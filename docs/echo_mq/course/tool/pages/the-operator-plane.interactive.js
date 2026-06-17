(function () {
  "use strict";

  /* ---------- hero: the separate gate (pure over a fixed pending set) ----------
     A queue with a fixed pending set (depth 4) and a meta hash with a paused
     field. The claim reads the field FIRST: paused -> :empty, depth untouched;
     clear -> serves the head, depth would fall by one. The verdict is a pure
     function of the paused flag; nothing mutates the underlying set. */
  var paused = false, claimed = false;
  var pauseBtn = document.getElementById('pauseBtn');
  var resumeBtn = document.getElementById('resumeBtn');
  var claimBtn = document.getElementById('claimBtn');
  var metaBox = document.getElementById('metaBox');
  var pendBox = document.getElementById('pendBox');
  var flagLabel = document.getElementById('flagLabel');
  var depthLabel = document.getElementById('depthLabel');
  var gateLine = document.getElementById('gateLine');
  var gateOut = document.getElementById('gateOut');

  function renderGate() {
    if (flagLabel) flagLabel.textContent = paused ? "paused = 1" : "paused = (unset)";
    if (metaBox) metaBox.classList.toggle('on', paused);
    if (gateLine) gateLine.setAttribute('opacity', paused ? '1' : '0');
    if (pauseBtn) { pauseBtn.classList.toggle('active', paused); pauseBtn.setAttribute('aria-pressed', paused ? 'true' : 'false'); }
    if (resumeBtn) { resumeBtn.classList.toggle('active', !paused); resumeBtn.setAttribute('aria-pressed', !paused ? 'true' : 'false'); }
    if (depthLabel) depthLabel.textContent = !claimed ? "depth 4" : (paused ? "depth 4 → 4" : "depth 4 → 3");
    if (!gateOut) return;
    if (!claimed) {
      gateOut.innerHTML = paused
        ? 'queue paused &middot; <span class="dim">the claim will read the paused field first &mdash; run a claim</span>'
        : 'queue running &middot; <span class="dim">the claim will serve the head of pending &mdash; run a claim</span>';
      return;
    }
    if (paused) {
      gateOut.innerHTML = 'Jobs.claim/3 &rarr; <span class="bad">:empty</span>' +
        '<br><span class="dim">the paused field gates the claim before any set is read</span>' +
        '<br>pending depth <b>4 &rarr; 4</b> &mdash; the backlog is untouched';
    } else {
      gateOut.innerHTML = 'Jobs.claim/3 &rarr; <span class="ok">{:ok, {JOB0Nb1VTbfnu4, payload, 1}}</span>' +
        '<br><span class="dim">no paused field: the claim serves the head of pending</span>' +
        '<br>pending depth <b>4 &rarr; 3</b> &mdash; one job moved to active';
    }
  }
  function setPaused(p) { paused = p; claimed = false; renderGate(); }
  if (pauseBtn) pauseBtn.addEventListener('click', function () { setPaused(true); });
  if (resumeBtn) resumeBtn.addEventListener('click', function () { setPaused(false); });
  if (claimBtn) claimBtn.addEventListener('click', function () { claimed = true; renderGate(); });
  renderGate(); // initial render — correct without interaction

  /* ---------- content: the operator console (pure over a fixed dataset) ----------
     A verb and a queue/job state map to the real fn, the precondition it checks,
     the keys it touches (highlighted), and the typed verdict. Pure lookup. */
  var VERBS = {
    pause:           { fn: 'EchoMQ.Admin.pause/2',          keys: ['meta'],                                        danger: false, pre: 'none (idempotent)' },
    resume:          { fn: 'EchoMQ.Admin.resume/2',         keys: ['meta'],                                        danger: false, pre: 'none (idempotent)' },
    drain:           { fn: 'EchoMQ.Admin.drain/3',          keys: ['pending', 'row'],                              danger: false, pre: 'none' },
    obliterate:      { fn: 'EchoMQ.Admin.obliterate/3',     keys: ['pending', 'active', 'schedule', 'dead', 'meta', 'row'], danger: true,  pre: 'paused & (unforced) no active' },
    update_data:     { fn: 'EchoMQ.Jobs.update_data/4',     keys: ['row'],                                         danger: false, pre: 'row exists' },
    update_progress: { fn: 'EchoMQ.Jobs.update_progress/4', keys: ['row', 'events'],                               danger: false, pre: 'row exists' },
    add_log:         { fn: 'EchoMQ.Jobs.add_log/5',         keys: ['row'],                                         danger: false, pre: 'row exists' },
    remove_job:      { fn: 'EchoMQ.Jobs.remove_job/4',      keys: ['pending', 'active', 'schedule', 'dead', 'row'], danger: true,  pre: 'not locked' },
    reprocess_job:   { fn: 'EchoMQ.Jobs.reprocess_job/3',   keys: ['dead', 'pending', 'row'],                      danger: false, pre: 'job in dead' }
  };
  function verdict(verb, state) {
    switch (verb) {
      case 'pause':   return ['ok', ':ok &mdash; paused field set; the pending backlog is untouched'];
      case 'resume':  return ['ok', ':ok &mdash; paused field cleared; claiming resumes at the head of pending'];
      case 'drain':   return ['ok', '{:ok, n} &mdash; pending rows + logs deleted; active & the repeat registry survive'];
      case 'obliterate':
        if (state === 'paused_idle') return ['ok', ':more &hellip; :ok &mdash; every set + aux key deleted, bounded by the budget'];
        if (state === 'paused_active') return ['bad', '{:error, :active} &mdash; live active jobs (pass force: true to override)'];
        return ['bad', '{:error, :not_paused} &mdash; a queue must be paused before it can be obliterated'];
      case 'update_data':
        return state === 'job_gone' ? ['bad', '{:error, :gone} &mdash; no such row'] : ['ok', ':ok &mdash; the payload field is replaced'];
      case 'update_progress':
        return state === 'job_gone' ? ['bad', '{:error, :gone} &mdash; no such row'] : ['ok', ':ok &mdash; progress written + a progress event PUBLISHed on emq:{q}:events'];
      case 'add_log':
        return state === 'job_gone' ? ['bad', '{:error, :gone} &mdash; no such row'] : ['ok', '{:ok, count} &mdash; the line appended to the logs list'];
      case 'remove_job':
        if (state === 'job_locked') return ['bad', '{:error, :locked} &mdash; a held job is left untouched'];
        if (state === 'job_gone') return ['bad', '{:error, :gone} &mdash; no such row'];
        return ['ok', ':ok &mdash; removed from its set; row + logs deleted'];
      case 'reprocess_job':
        if (state === 'job_dead') return ['ok', ':ok &mdash; dead &rarr; pending; last_error cleared'];
        if (state === 'job_gone') return ['bad', '{:error, :gone} &mdash; no such row'];
        return ['bad', '{:error, :not_dead} &mdash; only a dead job can be reprocessed'];
      default: return ['dim', '—'];
    }
  }
  var BOXES = ['pending', 'active', 'schedule', 'dead', 'meta', 'row', 'events'];
  var verbSel = document.getElementById('verbSel');
  var stateSel = document.getElementById('stateSel');
  var consoleOut = document.getElementById('consoleOut');
  function renderConsole() {
    if (!verbSel || !stateSel) return;
    var verb = verbSel.value, state = stateSel.value, v = VERBS[verb];
    BOXES.forEach(function (k) {
      var el = document.getElementById('kb-' + k);
      if (!el) return;
      var on = v.keys.indexOf(k) !== -1;
      el.classList.toggle('on', on);
      el.classList.toggle('danger', on && v.danger);
    });
    var r = verdict(verb, state);
    if (consoleOut) {
      consoleOut.innerHTML = '<b>' + v.fn + '</b>' +
        '<br><span class="dim">precondition: ' + v.pre + '</span>' +
        '<br><span class="' + r[0] + '">' + r[1] + '</span>';
    }
  }
  if (verbSel) verbSel.addEventListener('change', renderConsole);
  if (stateSel) stateSel.addEventListener('change', renderConsole);
  renderConsole(); // initial render — correct without interaction
})();
