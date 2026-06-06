defmodule Portal.AuthTest do
  @moduledoc """
  Unit test for the `Portal.Auth` facade (F6.8.1-AS3, D3/D4, INV3/INV4).

  Proves the honest door: `sign_in/2` returns the IDENTICAL `{:error,
  :invalid_credentials}` for a wrong name AND a wrong password, and `{:ok, %Session{}}`
  with a branded `SES` id for valid credentials; `request_reset/1` returns the identical
  `:ok` whether the email matches an account or not (no enumeration).

  `async: false` + a `Portal.Store.reset/0` in `setup` give per-test isolation against
  the same-millisecond branded-id collision hazard (echo/CLAUDE.md §4) — `sign_in/2`
  mints a `SES` id.
  """
  use ExUnit.Case, async: false

  alias Portal.Accounts.Session

  # The seeded demonstration credential (Portal.Accounts @credentials).
  @good_ident "ada"
  @good_email "ada@portal.dev"
  @good_pass "correct-horse"

  setup do
    Portal.Store.reset()
    :ok
  end

  describe "sign_in/2 — the honest door (INV3)" do
    test "a non-existent identifier returns {:error, :invalid_credentials}" do
      assert Portal.Auth.sign_in("nobody", "whatever") == {:error, :invalid_credentials}
    end

    test "an existing identifier with a WRONG password returns the IDENTICAL error" do
      wrong_name = Portal.Auth.sign_in("nobody", "whatever")
      wrong_pass = Portal.Auth.sign_in(@good_ident, "wrong-password")

      assert wrong_pass == {:error, :invalid_credentials}
      # Byte-identical: a caller cannot distinguish which half failed.
      assert wrong_pass == wrong_name
    end

    test "valid credentials return {:ok, %Session{}} with a branded SES id (INV4)" do
      assert {:ok, %Session{} = session} = Portal.Auth.sign_in(@good_ident, @good_pass)
      assert String.starts_with?(session.id, "SES")
      assert Portal.ID.valid?(session.id)
      assert is_binary(session.user_id)
      assert is_binary(session.token)
    end

    test "the email also resolves the same account (username OR email)" do
      assert {:ok, %Session{} = a} = Portal.Auth.sign_in(@good_ident, @good_pass)
      assert {:ok, %Session{} = b} = Portal.Auth.sign_in(@good_email, @good_pass)
      assert a.user_id == b.user_id
    end
  end

  describe "request_reset/1 — no enumeration (INV3)" do
    test "a matching email returns :ok" do
      assert Portal.Auth.request_reset(@good_email) == :ok
    end

    test "a non-matching email returns the IDENTICAL :ok" do
      matching = Portal.Auth.request_reset(@good_email)
      missing = Portal.Auth.request_reset("nobody@nowhere.test")

      assert missing == :ok
      assert missing == matching
    end
  end
end
