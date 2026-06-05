defmodule EchoBot.Config do
  @moduledoc """
  The YAML **v1.0** config loader (F10.1-INV5). A bot exists because a YAML v1.0 file declares
  it — no bot is hard-coded in the engine.

  The loader reads the `version` field **first** and validates it is `"1.0"`, then validates the
  rest against the v1.0 schema and returns the five-key definition. The five required keys are
  `version` (`"1.0"`), `name`, `platform`, `token_env`, and `handler`. The loader:

  - resolves `token_env` to the named environment variable's value **at boot** — the token is
    NEVER written in the YAML and never compiled in (F10.1-INV5, R8);
  - selects the platform adapter from `platform` (`telegram` → `EchoBot.Platform.Telegram`);
  - resolves `handler` to the handler module that routes the bot's commands.

  Loud failure on a missing/unknown version, an unknown platform, a missing required key, or a
  missing/empty token — each is a startup error, surfaced before the bot supervises.
  """

  alias EchoBot.Platform.Telegram, as: TelegramPlatform

  @supported_version "1.0"
  @required_keys ~w(version name platform token_env handler)
  @platforms %{"telegram" => TelegramPlatform}

  @typedoc "A loaded bot definition — the five validated fields plus the resolved adapter + token."
  @type definition :: %{
          version: String.t(),
          name: String.t(),
          platform: String.t(),
          adapter: module(),
          token_env: String.t(),
          token: String.t(),
          handler: module()
        }

  @doc """
  Load and validate the bot definition from `path` (a YAML v1.0 file), resolving the token from
  the env var the YAML names. Returns `{:ok, definition}` or `{:error, reason}`.

  Reads the `version` first; a non-`"1.0"` version is rejected before any other field is trusted.
  """
  @spec load(Path.t()) :: {:ok, definition()} | {:error, term()}
  def load(path) do
    with {:ok, raw} <- read_yaml(path),
         :ok <- validate_version(raw),
         :ok <- validate_required(raw),
         {:ok, adapter} <- select_adapter(raw),
         {:ok, handler} <- resolve_handler(raw),
         {:ok, token} <- resolve_token(raw) do
      {:ok,
       %{
         version: Map.fetch!(raw, "version"),
         name: Map.fetch!(raw, "name"),
         platform: Map.fetch!(raw, "platform"),
         adapter: adapter,
         token_env: Map.fetch!(raw, "token_env"),
         token: token,
         handler: handler
       }}
    end
  end

  @doc "Load the bot definition or raise — the boot path, where a bad config must fail loudly."
  @spec load!(Path.t()) :: definition()
  def load!(path) do
    case load(path) do
      {:ok, definition} ->
        definition

      {:error, reason} ->
        raise ArgumentError, "invalid bot config #{inspect(path)}: #{inspect(reason)}"
    end
  end

  @doc """
  The config-file path for the single bot, resolved from application config
  (`config :echo_bot, :bot_config`). A relative path resolves against the `:echo_bot` priv dir.
  """
  @spec bot_config_path() :: Path.t()
  def bot_config_path do
    case Application.get_env(:echo_bot, :bot_config) do
      nil -> Path.join(:code.priv_dir(:echo_bot), "bots/hello_bot.yaml")
      path when is_binary(path) -> resolve_path(path)
    end
  end

  defp resolve_path(path) do
    if Path.type(path) == :absolute, do: path, else: Path.join(:code.priv_dir(:echo_bot), path)
  end

  defp read_yaml(path) do
    case YamlElixir.read_from_file(path) do
      {:ok, raw} when is_map(raw) -> {:ok, raw}
      {:ok, _other} -> {:error, :not_a_mapping}
      {:error, reason} -> {:error, {:yaml, reason}}
    end
  end

  # Read the `version` FIRST and validate it before trusting any other field (F10.1-INV5).
  defp validate_version(%{"version" => @supported_version}), do: :ok
  defp validate_version(%{"version" => other}), do: {:error, {:unsupported_version, other}}
  defp validate_version(_), do: {:error, :missing_version}

  defp validate_required(raw) do
    case Enum.reject(@required_keys, &Map.has_key?(raw, &1)) do
      [] -> :ok
      missing -> {:error, {:missing_keys, missing}}
    end
  end

  defp select_adapter(%{"platform" => platform}) do
    case Map.fetch(@platforms, platform) do
      {:ok, adapter} -> {:ok, adapter}
      :error -> {:error, {:unknown_platform, platform}}
    end
  end

  # The handler is named in the YAML as an Elixir module string ("EchoBot.Handlers.Hello"); a
  # name that resolves to no loaded module is a config error, surfaced at boot.
  defp resolve_handler(%{"handler" => handler}) when is_binary(handler) do
    module = Module.concat([handler])

    if Code.ensure_loaded?(module) do
      {:ok, module}
    else
      {:error, {:unknown_handler, handler}}
    end
  end

  defp resolve_handler(_), do: {:error, :invalid_handler}

  # Resolve the token from the named env var at boot — the token is NOT in the YAML. A missing
  # or empty env value fails loudly (F10.1-R8).
  defp resolve_token(%{"token_env" => token_env}) when is_binary(token_env) do
    case System.get_env(token_env) do
      nil -> {:error, {:missing_token, token_env}}
      "" -> {:error, {:empty_token, token_env}}
      token -> {:ok, token}
    end
  end

  defp resolve_token(_), do: {:error, :invalid_token_env}
end
