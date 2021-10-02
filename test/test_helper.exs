ExUnit.start(capture_log: System.get_env("CAPTURE_LOG", "true") == "true")
Logger.put_module_level(PathGlob, :debug)
