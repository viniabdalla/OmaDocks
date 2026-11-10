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
