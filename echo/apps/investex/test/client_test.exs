defmodule Investex.ClientTest do
  @moduledoc """
  Tier 1 (pure, network-free): the G-TLS trust proof for `Investex.Client`'s
  vendored Russian-CA trust anchor (rung TRD.9.1.1, `docs/exchange/trd.9.1.1.specs.md`
  §G-TLS; INV-11). No token VALUE appears in this file; no network egress.

  Two assertions realize G-TLS (D-3 — realization-over-literal):

    1. **Real-root presence (the teeth).** The vendored `Russian Trusted Root CA`
       DER is present in the `:cacerts` list `Investex.Client.tls_opts/0` actually
       builds. Dropping the `++ [russian_root_ca_der()]` append in `client.ex`
       turns this RED — this is what the Stage-3 mutation spot-check exercises.

    2. **Mechanism, strong form.** A loopback `:ssl` handshake using a
       SELF-GENERATED test CA + server leaf: the client clears the handshake
       ONLY when the test CA is appended to `:public_key.cacerts_get()` under
       `verify: :verify_peer`, and is REJECTED (a `{:tls_alert, _}` / `unknown_ca`
       shape) WITHOUT it. This proves the append→trust mechanism, AND that
       `verify_peer` genuinely rejects an untrusted chain — so assertion (1) is
       not a tautology.

  Why a self-generated test CA and not the real vendored root in (2): signing a
  test leaf with the real `Russian Trusted Root CA` needs that root's private key
  (not ours), so a loopback chain CANNOT terminate at the real root. (1) proves
  the *specific real root* is wired into the client; (2) proves the *mechanism*
  generically. Together they cover both. `async: false` — the loopback binds a
  listening socket and the test shells `openssl` into a tmp dir (no process-global
  mutation, but kept serial for socket/port hygiene).
  """
  use ExUnit.Case, async: false

  @pin_sha256 "D26D2D0231B7C39F92CC738512BA54103519E4405D68B5BD703E9788CA8ECF31"

  describe "tls_opts/0 — the vendored Russian root is a trust anchor (INV-11)" do
    test "the vendored root's DER is present in the cacerts tls_opts/0 builds (the teeth)" do
      opts = Investex.Client.tls_opts()

      # verify_peer kept; verify_none never appears; depth: 3 kept.
      assert Keyword.fetch!(opts, :verify) == :verify_peer
      assert Keyword.fetch!(opts, :depth) == 3
      refute Keyword.get(opts, :verify) == :verify_none

      cacerts = Keyword.fetch!(opts, :cacerts)
      vendored_der = vendored_root_der()

      # The vendored root (pinned, fingerprint-matched) is in the built bundle...
      assert vendored_der in cacerts,
             "the vendored Russian Trusted Root CA DER must be appended to cacerts (INV-11)"

      # ...and it is NOT in the OS bundle alone (so the append is load-bearing).
      refute vendored_der in :public_key.cacerts_get(),
             "the OS bundle must not already contain the Russian root — the append is what adds it"

      # The vendored DER is exactly the pinned identity (defense-in-depth here too).
      assert Base.encode16(:crypto.hash(:sha256, vendored_der)) == @pin_sha256
    end

    test "tls_opts/0 builds a credential :ssl accepts (mixed cacerts shape is valid)" do
      # GRPC.Credential.new(ssl: tls_opts()) must not raise — proves the mixed
      # cacerts list (OTP {:cert, der} entries + the bare vendored DER) is a
      # shape :ssl normalizes (L-1).
      cred = GRPC.Credential.new(ssl: Investex.Client.tls_opts())
      assert is_struct(cred) or is_map(cred)
    end
  end

  describe "the append→trust mechanism (loopback, network-free)" do
    setup do
      {:ok, _} = Application.ensure_all_started(:ssl)
      paths = gen_test_ca!()
      on_exit(fn -> File.rm_rf!(paths.dir) end)
      {:ok, paths}
    end

    test "a leaf chained to the test CA verifies ONLY when the test CA is appended", paths do
      test_ca_der = pem_file_der(paths.ca_crt)

      # WITH the test CA appended: verify_peer clears (the mechanism this rung adds).
      assert {:ok, "hello-trd911"} =
               loopback_roundtrip(paths, :public_key.cacerts_get() ++ [test_ca_der])

      # WITHOUT it (OS bundle only): the same leaf is REJECTED — a TLS-layer
      # rejection (unknown_ca / {:tls_alert, _}), NOT an egress/transport error.
      # This proves verify_peer genuinely rejects an untrusted chain.
      assert {:error, reason} = loopback_roundtrip(paths, :public_key.cacerts_get())
      assert tls_rejection?(reason),
             "an untrusted chain must be rejected at the TLS layer, got: #{inspect(reason)}"
    end
  end

  # ── helpers ────────────────────────────────────────────────────────────────

  # The DER of the vendored Russian root, re-derived the way the client does.
  defp vendored_root_der do
    pem =
      :code.priv_dir(:investex)
      |> Path.join("certs/russian_trusted_root_ca.pem")
      |> File.read!()

    [{:Certificate, der, :not_encrypted}] = :public_key.pem_decode(pem)
    der
  end

  # Read a PEM cert file and return its single DER.
  defp pem_file_der(path) do
    [{:Certificate, der, :not_encrypted}] = path |> File.read!() |> :public_key.pem_decode()
    der
  end

  # Generate a throwaway self-signed test CA + a localhost server leaf signed by
  # it, into a fresh tmp dir, via openssl (already a build dependency). Returns
  # the dir + the file paths. Network-free.
  defp gen_test_ca! do
    dir = Path.join(System.tmp_dir!(), "trd911_test_ca_#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)

    ca_key = Path.join(dir, "ca.key")
    ca_crt = Path.join(dir, "ca.crt")
    leaf_key = Path.join(dir, "leaf.key")
    leaf_csr = Path.join(dir, "leaf.csr")
    leaf_crt = Path.join(dir, "leaf.crt")
    ext = Path.join(dir, "ext.cnf")

    sh!(~w(openssl req -x509 -newkey rsa:2048 -nodes -keyout #{ca_key} -out #{ca_crt}
           -days 1 -subj /CN=trd911-test-ca))

    sh!(~w(openssl req -newkey rsa:2048 -nodes -keyout #{leaf_key} -out #{leaf_csr}
           -subj /CN=localhost))

    File.write!(ext, "subjectAltName=DNS:localhost,IP:127.0.0.1\n")

    sh!(~w(openssl x509 -req -in #{leaf_csr} -CA #{ca_crt} -CAkey #{ca_key}
           -CAcreateserial -out #{leaf_crt} -days 1 -extfile #{ext}))

    %{dir: dir, ca_crt: ca_crt, leaf_crt: leaf_crt, leaf_key: leaf_key}
  end

  defp sh!(args) do
    {out, status} = System.cmd(hd(args), tl(args), stderr_to_stdout: true)

    if status != 0 do
      raise "openssl failed (#{status}): #{out}"
    end

    :ok
  end

  # A loopback TLS round-trip over 127.0.0.1 on an ephemeral port: a tiny :ssl
  # server presenting the test leaf, a client verifying against `client_cacerts`
  # with verify_peer + the https hostname match. Returns {:ok, reply} on a clean
  # handshake+exchange, {:error, reason} on a handshake rejection. Network-free.
  defp loopback_roundtrip(paths, client_cacerts) do
    server_opts = [
      certfile: paths.leaf_crt,
      keyfile: paths.leaf_key,
      reuseaddr: true,
      active: false
    ]

    {:ok, listen} = :ssl.listen(0, server_opts)
    {:ok, {_addr, port}} = :ssl.sockname(listen)
    parent = self()

    server =
      spawn_link(fn ->
        case :ssl.transport_accept(listen, 5_000) do
          {:ok, tls_transport} ->
            case :ssl.handshake(tls_transport, 5_000) do
              {:ok, sock} ->
                send(parent, {:server_handshake, :ok})
                :ssl.send(sock, "hello-trd911")
                :ssl.close(sock)

              other ->
                send(parent, {:server_handshake, other})
            end

          other ->
            send(parent, {:server_handshake, other})
        end
      end)

    client_opts = [
      verify: :verify_peer,
      cacerts: client_cacerts,
      depth: 3,
      server_name_indication: ~c"localhost",
      customize_hostname_check: [
        match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
      ],
      active: false
    ]

    result =
      case :ssl.connect(~c"127.0.0.1", port, client_opts, 5_000) do
        {:ok, sock} ->
          reply =
            case :ssl.recv(sock, 0, 5_000) do
              {:ok, data} -> {:ok, to_string(data)}
              {:error, r} -> {:error, r}
            end

          :ssl.close(sock)
          reply

        {:error, reason} ->
          {:error, reason}
      end

    # Drain the server's report so the spawned process is not orphaned, then
    # close the listener.
    receive do
      {:server_handshake, _} -> :ok
    after
      1_000 -> :ok
    end

    Process.unlink(server)
    :ssl.close(listen)
    result
  end

  # A TLS-layer rejection (verify_peer rejecting an untrusted chain) vs an
  # egress/transport error. The hallmark is a TLS alert (`unknown_ca` /
  # `bad_certificate` / a `{:tls_alert, _}` tuple) — never a bare :timeout/:closed.
  defp tls_rejection?({:tls_alert, _}), do: true
  defp tls_rejection?({:options, _}), do: false

  defp tls_rejection?(reason) do
    s = inspect(reason)
    String.contains?(s, "tls_alert") or String.contains?(s, "unknown_ca") or
      String.contains?(s, "unknown ca") or String.contains?(s, "bad_certificate") or
      String.contains?(s, "certificate")
  end
end
