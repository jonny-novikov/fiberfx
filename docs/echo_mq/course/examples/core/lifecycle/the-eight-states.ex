# the eight states → their keys (EchoMQ.Keys), against emq:{q}
  wait             LIST   emq:{q}:wait              Keys.wait/1
  paused           LIST   emq:{q}:paused            Keys.paused/1
  delayed          ZSET   emq:{q}:delayed           Keys.delayed/1 · score = run-at
  prioritized      ZSET   emq:{q}:prioritized       Keys.prioritized/1 · score = priority
  active           LIST   emq:{q}:active            Keys.active/1 · lock held
  completed        ZSET   emq:{q}:completed         Keys.completed/1 · terminal · score = finished-at
  failed           ZSET   emq:{q}:failed            Keys.failed/1 · terminal
  waiting-children ZSET   emq:{q}:waiting-children  Keys.waiting_children/1
