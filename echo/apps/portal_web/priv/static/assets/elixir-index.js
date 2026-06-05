(function () {
  "use strict";

  /* The deep-link base (F6.5.5-D9) — injected ONCE by the server-rendered <head>
     (a <meta name="deep-link-base">, or window.__deepLinkBase). This static asset
     cannot read Elixir config, so it reads the injected value and prefixes its arc
     "Open Fn" nav route with it. Empty fallback keeps the file servable bare. */
  var META = document.querySelector('meta[name="deep-link-base"]');
  var BASE = (META && META.content) || window.__deepLinkBase || "";

  /* ---------- Interactive 1: the arc ---------- */
  var CH = [{"id": "F1", "name": "Algebra", "route": "/elixir/algebra", "live": true, "modules": 9, "one": "The functional mindset, straight from the math you already know.", "reuses": "Starts from the algebra you already know."}, {"id": "F2", "name": "Functional Programming", "route": "/elixir/functional", "live": true, "modules": 9, "one": "Pure functions, immutability, and higher-order functions on their own terms.", "reuses": "Builds on F1 · Algebra."}, {"id": "F3", "name": "The Elixir Language", "route": "/elixir/language", "live": true, "modules": 9, "one": "Syntax, pipelines, pattern matching, and structs on the BEAM.", "reuses": "Builds on F2 · Functional Programming."}, {"id": "F4", "name": "Algorithms & Data Structures", "route": "/elixir/algorithms", "live": true, "modules": 9, "one": "Classical and advanced problems, from lists to branded CHAMP tries.", "reuses": "Builds on F3 · The Elixir Language."}, {"id": "F5", "name": "Pragmatic Programming", "route": "/elixir/pragmatic", "live": true, "modules": 9, "one": "Real-world engineering: structure, testing, telemetry, releases.", "reuses": "Builds on F4 · Algorithms & Data Structures."}, {"id": "F6", "name": "Phoenix Framework", "route": "/elixir/phoenix", "live": true, "modules": 9, "one": "Web applications on Elixir, and the road into real-time LiveView.", "reuses": "Builds on F5 · Pragmatic Programming."}];
  var byId = {};
  CH.forEach(function (c) { byId[c.id] = c; });

  function selectChapter(id) {
    var c = byId[id];
    if (!c) return;
    var nodes = document.querySelectorAll('.arc-node');
    nodes.forEach(function (n) {
      var on = n.getAttribute('data-ch') === id;
      n.classList.toggle('active', on);
      n.setAttribute('aria-pressed', on ? 'true' : 'false');
    });
    var set = function (sel, txt) { var el = document.getElementById(sel); if (el) el.textContent = txt; };
    set('arcNm', c.name);
    set('arcOne', c.one);
    set('arcId', c.id);
    set('arcMods', String(c.modules));
    set('arcReuse', c.reuses);

    var open = document.getElementById('arcOpen');
    if (open) {
      open.textContent = '';
      if (c.live) {
        var a = document.createElement('a');
        a.setAttribute('href', BASE + c.route);
        a.textContent = 'Open ' + c.id + ' \u00b7 ' + c.name + ' \u2192';
        open.appendChild(a);
      } else {
        var s = document.createElement('span');
        s.className = 'muted';
        s.textContent = c.id + ' \u00b7 ' + c.name + ' \u2014 in progress';
        open.appendChild(s);
      }
    }
  }

  document.querySelectorAll('.arc-node').forEach(function (n) {
    var go = function () { selectChapter(n.getAttribute('data-ch')); };
    n.addEventListener('click', go);
    n.addEventListener('keydown', function (e) {
      if (e.key === 'Enter' || e.key === ' ' || e.key === 'Spacebar') { e.preventDefault(); go(); }
    });
  });

  /* ---------- Interactive 2: the pipe ---------- */
  var STAGES = [
    { key: 'double', label: 'double',    cls: 'blue', fn: function (v) { return v * 2; } },
    { key: 'inc',    label: 'increment', cls: 'sage', fn: function (v) { return v + 1; } },
    { key: 'square', label: 'square',    cls: 'gold', fn: function (v) { return v * v; } }
  ];

  function activeStages() {
    var on = {};
    document.querySelectorAll('#pipeStages button').forEach(function (b) {
      on[b.getAttribute('data-stage')] = b.classList.contains('active');
    });
    return STAGES.filter(function (s) { return on[s.key]; });
  }

  function renderPipe() {
    var slider = document.getElementById('pipeX');
    if (!slider) return;
    var x = parseInt(slider.value, 10);
    var xv = document.getElementById('pipeXval');
    if (xv) xv.textContent = String(x);

    var stages = activeStages();
    var v = x;
    var chain = [x];
    var lines = ['<span class="res">' + x + '</span>'];
    var pad = 'increment'.length; // widest label, for aligned comments

    stages.forEach(function (s) {
      v = s.fn(v);
      chain.push(v);
      var name = s.label + '()';
      var gap = '    '.slice(0, 1) + Array(Math.max(1, pad - s.label.length + 1)).join(' ');
      lines.push('<span class="op">|&gt;</span> <span class="fn ' + s.cls + '">' + s.label + '</span>()' + gap + '<span class="cmt"># =&gt; ' + v + '</span>');
    });

    var code = document.getElementById('pipeCode');
    if (code) code.innerHTML = lines.join('\n');

    var out = document.getElementById('pipeChain');
    if (out) {
      if (chain.length === 1) {
        out.innerHTML = x + ' <span class="dim">&nbsp;=&nbsp;' + x + '&nbsp;(identity)</span>';
      } else {
        out.innerHTML = chain.join(' \u25b7 ') + ' <span class="dim">&nbsp;=&nbsp;' + v + '</span>';
      }
    }
  }

  var sliderEl = document.getElementById('pipeX');
  if (sliderEl) sliderEl.addEventListener('input', renderPipe);
  document.querySelectorAll('#pipeStages button').forEach(function (b) {
    b.addEventListener('click', function () {
      var on = !b.classList.contains('active');
      b.classList.toggle('active', on);
      b.setAttribute('aria-pressed', on ? 'true' : 'false');
      renderPipe();
    });
  });
  renderPipe();

  /* ---------- Branded Snowflake decoder (mirrors build_page.py) ---------- */
  var B62 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
  var EPOCH_MS = 1704067200000;

  function b62decode(s) {
    var n = 0n;
    for (var i = 0; i < s.length; i++) {
      var d = B62.indexOf(s.charAt(i));
      if (d < 0) return null;
      n = n * 62n + BigInt(d);
    }
    return n;
  }

  function pad2(x) { return (x < 10 ? '0' : '') + x; }

  function decodeBranded(id) {
    if (!id || id.length < 4) return null;
    var ns = id.slice(0, 3);
    var snow = b62decode(id.slice(3));
    if (snow === null) return null;
    var ts = snow >> 22n;
    var node = (snow >> 12n) & 0x3FFn;
    var seq = snow & 0xFFFn;
    var d = new Date(Number(ts) + EPOCH_MS);
    var tstr = d.getUTCFullYear() + '-' + pad2(d.getUTCMonth() + 1) + '-' + pad2(d.getUTCDate()) +
      ' ' + pad2(d.getUTCHours()) + ':' + pad2(d.getUTCMinutes()) + ':' + pad2(d.getUTCSeconds()) + ' UTC';
    return { ns: ns, snow: snow.toString(), node: node.toString(), seq: seq.toString(), ts: tstr };
  }

  var stamp = document.getElementById('stamp');
  var idEl = document.getElementById('stampId');
  if (stamp && idEl) {
    var info = decodeBranded(idEl.textContent.trim());
    if (info) {
      var put = function (sel, txt) { var el = document.getElementById(sel); if (el) el.textContent = txt; };
      put('st-ns', info.ns);
      put('st-snow', info.snow);
      put('st-node', info.node);
      put('st-seq', info.seq);
      put('st-ts', info.ts);
    }
    var toggle = function () {
      var open = stamp.classList.toggle('open');
      stamp.setAttribute('aria-expanded', open ? 'true' : 'false');
    };
    stamp.addEventListener('click', toggle);
    stamp.addEventListener('keydown', function (e) {
      if (e.key === 'Enter' || e.key === ' ' || e.key === 'Spacebar') { e.preventDefault(); toggle(); }
    });
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
