 'use strict';
function navigationPage(path,hash){return path==='/keymap'?'keymap':hash==='#scores'?'scores':hash==='#settings'?'settings':'control';}
if(typeof module!=='undefined')module.exports={navigationPage};
if(typeof document!=='undefined'){
 const keymap=document.body.classList.contains('keymap-page');
 function renderNavigation(){
  const page=keymap?'keymap':navigationPage(location.pathname,location.hash);
  document.body.dataset.page=page;
  document.querySelectorAll('.bottom-nav a').forEach(link=>{if(link.dataset.page===page)link.setAttribute('aria-current','page');else link.removeAttribute('aria-current');});
  if(keymap)return;
  for(const name of ['control','scores','settings'])document.getElementById(name+'View').hidden=name!==page;
  document.getElementById('pageTitle').textContent={control:'电子乐器控制',scores:'曲谱',settings:'设置'}[page];
 }
 document.querySelectorAll('.bottom-nav a').forEach(link=>link.addEventListener('click',event=>{
  const target=new URL(link.href,location.href);
  if(!keymap&&target.pathname==='/'&&target.origin===location.origin){event.preventDefault();if(location.hash!==target.hash)location.hash=target.hash;else renderNavigation();window.scrollTo(0,0);}
 }));
 window.addEventListener('hashchange',renderNavigation);renderNavigation();
}
