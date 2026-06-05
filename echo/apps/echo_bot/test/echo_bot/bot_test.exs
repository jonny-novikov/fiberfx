defmodule EchoBot.BotTest do
  @moduledoc """
  The fake-updater handler test (F10.1-D8/D9, US1, US8). Constructed `/start` and `/help` updates
  are fed through the FAKE updater (`ExGram.Updater.Noup`, the `:noup` analog) and routed through
  the real seam; the rendered reply text is asserted. No live Telegram is contacted: the reply is
  captured by a recording adapter instead of `sendMessage`.
  """

  use ExUnit.Case, async: true

  alias EchoBot.Bot
  alias EchoBot.Handlers.Hello
  alias EchoBot.Platform.Telegram
  alias EchoBot.Platform.Update, as: PlatformUpdate
  alias ExGram.Updater.Noup

  # A test double for the platform adapter that records the reply (to a captured reporting pid)
  # instead of sending it over the network — so the fake-updater route is exercised end to end with
  # no live HTTP. The reply is sent to the test process (captured at child_spec build time, since
  # the updater process runs the sink), not to the updater's own mailbox. It reuses the real
  # Telegram normalization (decode → normalize) so the update shape is genuine.
  defmodule RecordingAdapter do
    @behaviour EchoBot.Platform

    @impl true
    def child_spec(opts) do
      sink = Keyword.fetch!(opts, :sink)
      name = Keyword.fetch!(opts, :name)
      wrapped = fn raw -> sink.(Telegram.normalize(raw)) end
      %{id: name, start: {Noup, :start_link, [[sink: wrapped, name: name]]}}
    end

    # `token` carries the reporting pid (encoded by the test) so the reply reaches the test process
    # rather than the updater process running the sink.
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

  # A constructed raw Telegram update map (the JSON shape getUpdates returns), for a /command line.
  defp raw_update(update_id, command_text, chat_id \\ 555) do
    %{
      "update_id" => update_id,
      "message" => %{
        "message_id" => update_id * 10,
        "chat" => %{"id" => chat_id, "type" => "private"},
        "from" => %{"id" => 42, "is_bot" => false, "first_name" => "Tester"},
        "text" => command_text,
        "date" => 1_700_000_000
      }
    }
  end

  describe "the handler as a pure function of the update" do
    test "/start → welcome text" do
      update = Telegram.decode_and_normalize(raw_update(1, "/start"))
      assert Hello.handle(update) == {:reply, Hello.welcome_text()}
    end

    test "/help → help text" do
      update = Telegram.decode_and_normalize(raw_update(2, "/help"))
      assert Hello.handle(update) == {:reply, Hello.help_text()}
    end

    test "a re-delivered update yields the same single reply (idempotent)" do
      update = Telegram.decode_and_normalize(raw_update(7, "/start"))
      assert Hello.handle(update) == Hello.handle(update)
      assert Hello.handle(update) == {:reply, Hello.welcome_text()}
    end

    test "an unmatched command → :noreply" do
      update = Telegram.decode_and_normalize(raw_update(3, "/unknown"))
      assert Hello.handle(update) == :noreply
    end
  end

  describe "the fake updater feeds updates through the routing seam with no live Telegram" do
    setup do
      name = :"fake_updater_#{System.unique_integer([:positive])}"
      reporter = self()

      # The "token" slot carries the reporting pid; RecordingAdapter.send_reply/3 sends the reply
      # there, so the assertion runs in the test process even though the sink runs in the updater.
      sink = fn update -> Bot.route(RecordingAdapter, Hello, reporter, update) end
      spec = RecordingAdapter.child_spec(sink: sink, name: name)

      pid = start_supervised!(spec)
      %{updater: pid}
    end

    test "/start fed via the fake updater is answered with the welcome text", %{updater: updater} do
      raw = ExGram.Model.decode_update(raw_update(10, "/start", 777))
      Noup.deliver(updater, raw)
      assert_received {:reply_sent, 777, text}
      assert text == Hello.welcome_text()
    end

    test "/help fed via the fake updater is answered with the help text", %{updater: updater} do
      raw = ExGram.Model.decode_update(raw_update(11, "/help", 888))
      Noup.deliver(updater, raw)
      assert_received {:reply_sent, 888, text}
      assert text == Hello.help_text()
    end

    test "the same update twice produces the same single reply each time (no doubling)", %{
      updater: updater
    } do
      raw = ExGram.Model.decode_update(raw_update(12, "/start", 999))

      # First delivery: exactly ONE reply effect (not two) — assert one, then assert the mailbox
      # holds no second {:reply_sent, ...} for this delivery.
      Noup.deliver(updater, raw)
      assert_received {:reply_sent, 999, first}
      refute_received {:reply_sent, 999, _extra}

      # Re-deliver the SAME update (Telegram's resend of the same update_id): one more reply,
      # identical text, and still no duplicate effect from a single delivery (INV7).
      Noup.deliver(updater, raw)
      assert_received {:reply_sent, 999, second}
      refute_received {:reply_sent, 999, _another}

      assert first == second
      assert first == Hello.welcome_text()
    end
  end
end
