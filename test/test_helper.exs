ExUnit.configure(exclude: [pending: true])
ExUnit.start(capture_log: System.get_env("CAPTURE_LOG", "true") == "true")

if System.version() >= "1.11" do
  Logger.put_module_level(PathGlob, :debug)
end
