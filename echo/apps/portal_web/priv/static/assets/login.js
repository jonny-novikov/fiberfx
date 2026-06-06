const io=new IntersectionObserver(es=>es.forEach(e=>{if(e.isIntersecting)e.target.classList.add('in-view')}),{threshold:.06});
document.querySelectorAll('section .wrap, section .wrap-narrow').forEach(el=>{el.classList.add('reveal-on-scroll');io.observe(el)});

/* canonical branded-Snowflake build stamp: decode on load, reveal the panel as a popover on click */
(function () {
  "use strict";
  var B62 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
  var EPOCH_MS = 1704067200000;
  function b62decode(s) { var n = 0n; for (var i = 0; i < s.length; i++) { var d = B62.indexOf(s.charAt(i)); if (d < 0) return null; n = n * 62n + BigInt(d); } return n; }
  function pad2(x) { return (x < 10 ? '0' : '') + x; }
  function decodeBranded(id) {
    if (!id || id.length < 4) return null;
    var ns = id.slice(0, 3), snow = b62decode(id.slice(3));
    if (snow === null) return null;
    var ts = snow >> 22n, node = (snow >> 12n) & 0x3FFn, seq = snow & 0xFFFn;
    var d = new Date(Number(ts) + EPOCH_MS);
    var tstr = d.getUTCFullYear() + '-' + pad2(d.getUTCMonth() + 1) + '-' + pad2(d.getUTCDate()) + ' ' + pad2(d.getUTCHours()) + ':' + pad2(d.getUTCMinutes()) + ':' + pad2(d.getUTCSeconds()) + ' UTC';
    return { ns: ns, snow: snow.toString(), node: node.toString(), seq: seq.toString(), ts: tstr };
  }
  var stamp = document.getElementById('stamp'), idEl = document.getElementById('stampId');
  if (stamp && idEl) {
    var info = decodeBranded(idEl.textContent.trim());
    if (info) { var put = function (id, t) { var el = document.getElementById(id); if (el) el.textContent = t; };
      put('st-ns', info.ns); put('st-snow', info.snow); put('st-node', info.node); put('st-seq', info.seq); put('st-ts', info.ts); }
    var toggle = function () { var open = stamp.classList.toggle('open'); stamp.setAttribute('aria-expanded', open ? 'true' : 'false'); };
    stamp.addEventListener('click', toggle);
    stamp.addEventListener('keydown', function (ev) { if (ev.key === 'Enter' || ev.key === ' ' || ev.key === 'Spacebar') { ev.preventDefault(); toggle(); } });
  }
})();

// F6.8.1 (CSRF resolution (a)): read the page's csrf-token meta ONCE and expose it
// for the two POST fetches below. The page keeps protect_from_forgery ON; this is the
// single minimal addition to the otherwise-verbatim login.html script bodies.
var __csrfMeta = document.querySelector('meta[name="csrf-token"]');
var __csrfToken = __csrfMeta ? __csrfMeta.getAttribute("content") : "";

