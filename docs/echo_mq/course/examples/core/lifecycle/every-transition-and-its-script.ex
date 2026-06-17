# transition          script                 KEYS   reached from Elixir
  pickup              moveToActive-11        11     EchoMQ.Scripts.move_to_active/4
  completion          moveToFinished-14      14     EchoMQ.Scripts.move_to_finished/7
  retry               moveToDelayed-8        8      EchoMQ.Scripts.move_to_delayed/6
  stalled recovery    moveStalledJobsToWait-8  8      driven by the stalled-checker process
