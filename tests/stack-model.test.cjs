const {test} = require('node:test');
const assert = require('node:assert/strict');
const {readFileSync, existsSync} = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
function load(file, extra={}) {
  const context = vm.createContext(extra);
  if (existsSync(path.join(__dirname, '..', file)))
    vm.runInContext(readFileSync(path.join(__dirname, '..', file), 'utf8').replace(/^\.(pragma|import).*$/gm,''), context);
  return context;
}
const m = load('StackModel.js', {Qt:{CopyAction:1,MoveAction:2}});
const plain = x => JSON.parse(JSON.stringify(x));
test('incoming transfers default to Move and preserve copy-only offers', () => {
  assert.equal(m.dropCopies({supportedActions:3,proposedAction:2}),false);
  assert.equal(m.dropCopies({supportedActions:3,proposedAction:1}),false);
  assert.equal(m.dropCopies({supportedActions:1,proposedAction:1}),true);
  assert.equal(m.dropCopies({supportedActions:1,proposedAction:0}),true);
  assert.equal(m.dropCopies({supportedActions:2,proposedAction:2}),false);
});
test('folders reject relative paths and deduplicate normalized paths', () => {
  assert.deepEqual(plain(m.normalizeFolders([{path:'/tmp/files/'}, {path:'/tmp/files'}, {path:'relative'}, null])),
    [{path:'/tmp/files',name:'files',view:'fan',showHidden:false,sort:'name'}]);
});
test('folder names and display choices survive normalization', () => {
  assert.deepEqual(plain(m.normalizeFolders([{path:'/tmp/a b', name:'Work',view:'list',sort:'modified',showHidden:true}])),
    [{path:'/tmp/a b',name:'Work',view:'list',sort:'modified',showHidden:true}]);
  assert.equal(m.normalizeFolders([{path:'/tmp/a',view:'invalid'}])[0].view,'fan');
});
test('file URIs preserve literal punctuation and unicode', () => {
  assert.equal(m.fileUrl('/tmp/a #?é\n.txt'), 'file:///tmp/a%20%23%3F%C3%A9%0A.txt');
});
test('dropped URIs decode local paths and reject remote hosts or malformed data', () => {
  assert.deepEqual(plain(m.localPaths(['file:///tmp/a%20b','file://localhost/tmp/%23hello',
    'https://example.com/a','file://server/share/a','file:///tmp/%00a','file:///tmp/%ZZ'])),
    ['/tmp/a b','/tmp/#hello']);
});
test('fan uses available height and reserves its last item for overflow', () => {
  const f = m.fanLayout(80, 480);
  assert.ok(f.visibleCount >= 3 && f.visibleCount <= 8);
  assert.equal(f.hasOverflow,true);
  assert.equal(f.fileCount, f.visibleCount-1);
  assert.equal(m.fanLayout(2,480).fileCount,2);
  assert.equal(m.fanLayout(2,480).hasOverflow,false);
  assert.equal(m.fanLayout(0,480).visibleCount,0);
});
test('fan follows a curved arc with increasing perspective size', () => {
  const a=m.fanPose(0,6), b=m.fanPose(2,6), c=m.fanPose(5,6);
  assert.ok(a.x < b.x && b.x < c.x);
  assert.ok(a.y > b.y && b.y > c.y);
  assert.ok(a.scale < c.scale);
  assert.notEqual(b.x, (a.x+c.x)*2/5+a.x*3/5); // arc is not straight
});
test('panels remain inside the active screen at every dock edge', () => {
  for (const edge of ['top','bottom','left','right']) {
    for (const anchor of [{x:1,y:1,width:40,height:40},{x:760,y:560,width:40,height:40}]) {
      const r=m.stackRect(edge,anchor,{width:600,height:450},{width:800,height:600});
      assert.ok(r.x>=8 && r.y>=8);
      assert.ok(r.x+r.width<=792 && r.y+r.height<=592);
    }
  }
});
test('cascade flips left near the right edge and clamps vertically', () => {
  assert.deepEqual(plain(m.cascadeRect({x:600,y:400,width:180,height:160}, 145,
    {width:220,height:300},{width:800,height:600})),{x:384,y:292,width:220,height:300});
});
test('state round trip retains app settings and folder choices', () => {
  const d=load('DockModel.js',{StackModel:m});
  const saved=d.serializeState({pinned:['steam'],order:['steam'],settings:{position:'left'},
    folders:[{path:'/tmp/a',view:'grid',showHidden:true}]});
  const state=d.parseState(saved);
  assert.deepEqual(plain(state.pinned),['steam']);
  assert.equal(state.settings.position,'left');
  assert.equal(state.folders[0].view,'grid');
  assert.equal(state.folders[0].showHidden,true);
});
