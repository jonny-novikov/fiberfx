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
/* progressive enhancement: mark JS on, then reveal-on-scroll */
document.documentElement.classList.add('js');
document.addEventListener('DOMContentLoaded', function () {
  var reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var els = document.querySelectorAll('.reveal');
  if (reduce || !('IntersectionObserver' in window)) {
    els.forEach(function (e) { e.classList.add('in'); });
    return;
  }
  var io = new IntersectionObserver(function (entries) {
    entries.forEach(function (en) {
      if (en.isIntersecting) { en.target.classList.add('in'); io.unobserve(en.target); }
    });
  }, { threshold: 0.12 });
  els.forEach(function (e) { io.observe(e); });
});
