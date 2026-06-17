# EchoMQ.Scripts — the compile-time registry (verified in scripts.ex)
  @scripts_path  ->  priv/scripts            # the directory of .lua files

  # every .lua file is registered as a compile dependency:
  @external_resource Path.join(@scripts_path, file)

  # the filename is parsed; the trailing number is the KEYS arity:
  ~r/^(.+)-(\d+)\.lua$/      # "moveToActive-11.lua" -> name "moveToActive", KEYS 11
