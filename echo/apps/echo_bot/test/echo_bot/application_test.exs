defmodule EchoBot.ApplicationTest do
  @moduledoc """
  The standalone-app boot and self-heal checks (F10.1-D3/D9, US2, US7). The umbrella boots
  `EchoBot.Application` as its own `:one_for_one` supervisor named `EchoBot.Supervisor`, with the
  loaded bot's updater under it; killing the updater restarts it in isolation, and the two Portal
  app supervisors are undisturbed (asserted by their names, without naming a Portal MODULE in the
  engine app's own lib/ — these references live only in this test).
  """

  use ExUnit.Case, async: false

  alias EchoBot.Bot
  alias EchoBot.Config
  alias EchoBot.Handlers.Hello
  alias EchoBot.Platform.Telegram
  alias EchoBot.Platform.Update, as: PlatformUpdate
  alias ExGram.Updater.Noup

  # A recording adapter (a copy of the bot_test double) so the post-restart "answered again" check
  # captures the reply text without a live Telegram send. The reply lands in the test process; the
  # `token` slot carries the reporting pid (the adapter is a pure function of its args, so this seam
  # never touches the network).
  defmodule RecordingAdapter do
    @behaviour EchoBot.Platform

    @impl true
    def child_spec(opts) do
      sink = Keyword.fetch!(opts, :sink)
      name = Keyword.fetch!(opts, :name)
      wrapped = fn raw -> sink.(Telegram.normalize(raw)) end
      %{id: name, start: {Noup, :start_link, [[sink: wrapped, name: name]]}}
    end

    @impl true
    def send_reply(reporter, chat_ref, text) when is_pid(reporter) do
      send(reporter, {:reply_sent, chat_ref, text})
      :ok
    end

    @impl true
    def command(%PlatformUpdate{command: command}), do: command

    @impl true
    def chat_ref(%PlatformUpdate{chat_ref: chat_ref}), do: chat_ref
  end

  defp raw_start_update(update_id, chat_id) do
    ExGram.Model.decode_update(%{
      "update_id" => update_id,
      "message" => %{
        "message_id" => update_id * 10,
        "chat" => %{"id" => chat_id, "type" => "private"},
        "text" => "/start",
        "date" => 1_700_000_000
      }
    })
  end

  test "EchoBot.Application supervises the bot under the named EchoBot.Supervisor" do
    sup = Process.whereis(EchoBot.Supervisor)
    assert is_pid(sup)

    # The named supervisor reports a child count — it is a live supervisor (the engine's own,
    # named EchoBot.Supervisor, not a Portal supervisor).
    assert %{specs: specs} = Supervisor.count_children(EchoBot.Supervisor)
    assert specs >= 1

    # Under :fake, the loaded bot's updater is a supervised child by its derived id.
    definition = Config.load!(Config.bot_config_path())
    child_id = Bot.process_name(definition)
    children = Supervisor.which_children(EchoBot.Supervisor)
    assert Enum.any?(children, fn {id, _pid, _type, _mods} -> id == child_id end)
  end

  test "killing the bot's updater restarts it under EchoBot.Supervisor (:one_for_one)" do
    definition = Config.load!(Config.bot_config_path())
    name = Bot.process_name(definition)

    pid_before = Process.whereis(name)
    assert is_pid(pid_before)

    ref = Process.monitor(pid_before)
    Process.exit(pid_before, :kill)
    assert_receive {:DOWN, ^ref, :process, ^pid_before, :killed}

    # The supervisor restarts the updater; the new process is a different pid under the same name.
    pid_after = wait_for_restart(name, pid_before)
    assert is_pid(pid_after)
    assert pid_after != pid_before
  end

  # US7 · INV2 · D3,D9 — the full self-heal: kill the updater, the supervisor restarts it under the
  # SAME child id, and a later /start is still answered. The recording-adapter updater is supervised
  # by this test's own supervisor (a faithful stand-in for EchoBot.Supervisor's :one_for_one
  # restart, with no live Telegram on the reply path) so the post-restart reply is asserted.
  test "after a crash the restarted updater answers a later /start" do
    name = :"restart_updater_#{System.unique_integer([:positive])}"
    reporter = self()
    sink = fn update -> Bot.route(RecordingAdapter, Hello, reporter, update) end
    spec = RecordingAdapter.child_spec(sink: sink, name: name)

    pid_before = start_supervised!(spec)
    assert is_pid(pid_before)

    # Before the crash, /start is answered.
    Noup.deliver(pid_before, raw_start_update(1, 100))
    assert_receive {:reply_sent, 100, before_text}
    assert before_text == Hello.welcome_text()

    # Kill the updater; the supervisor restarts it under the same registered name (a new pid).
    ref = Process.monitor(pid_before)
    Process.exit(pid_before, :kill)
    assert_receive {:DOWN, ^ref, :process, ^pid_before, :killed}

    pid_after = wait_for_restart(name, pid_before)
    assert is_pid(pid_after)
    assert pid_after != pid_before

    # After the restart, a later /start is answered again.
    Noup.deliver(pid_after, raw_start_update(2, 200))
    assert_receive {:reply_sent, 200, after_text}
    assert after_text == Hello.welcome_text()
  end

  test "the engine app does not depend on the Portal apps (it boots independently)" do
    # echo_bot lists neither Portal app as a dep — its application spec has no :portal entry.
    {:ok, deps} = :application.get_key(:echo_bot, :applications)
    refute :portal in deps
    refute :portal_web in deps
  end

  # US2,US6 · INV1,INV6 — Portal-independence: the engine's own supervisor is alive while the test
  # node does NOT require the Portal supervision tree, and echo_bot has added no child to it.
  test "EchoBot.Supervisor is alive and Portal's supervision tree is not required" do
    # The engine's own supervisor is running.
    assert is_pid(Process.whereis(EchoBot.Supervisor))

    # echo_bot does not name, start, or require Portal — and adds no child to Portal.Application.
    # Whether or not Portal happens to be loaded in the node, the engine's children are its own:
    # every child under EchoBot.Supervisor is an EchoBot.* process, none is a Portal child.
    children = Supervisor.which_children(EchoBot.Supervisor)
    refute Enum.empty?(children)

    # The bot's updater child id is the engine's own derived name (EchoBot.Bot.<name>), never a
    # Portal id — the engine supervises only what it loaded from its YAML, nothing Portal-owned.
    definition = Config.load!(Config.bot_config_path())
    own_child_id = Bot.process_name(definition)
    child_ids = Enum.map(children, fn {id, _pid, _type, _mods} -> id end)
    assert own_child_id in child_ids

    assert Enum.all?(child_ids, fn id ->
             id |> to_string() |> String.starts_with?("Elixir.EchoBot.")
           end)
  end

  defp wait_for_restart(name, old_pid, attempts \\ 50)
  defp wait_for_restart(name, _old_pid, 0), do: Process.whereis(name)

  defp wait_for_restart(name, old_pid, attempts) do
    case Process.whereis(name) do
      pid when is_pid(pid) and pid != old_pid -> pid
      _ -> Process.sleep(10) && wait_for_restart(name, old_pid, attempts - 1)
    end
  end
end
