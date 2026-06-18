(function () {
  "use strict";

  /* ---------- hero: the @claim transition stepper (pure over a fixed dataset) ---------- */
  var MOVES = [
    { id: 'pop', title: 'Move 1 — pop the oldest',
      line: "local popped = redis.call('ZPOPMIN', KEYS[1]) ; if #popped == 0 then return {}",
      note: 'ZPOPMIN removes the lexically-smallest member — the mint-oldest id — before any other claimer can pop it; an empty pop returns {} (:empty)' },
    { id: 'token', title: 'Move 2 — mint the fencing token',
      line: "local att = redis.call('HINCRBY', jk, 'attempts', 1)",
      note: 'attempts is incremented and the new value kept — this number IS the fencing token the worker must present to complete or extend' },
    { id: 'active', title: 'Move 3 — set the row active',
      line: "redis.call('HSET', jk, 'state', 'active')",
      note: 'the row state moves to active; the row already carries the payload and the incremented attempts' },
    { id: 'lease', title: 'Move 4 — score the lease',
      line: "ZADD KEYS[2] (now + tonumber(ARGV[2])) id ; return {id, payload, att}",
      note: 'now is the SERVER clock (TIME); now + lease is the deadline, stored as the active-set score — so the active set is an index of leases by expiry' }
  ];
  function describeMove(i) {
    var m = MOVES[i];
    return '<b>' + m.title + '</b><br><span class="dim">' + m.line + '</span><br>' + m.note + '.';
  }
  function setMove(i) {
    MOVES.forEach(function (_, k) {
      var g = document.getElementById('m-' + k);
      if (g) g.classList.toggle('on', k === i);
    });
    var out = document.getElementById('stepOut');
    if (out) out.innerHTML = describeMove(i);
  }
  document.querySelectorAll('#stepSel button').forEach(function (b) {
    b.addEventListener('click', function () {
      var i = parseInt(b.getAttribute('data-move'), 10);
      document.querySelectorAll('#stepSel button').forEach(function (x) {
        var sel = x === b; x.classList.toggle('active', sel); x.setAttribute('aria-pressed', sel ? 'true' : 'false');
      });
      setMove(i);
    });
  });
  setMove(0); // initial render — correct without interaction

  /* ---------- content: claim arithmetic (the real @claim math over a fixed job) ---------- */
  /* The example job JOB0KHTOWnGLuC has attempts = 0 before this claim (just
     enqueued). @claim does HINCRBY attempts 1 -> 1 (the token), and ZADD active
     at now + lease (the deadline). Pure functions of (now, lease) over the fixed
     prior attempts. A second claimer finds pending already popped -> :empty. */
  var PRIOR_ATTEMPTS = 0;
  function render(now, lease) {
    var attEl = document.getElementById('insp-att');
    var scoreEl = document.getElementById('insp-score');
    var out = document.getElementById('inspOut');
    var token = PRIOR_ATTEMPTS + 1;           // HINCRBY attempts 1
    var deadline = now + lease;               // ZADD active (now + lease)
    if (attEl) attEl.textContent = PRIOR_ATTEMPTS + ' → ' + token;
    if (scoreEl) scoreEl.textContent = String(deadline);
    if (!out) return;
    out.innerHTML = 'claim JOB0KHTOWnGLuC &middot; lease ' + lease + 'ms' +
      '<br>HINCRBY attempts &rarr; token = <b>' + token + '</b> &middot; ' +
      'ZADD active score = now + lease = <b>' + deadline + '</b>' +
      '<br>worker receives <span class="ok">{:ok, {JOB0KHTOWnGLuC, payload, ' + token + '}}</span>' +
      '<br><span class="dim">a second claimer racing this one finds ZPOPMIN already removed the id &rarr; :empty — two workers cannot hold the same job</span>';
  }
  var nowRange = document.getElementById('nowRange');
  var leaseRange = document.getElementById('leaseRange');
  var nowVal = document.getElementById('nowVal');
  var leaseVal = document.getElementById('leaseVal');
  function sync() {
    var now = parseInt(nowRange.value, 10), lease = parseInt(leaseRange.value, 10);
    if (nowVal) nowVal.textContent = String(now);
    if (leaseVal) leaseVal.textContent = String(lease);
    render(now, lease);
  }
  if (nowRange && leaseRange) {
    nowRange.addEventListener('input', sync);
    leaseRange.addEventListener('input', sync);
    sync(); // initial render — correct without interaction
  }

})();
