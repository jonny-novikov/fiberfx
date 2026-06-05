defmodule EchoBot.ConfigTest do
  @moduledoc """
  The YAML v1.0 loader test (F10.1-D8/D9, US4). A sample v1.0 file yields one definition with the
  five fields — the `version` read and validated, the adapter selected from `platform`, and the
  token resolved from the named env var (and absent from the YAML).
  """

  use ExUnit.Case, async: true

  alias EchoBot.Config
  alias EchoBot.Handlers.Hello
  alias EchoBot.Platform.Telegram

  @token_env "ECHO_BOT_CONFIG_TEST_TOKEN"

  setup do
    # The token lives in the env var the YAML names — never in the file.
    System.put_env(@token_env, "secret-token-value")
    on_exit(fn -> System.delete_env(@token_env) end)
    :ok
  end

  defp write_yaml(contents) do
    path =
      Path.join(System.tmp_dir!(), "echo_bot_config_#{System.unique_integer([:positive])}.yaml")

    File.write!(path, contents)
    on_exit(fn -> File.rm(path) end)
    path
  end

  test "a YAML v1.0 file yields one definition with the five validated fields and a resolved token" do
    path =
      write_yaml("""
      version: "1.0"
      name: hello_bot
      platform: telegram
      token_env: #{@token_env}
      handler: EchoBot.Handlers.Hello
      """)

    assert {:ok, definition} = Config.load(path)

    # The five v1.0 fields, the version validated.
    assert definition.version == "1.0"
    assert definition.name == "hello_bot"
    assert definition.platform == "telegram"
    assert definition.token_env == @token_env
    assert definition.handler == Hello

    # The adapter is selected from `platform`.
    assert definition.adapter == Telegram

    # The token is resolved from the env var — not present anywhere in the YAML source.
    assert definition.token == "secret-token-value"
    refute File.read!(path) =~ "secret-token-value"
  end

  test "the version is read first — a non-1.0 version is rejected before other fields are trusted" do
    path =
      write_yaml("""
      version: "2.0"
      name: hello_bot
      platform: telegram
      token_env: #{@token_env}
      handler: EchoBot.Handlers.Hello
      """)

    assert {:error, {:unsupported_version, "2.0"}} = Config.load(path)
  end

  test "an unknown platform is rejected" do
    path =
      write_yaml("""
      version: "1.0"
      name: hello_bot
      platform: discord
      token_env: #{@token_env}
      handler: EchoBot.Handlers.Hello
      """)

    assert {:error, {:unknown_platform, "discord"}} = Config.load(path)
  end

  test "a missing token (env var unset) fails loudly — not a silent nil" do
    System.delete_env(@token_env)

    path =
      write_yaml("""
      version: "1.0"
      name: hello_bot
      platform: telegram
      token_env: #{@token_env}
      handler: EchoBot.Handlers.Hello
      """)

    # A clear failure, not a silent nil — the missing env var is named in the error.
    assert {:error, {:missing_token, @token_env}} = Config.load(path)
  end

  test "an empty token (env var set to \"\") fails loudly — not a silent empty string" do
    System.put_env(@token_env, "")

    path =
      write_yaml("""
      version: "1.0"
      name: hello_bot
      platform: telegram
      token_env: #{@token_env}
      handler: EchoBot.Handlers.Hello
      """)

    assert {:error, {:empty_token, @token_env}} = Config.load(path)
  end

  test "a file with no version key is rejected before any other field is trusted" do
    path =
      write_yaml("""
      name: hello_bot
      platform: telegram
      token_env: #{@token_env}
      handler: EchoBot.Handlers.Hello
      """)

    assert {:error, :missing_version} = Config.load(path)
  end

  test "a missing required key is reported by name (a loud config error)" do
    # `handler` omitted — the loader reports exactly which v1.0 key is missing.
    path =
      write_yaml("""
      version: "1.0"
      name: hello_bot
      platform: telegram
      token_env: #{@token_env}
      """)

    assert {:error, {:missing_keys, ["handler"]}} = Config.load(path)
  end

  test "a handler that resolves to no loaded module is rejected (not a silent unknown module)" do
    path =
      write_yaml("""
      version: "1.0"
      name: hello_bot
      platform: telegram
      token_env: #{@token_env}
      handler: EchoBot.Handlers.DoesNotExist
      """)

    assert {:error, {:unknown_handler, "EchoBot.Handlers.DoesNotExist"}} = Config.load(path)
  end

  test "load! raises loudly on an invalid config (the boot path)" do
    path =
      write_yaml("""
      version: "9.9"
      name: hello_bot
      platform: telegram
      token_env: #{@token_env}
      handler: EchoBot.Handlers.Hello
      """)

    assert_raise ArgumentError, ~r/invalid bot config/, fn -> Config.load!(path) end
  end

  test "the platform field selects EchoBot.Platform.Telegram and the handler routes its commands" do
    # US4 third criterion: `platform: telegram` selects the Telegram adapter and the named
    # `handler` module routes the bot's commands.
    path =
      write_yaml("""
      version: "1.0"
      name: hello_bot
      platform: telegram
      token_env: #{@token_env}
      handler: EchoBot.Handlers.Hello
      """)

    assert {:ok, definition} = Config.load(path)
    assert definition.adapter == Telegram
    assert definition.handler == Hello
    # The selected handler routes /start to the welcome text — the wiring the YAML named.
    update = %EchoBot.Platform.Update{update_id: 1, chat_ref: 1, command: "start"}
    assert definition.handler.handle(update) == {:reply, Hello.welcome_text()}
  end
end
