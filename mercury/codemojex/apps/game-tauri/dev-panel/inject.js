// inject.js — injected by Tauri as an initialization script (document-start),
// so it runs before the Phoenix-served React app's own scripts.
//
// Two jobs:
//   1. Wrap window.WebSocket immediately, so every Phoenix Channel frame is
//      tapped in both directions — no native bridge needed, because Tauri's
//      system webview speaks WebSocket natively and phoenix.js uses it.
//   2. Render a developer panel over the page (built once the DOM exists).
//
// Toggle with Ctrl+`.  Works against the remote app without touching its build.

(function () {
  if (window.__codemojiDevPanel) return;
  window.__codemojiDevPanel = true;

  // ---------------------------------------------------------------- wire tap
  var taps = new Set();
  var captured = [];
  function emitWire(dir, frame, ts) {
    var t = ts || Date.now();
    captured.push({ dir: dir, frame: frame, t: t });
    if (captured.length > 5000) captured.shift();
    taps.forEach(function (fn) { try { fn(dir, frame, t); } catch (_) {} });
  }

  var Native = window.WebSocket;
  function Tapped(url, protocols) {
    var ws = protocols === undefined ? new Native(url) : new Native(url, protocols);
    emitWire("meta", "ws open " + url);
    var send = ws.send.bind(ws);
    ws.send = function (data) {
      emitWire("out", typeof data === "string" ? data : "[binary]");
      return send(data);
    };
    ws.addEventListener("message", function (ev) {
      emitWire("in", typeof ev.data === "string" ? ev.data : "[binary]");
    });
    ws.addEventListener("close", function (ev) { emitWire("meta", "ws close " + (ev.code || "")); });
    ws.addEventListener("error", function () { emitWire("meta", "ws error"); });
    return ws;
  }
  Tapped.prototype = Native.prototype;
  ["CONNECTING", "OPEN", "CLOSING", "CLOSED"].forEach(function (k) { Tapped[k] = Native[k]; });
  window.WebSocket = Tapped;

  // ---------------------------------------------------------------- decoding
  function decode(frame) {
    var p;
    try { p = JSON.parse(frame); } catch (e) { return { raw: frame }; }
    if (Array.isArray(p)) return { join_ref: p[0], ref: p[1], topic: p[2], event: p[3], payload: p[4] };
    if (p && typeof p === "object") return { ref: p.ref, topic: p.topic, event: p.event, payload: p.payload };
    return { raw: frame };
  }
  function klass(d) {
    if (!d.event) return "";
    if (d.event === "heartbeat") return "hb";
    if (d.event === "phx_reply") return "reply";
    if (d.event === "phx_error" || d.event === "phx_close") return "error";
    return "";
  }
  function esc(s) {
    return String(s).replace(/[&<>"]/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c];
    });
  }
  function stamp(ts) {
    var d = ts ? new Date(ts) : new Date();
    return d.toLocaleTimeString("en-GB", { hour12: false }) + "." +
      String(d.getMilliseconds()).padStart(3, "0");
  }

  // ---------------------------------------------------------------- export
  function download(data) {
    var b = new Blob([data], { type: "application/json" });
    var a = document.createElement("a");
    a.href = URL.createObjectURL(b);
    a.download = "codemoji-events-" + Date.now() + ".json";
    a.click();
    URL.revokeObjectURL(a.href);
  }
  function exportEvents(note) {
    var data = JSON.stringify(captured, null, 2);
    var T = window.__TAURI__;
    if (T && T.core && typeof T.core.invoke === "function") {
      T.core.invoke("export_events", { events: data })
        .then(function (p) { note("exported → " + p); })
        .catch(function (e) { note("export failed: " + e); download(data); });
    } else {
      download(data);
    }
  }

  // ---------------------------------------------------------------- panel UI
  var CSS =
    "#cdp{position:fixed;top:0;right:0;height:100vh;width:440px;transform:translateX(100%);" +
    "transition:transform .18s ease;background:#0c0f14;color:#cdd6e4;font:12px/1.5 ui-monospace,Menlo,monospace;" +
    "display:flex;flex-direction:column;z-index:2147483647;border-left:1px solid #1d232e;box-shadow:-8px 0 24px rgba(0,0,0,.4)}" +
    "#cdp.open{transform:translateX(0)}" +
    "#cdp header{display:flex;align-items:center;gap:8px;padding:8px 10px;border-bottom:1px solid #1d232e;background:#11151c}" +
    "#cdp .dot{width:8px;height:8px;border-radius:50%;background:#5c6675}#cdp .dot.up{background:#3fb950}#cdp .dot.down{background:#f85149}" +
    "#cdp .title{font-weight:600;color:#e6edf3}#cdp .count{color:#7d8590;margin-left:auto}" +
    "#cdp .bar{display:flex;gap:6px;padding:6px 10px;border-bottom:1px solid #1d232e}" +
    "#cdp .bar input{flex:1;background:#0c0f14;border:1px solid #1d232e;color:#cdd6e4;padding:3px 6px;border-radius:5px;outline:none}" +
    "#cdp .bar button{background:#1d232e;border:0;color:#cdd6e4;padding:3px 8px;border-radius:5px;cursor:pointer}" +
    "#cdp .bar button.on{background:#2d6cdf;color:#fff}" +
    "#cdp .log{flex:1;overflow:auto;padding:4px 0}" +
    "#cdp .row{padding:3px 10px;border-bottom:1px solid #11151c;cursor:pointer;display:grid;grid-template-columns:62px 14px 1fr auto;gap:8px;align-items:baseline}" +
    "#cdp .row:hover{background:#11151c}#cdp .t{color:#5c6675}" +
    "#cdp .arrow.out{color:#d29922}#cdp .arrow.in{color:#58a6ff}" +
    "#cdp .topic{color:#e6edf3;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}#cdp .evt{color:#a5d6ff}#cdp .ref{color:#5c6675;font-size:11px}" +
    "#cdp .row.reply .evt{color:#3fb950}#cdp .row.error .evt{color:#f85149}#cdp .row.hb{opacity:.45}" +
    "#cdp .row.meta{grid-template-columns:62px 1fr}#cdp .row.meta .evt{color:#bc8cff}" +
    "#cdp pre{grid-column:1/-1;margin:4px 0 2px;padding:6px 8px;background:#11151c;border-radius:5px;color:#9fb0c3;white-space:pre-wrap;word-break:break-word;display:none}" +
    "#cdp .row.expanded pre{display:block}" +
    "#cdp-fab{position:fixed;bottom:14px;right:14px;z-index:2147483646;background:#1d232e;color:#cdd6e4;border:0;border-radius:8px;padding:7px 10px;cursor:pointer;font:12px ui-monospace,monospace;box-shadow:0 2px 10px rgba(0,0,0,.3)}";

  function build() {
    var style = document.createElement("style");
    style.textContent = CSS;
    document.head.appendChild(style);

    var el = document.createElement("div");
    el.id = "cdp";
    el.innerHTML =
      '<header><span class="dot" id="cdp-dot"></span><span class="title">Channel Events</span>' +
      '<span class="count" id="cdp-count">0 in / 0 out</span></header>' +
      '<div class="bar"><input id="cdp-filter" placeholder="filter topic / event…"/>' +
      '<button id="cdp-pause">pause</button><button id="cdp-export">export</button>' +
      '<button id="cdp-clear">clear</button></div><div class="log" id="cdp-log"></div>';
    document.body.appendChild(el);

    var fab = document.createElement("button");
    fab.id = "cdp-fab";
    fab.textContent = "events \u2303`";
    document.body.appendChild(fab);

    var log = el.querySelector("#cdp-log");
    var dot = el.querySelector("#cdp-dot");
    var counter = el.querySelector("#cdp-count");
    var state = { paused: false, filter: "", inN: 0, outN: 0 };

    function toggle() { el.classList.toggle("open"); }
    fab.onclick = toggle;
    addEventListener("keydown", function (e) {
      if (e.ctrlKey && e.key === "`") { e.preventDefault(); toggle(); }
    });

    function note(text) {
      if (state.paused) return;
      var row = document.createElement("div");
      row.className = "row meta";
      row.innerHTML = '<span class="t">' + stamp() + '</span><span class="evt">' + esc(text) + "</span>";
      push(row);
    }
    function push(row) {
      var atBottom = log.scrollHeight - log.scrollTop - log.clientHeight < 40;
      log.appendChild(row);
      while (log.childElementCount > 1500) log.removeChild(log.firstChild);
      if (atBottom) log.scrollTop = log.scrollHeight;
    }

    el.querySelector("#cdp-filter").oninput = function (e) {
      state.filter = e.target.value.toLowerCase();
      var rows = log.children;
      for (var i = 0; i < rows.length; i++) {
        var k = rows[i].dataset.key || "";
        rows[i].style.display = !state.filter || k.indexOf(state.filter) !== -1 ? "" : "none";
      }
    };
    var pauseBtn = el.querySelector("#cdp-pause");
    pauseBtn.onclick = function () {
      state.paused = !state.paused;
      pauseBtn.classList.toggle("on", state.paused);
      pauseBtn.textContent = state.paused ? "resume" : "pause";
    };
    el.querySelector("#cdp-clear").onclick = function () { log.innerHTML = ""; };
    el.querySelector("#cdp-export").onclick = function () { exportEvents(note); };

    taps.add(function (dir, frame, ts) {
      if (dir === "meta") {
        if (/open/.test(frame)) dot.className = "dot up";
        else if (/close|error/.test(frame)) dot.className = "dot down";
        note(frame);
        return;
      }
      if (dir === "in") state.inN++; else state.outN++;
      counter.textContent = state.inN + " in / " + state.outN + " out";
      if (state.paused) return;

      var d = decode(frame);
      var topic = d.topic || "—", event = d.event || (d.raw ? "(raw)" : "—");
      var ref = d.ref != null ? "#" + d.ref : "";
      var body = d.payload !== undefined ? d.payload : (d.raw !== undefined ? d.raw : d);
      var row = document.createElement("div");
      row.className = "row " + klass(d);
      row.dataset.key = (topic + " " + event).toLowerCase();
      row.innerHTML =
        '<span class="t">' + stamp(ts) + "</span>" +
        '<span class="arrow ' + dir + '">' + (dir === "out" ? "↑" : "↓") + "</span>" +
        '<span class="topic">' + esc(topic) + ' <span class="evt">' + esc(event) + "</span></span>" +
        '<span class="ref">' + ref + "</span><pre>" + esc(JSON.stringify(body, null, 2)) + "</pre>";
      row.onclick = function () { row.classList.toggle("expanded"); };
      if (state.filter && row.dataset.key.indexOf(state.filter) === -1) row.style.display = "none";
      push(row);
    });

    // Replay any frames captured before the DOM was ready.
    captured.forEach(function (e) { /* counts already advance via live taps */ });
  }

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", build);
  else build();
})();
