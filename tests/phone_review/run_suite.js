'use strict';
// Execute existing regression suites against this branch's actual phone files.
// Only module resolution is adapted; tests and production files are unchanged.
const fs=require('node:fs'),path=require('node:path'),Module=require('node:module');
const branch=path.resolve(__dirname,'../..'),root=path.resolve(branch,'../..');
const phone=path.join(branch,'firmware/remote_music_ble/shouji');
const suites={
 controller:'ref/lanya_20261019/sim/test_phone.js',
 async_api:'ref/lanya_20261019/sim/test_device_api.js',
 score:'ref/lanya_20261019/sim/test_score.js',
 keymap:'tests/physical_keymap_20261024/web_keymap.js',
 practice_dom:'tests/display_integration_20261021/phone_guidance.js'
};
const filename=path.join(root,suites[process.argv[2]]||'');
if(!suites[process.argv[2]])throw Error('Unknown suite');
let source=fs.readFileSync(filename,'utf8');
source=source.replace(/phone=path\.join\(root,'firmware\/remote_music(?:_ble)?\/shouji'\)/g,'phone='+JSON.stringify(phone));
const m=new Module(filename,module);m.filename=filename;m.paths=Module._nodeModulePaths(path.dirname(filename));
const originalRequire=m.require.bind(m);
m.require=request=>request.startsWith('../shouji/')?require(path.join(phone,request.slice('../shouji/'.length))):originalRequire(request);
m._compile(source,filename);