(function(){
  var signin=document.getElementById('signin-form'); if(!signin) return;
  var reset=document.getElementById('reset-form');
  var divider=document.getElementById('auth-divider');
  var card=document.getElementById('auth-card');
  var ident=document.getElementById('auth-ident');
  var pass=document.getElementById('auth-pass');
  var remail=document.getElementById('auth-remail');
  var identErr=document.getElementById('ident-err');
  var passErr=document.getElementById('pass-err');
  var remailErr=document.getElementById('remail-err');
  var caps=document.getElementById('caps-note');
  var peek=document.getElementById('auth-peek');
  var signinBtn=document.getElementById('signin-send');
  var resetBtn=document.getElementById('reset-send');
  var toReset=document.getElementById('to-reset');
  var toSignin=document.getElementById('to-signin');
  var ro=document.getElementById('auth-readout');
  var svg=document.getElementById('flow-svg');
  var st0=svg.querySelector('.st0');
  var stb=svg.querySelector('.stb');
  var st1=svg.querySelector('.st1');
  var lb0=svg.querySelector('.lb0');
  var lbb=svg.querySelector('.lbb');
  var halo=svg.querySelector('.flow-halo');
  var IDLE_IN='idle \u00B7 enter a name or email, and the password';
  var IDLE_RS='reset \u00B7 enter the account email';
  var AB='0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  var EPOCH=1704067200000;
  var NODE=Math.floor(Math.random()*1024);
  var seq=0, lastMs=0;
  function enc62(n){ var s=''; if(n===0n){ s='0'; } while(n>0n){ s=AB.charAt(Number(n%62n))+s; n=n/62n; } while(s.length<11){ s='0'+s; } return s; }
  function mint(ns){
    var ms=Date.now();
    if(ms===lastMs){ seq=(seq+1)&4095; } else { seq=0; lastMs=ms; }
    var n=(BigInt(ms-EPOCH)<<22n)|(BigInt(NODE)<<12n)|BigInt(seq);
    return ns+enc62(n);
  }
  function mask(e){ var at=e.indexOf('@'); return e.charAt(0)+'\u2022\u2022'+e.slice(at); }
  function validEmail(e){ return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(e); }
  function validIdent(v){ if(v.indexOf('@')>=0){ return validEmail(v); } return /^[A-Za-z0-9][A-Za-z0-9._-]{2,31}$/.test(v); }
  function paint(state){
    card.classList.remove('bad');
    st0.classList.remove('ok','warn','bad');
    st1.classList.remove('ok');
    stb.classList.remove('ok','warn');
    lb0.classList.remove('on');
    lbb.classList.remove('on');
    halo.classList.remove('auth-pulse');
    if(state==='bad'){ card.classList.add('bad'); st0.classList.add('bad'); }
    if(state==='busy'){ halo.classList.add('auth-pulse'); lb0.classList.add('on'); }
    if(state==='ok'){ st0.classList.add('ok'); st1.classList.add('ok'); lb0.classList.add('on'); }
    if(state==='warn'){ st0.classList.add('warn'); lb0.classList.add('on'); }
    if(state==='rs-busy'){ halo.classList.add('auth-pulse'); lbb.classList.add('on'); }
    if(state==='rs-ok'){ stb.classList.add('ok'); lbb.classList.add('on'); }
    if(state==='rs-warn'){ stb.classList.add('warn'); lbb.classList.add('on'); }
  }
  function clearErrs(){ identErr.hidden=true; passErr.hidden=true; remailErr.hidden=true; }
  function showPanel(which){
    clearErrs(); paint('idle');
    if(which==='reset'){
      signin.hidden=true; divider.hidden=true; reset.hidden=false;
      var v=ident.value.trim().toLowerCase();
      if(v.indexOf('@')>=0 && validEmail(v) && remail.value===''){ remail.value=v; }
      ro.textContent=IDLE_RS; remail.focus();
    } else {
      reset.hidden=true; divider.hidden=true; signin.hidden=false;
      ro.textContent=IDLE_IN; ident.focus();
    }
  }
  // progressive enhancement: collapse the stacked no-script layout into panels
  reset.hidden=true; divider.hidden=true; peek.hidden=false;
  toReset.addEventListener('click', function(){ showPanel('reset'); });
  toSignin.addEventListener('click', function(){ showPanel('signin'); });
  peek.addEventListener('click', function(){
    var show=(pass.type==='password');
    pass.type=show?'text':'password';
    peek.textContent=show?'hide':'show';
    peek.setAttribute('aria-pressed', show?'true':'false');
    peek.setAttribute('aria-label', show?'Hide password':'Show password');
    pass.focus();
  });
  function capsCheck(ev){ if(ev.getModifierState){ caps.hidden=!ev.getModifierState('CapsLock'); } }
  pass.addEventListener('keydown', capsCheck);
  pass.addEventListener('keyup', capsCheck);
  pass.addEventListener('blur', function(){ caps.hidden=true; });
  ident.addEventListener('input', function(){ if(card.classList.contains('bad')){ clearErrs(); paint('idle'); ro.textContent=IDLE_IN; } });
  pass.addEventListener('input', function(){ if(card.classList.contains('bad')){ clearErrs(); paint('idle'); ro.textContent=IDLE_IN; } });
  remail.addEventListener('input', function(){ if(card.classList.contains('bad')){ clearErrs(); paint('idle'); ro.textContent=IDLE_RS; } });
  signin.addEventListener('submit', function(ev){
    ev.preventDefault();
    clearErrs();
    var who=ident.value.trim().toLowerCase();
    var pw=pass.value;
    var ok=true;
    if(!validIdent(who)){ identErr.hidden=false; ok=false; }
    if(pw.length===0){ passErr.hidden=false; ok=false; }
    if(!ok){
      paint('bad');
      ro.textContent='error \u00B7 fix the marked field \u00B7 nothing sent';
      if(identErr.hidden===false){ ident.focus(); } else { pass.focus(); }
      return;
    }
    var id=mint('REQ');
    signinBtn.disabled=true;
    paint('busy');
    ro.textContent='checking \u00B7 '+id+' \u00B7 POST /auth/session \u2026';
    fetch(signin.action,{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded','x-csrf-token':__csrfToken},body:'identifier='+encodeURIComponent(who)+'&password='+encodeURIComponent(pw)})
      .then(function(r){
        if(r.ok){
          paint('ok');
          ro.textContent='signed in \u00B7 '+id+' \u00B7 opening the course';
          var dest=signin.getAttribute('data-redirect');
          setTimeout(function(){ try{ window.location.assign(dest); }catch(e){} }, 900);
        } else if(r.status===401 || r.status===403){
          paint('bad');
          ro.textContent='sign-in failed \u00B7 the name or the password did not match \u00B7 '+id;
        } else {
          paint('warn');
          ro.textContent='POST /auth/session \u2192 '+r.status+' \u00B7 endpoint not wired yet \u00B7 '+id;
        }
      })
      .catch(function(){
        paint('warn');
        if(window.location.protocol==='file:'){
          ro.textContent='preview \u00B7 '+id+' \u00B7 POST /auth/session is unreachable from a static file';
        } else {
          ro.textContent='network error \u00B7 '+id+' \u00B7 POST /auth/session did not complete';
        }
      })
      .then(function(){ signinBtn.disabled=false; });
  });
  reset.addEventListener('submit', function(ev){
    ev.preventDefault();
    clearErrs();
    var em=remail.value.trim().toLowerCase();
    if(!validEmail(em)){
      remailErr.hidden=false;
      paint('bad');
      ro.textContent='error \u00B7 the address failed validation \u00B7 nothing sent';
      remail.focus();
      return;
    }
    var id=mint('RST');
    resetBtn.disabled=true;
    paint('rs-busy');
    ro.textContent='requesting \u00B7 '+id+' \u00B7 POST /auth/reset \u2026';
    fetch(reset.action,{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded','x-csrf-token':__csrfToken},body:'email='+encodeURIComponent(em)})
      .then(function(r){
        if(r.ok){
          paint('rs-ok');
          ro.textContent='sent \u00B7 if an account matches '+mask(em)+', a reset link is on its way \u00B7 '+id;
          resetBtn.textContent='Send again';
        } else {
          paint('rs-warn');
          ro.textContent='POST /auth/reset \u2192 '+r.status+' \u00B7 endpoint not wired yet \u00B7 '+id;
        }
      })
      .catch(function(){
        paint('rs-warn');
        if(window.location.protocol==='file:'){
          ro.textContent='preview \u00B7 '+id+' \u00B7 POST /auth/reset is unreachable from a static file';
        } else {
          ro.textContent='network error \u00B7 '+id+' \u00B7 POST /auth/reset did not complete';
        }
      })
      .then(function(){ resetBtn.disabled=false; });
  });
})();
