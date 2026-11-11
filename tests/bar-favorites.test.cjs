const {test} = require('node:test');
const assert = require('node:assert/strict');
const {readFileSync} = require('node:fs');
const vm = require('node:vm');
const m=vm.createContext({StackModel:{normalizeFolders:x=>x||[]}});
vm.runInContext(readFileSync('DockModel.js','utf8').replace(/^\.(pragma|import).*$/gm,''),m);
test('bar favorites is opt in and survives state round trips without losing pins',()=>{
 assert.equal(m.defaultSettings().barFavorites,false);
 const s=m.parseState(JSON.stringify({pinned:['Oracle','browser'],settings:{barFavorites:true}}));
 const saved=m.parseState(m.serializeState(s));
 assert.equal(saved.settings.barFavorites,true);
 assert.deepEqual(Array.from(saved.pinned),['Oracle','browser']);
});
test('bar scrolling keeps a bounded window of four after list changes',()=>{
 assert.equal(m.barOffset(0,1,4),0);
 assert.equal(m.barOffset(0,-1,8),0);
 assert.equal(m.barOffset(0,1,8),1);
 assert.equal(m.barOffset(4,1,8),4);
 assert.equal(m.barOffset(4,0,2),0);
 assert.equal(m.barOffset(0,1,0),0);
});
test('tooltip text cannot introduce rich text resources',()=>{
 assert.equal(m.barTooltip('<img src="https://example.invalid/"> & Apps').includes('<'),false);
 assert.equal(m.barTooltip('Oracle'),'Oracle');
});
test('bar selection is independent, normalized and persisted without changing main pins',()=>{
 const state=m.parseState(JSON.stringify({pinned:['browser','terminal'],barPinned:['Oracle','Oracle','','artemis']}));
 assert.deepEqual(Array.from(state.barPinned),['Oracle','artemis']);
 state.barPinned=['crm'];
 const saved=m.parseState(m.serializeState(state));
 assert.deepEqual(Array.from(saved.pinned),['browser','terminal']);
 assert.deepEqual(Array.from(saved.barPinned),['crm']);
});
test('legacy main pins never automatically become bar favorites',()=>{
 assert.deepEqual(Array.from(m.parseState(JSON.stringify({pinned:['browser']})).barPinned),[]);
 assert.deepEqual(Array.from(m.defaultState().barPinned),[]);
});

test('Toolbar seeds defaults once and preserves an intentionally empty selection',()=>{
 const expected=['omadocks-default-terminal','omadocks-herdr','omadocks-default-browser'];
 assert.deepEqual(Array.from(m.defaultState().toolbarPinned || []),expected);
 assert.deepEqual(Array.from(m.parseState('{"pinned":["Oracle"]}').toolbarPinned || []),expected);
 const s=m.parseState('{"pinned":["Oracle"],"barPinned":["crm"],"toolbarPinned":[]}');
 const saved=m.parseState(m.serializeState(s));
 assert.deepEqual(Array.from(saved.toolbarPinned),[]);
 assert.deepEqual(Array.from(saved.pinned),['Oracle']);
 assert.deepEqual(Array.from(saved.barPinned),['crm']);
});
test('Toolbar normalizes and persists its selection independently',()=>{
 const s=m.parseState('{"toolbarPinned":["herdr","herdr",""," browser "],"barPinned":["crm"],"pinned":["Oracle"]}');
 assert.deepEqual(Array.from(s.toolbarPinned),['herdr','browser']);
 s.toolbarPinned=m.withoutPinned(s.toolbarPinned,'herdr');
 s.toolbarPinned=m.withoutPinned(s.toolbarPinned,'herdr'); // repeated removals cannot add it back
 const saved=m.parseState(m.serializeState(s));
 assert.deepEqual(Array.from(saved.toolbarPinned),['browser']);
 assert.deepEqual(Array.from(saved.barPinned),['crm']);
 assert.deepEqual(Array.from(saved.pinned),['Oracle']);
});
test('current default apps map to Toolbar roles for contextual membership',()=>{
 const defaults={terminal:'ghostty',browser:'chrome',herdr:'herdr'};
 assert.equal(m.toolbarKey('ghostty',defaults),'omadocks-default-terminal');
 assert.equal(m.toolbarKey('chrome',defaults),'omadocks-default-browser');
 assert.equal(m.toolbarKey('herdr',defaults),'omadocks-herdr');
 assert.equal(m.toolbarKey('editor',defaults),'editor');
 assert.equal(m.toolbarKey('omadocks-default-terminal',defaults),'omadocks-default-terminal');
 assert.equal(m.toolbarKey('editor',{}),'editor');
});
test('Toolbar launch commands follow defaults and run Herdr inside a terminal',()=>{
 assert.deepEqual(Array.from(m.toolbarCommand('omadocks-default-terminal')),['omarchy-launch-terminal']);
 assert.deepEqual(Array.from(m.toolbarCommand('omadocks-default-browser')),['omarchy-launch-browser']);
 assert.deepEqual(Array.from(m.toolbarCommand('omadocks-herdr')),['omarchy-launch-terminal','--app-id=herdr','--title=Herdr','--','herdr']);
 assert.deepEqual(Array.from(m.toolbarCommand('editor')),['uwsm-app','--','gtk-launch','editor.desktop']);
});
test('Toolbar reordering preserves every shortcut and other groups across save/load',()=>{
 const state=m.parseState('{"pinned":["main"],"barPinned":["favorite"],"toolbarPinned":["terminal","herdr","browser"]}');
 state.toolbarPinned=m.reorderPinned(state.toolbarPinned,'browser','terminal');
 assert.deepEqual(Array.from(state.toolbarPinned),['browser','terminal','herdr']);
 state.toolbarPinned=m.reorderPinned(state.toolbarPinned,'browser','herdr');
 assert.deepEqual(Array.from(state.toolbarPinned),['terminal','herdr','browser']);
 for(const pair of [['missing','terminal'],['terminal','missing'],['terminal','terminal']]) {
  assert.deepEqual(Array.from(m.reorderPinned(state.toolbarPinned,...pair)),['terminal','herdr','browser']);
 }
 const saved=m.parseState(m.serializeState(state));
 assert.deepEqual(Array.from(saved.toolbarPinned),['terminal','herdr','browser']);
 assert.deepEqual(Array.from(saved.pinned),['main']);
 assert.deepEqual(Array.from(saved.barPinned),['favorite']);
});
