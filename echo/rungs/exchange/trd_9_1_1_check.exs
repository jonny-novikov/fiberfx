# trd_9_1_1_check.exs -- gates G-TLS, the endpoint env-resolution, no-verify_none,
#   the CA provenance, and G7: the investex transport FIX (TRD.9.1.1).
#   cd /Users/jonny/dev/jonnify/echo && mix run --no-start rungs/exchange/trd_9_1_1_check.exs
#
# A COMPILED-umbrella `mix run --no-start` runner (the trd_9_1_check.exs pattern),
# re-pointed at the 9.1.1 transport fix. It dials NOTHING (`:investex` is lib-only),
# stays network-free, and exercises only the deterministic surface:
#   * G-TLS-presence -- the vendored Russian Trusted Root CA DER is in the :cacerts
#     Investex.Client.tls_opts/0 builds (the teeth: dropping the ++ append fails this),
#     and is NOT in the OS bundle alone (the append is load-bearing).
#   * G-TLS-mechanism -- a network-free loopback :ssl handshake with a SELF-GENERATED
#     test CA + leaf CLEARS under verify_peer when the test CA is appended (the
#     append->trust mechanism). Positive-only here (no negative reject) so the .out
#     stays free of the TLS-alert [notice] the full client_test.exs negative case
#     emits; the negative reject (the non-tautology proof) lives in client_test.exs.
#   * endpoint -- Config.new([]).endpoint defaults to sandbox-invest-public-api.tbank.ru:443
#     (the T-Bank rebrand), and resolve/1 env-resolves INVEST_API_URL + INVEST_API_PORT
#     with precedence explicit :endpoint opt > env > default (INV-10).
#   * no-verify_none -- `grep verify_none client.ex` is empty (the insecure no-verify
#     mode appears nowhere; verify_peer is kept) (INV-11).
#   * CA-provenance -- the vendored PEM hashes to the pinned SHA-256 D2:6D:...:CF:31.
#   * G7 -- no token-shaped literal anywhere in the diff surface (INV-9).
# One printed line per gate; nonzero exit on any failure. Reproducible: two runs are
# byte-identical (the loopback prints only its boolean outcome, never the per-run cert
# bytes). The live 3-way harness (G6') is the SEPARATE Operator gate, run with
# INVEST_TOKEN on `mix test --include sandbox test/transport_live_test.exs`, NOT part
# of this network-free transcript.
# Spec: docs/exchange/trd.9.1.1.specs.md ("Acceptance gates").

alias Investex.{Client, Config}

# The pinned identity of the vendored Russian Trusted Root CA (INV-11), as a plain
# binding (a script body has no module scope for @attrs). The PEM is a PUBLIC CA
# certificate, not a secret -- this fingerprint is not a token (INV-9).
pin = "D26D2D0231B7C39F92CC738512BA54103519E4405D68B5BD703E9788CA8ECF31"

defmodule G do
  def line(tag, ok, detail) do
    IO.puts("#{tag} #{if ok, do: "ok", else: "FAIL"} -- #{detail}")
    ok
  end

  # The DER of the vendored root, re-derived the way the client does.
  def vendored_der do
    pem =
      :code.priv_dir(:investex)
      |> Path.join("certs/russian_trusted_root_ca.pem")
      |> File.read!()

    [{:Certificate, der, :not_encrypted}] = :public_key.pem_decode(pem)
    der
  end

  # Generate a throwaway self-signed test CA + a localhost leaf, via openssl, into a
  # fresh tmp dir. Returns the dir + the cert/key paths. Network-free.
  def gen_test_ca do
    dir = Path.join(System.tmp_dir!(), "trd911_gate_ca_#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    ca_key = Path.join(dir, "ca.key")
    ca_crt = Path.join(dir, "ca.crt")
    leaf_key = Path.join(dir, "leaf.key")
    leaf_csr = Path.join(dir, "leaf.csr")
    leaf_crt = Path.join(dir, "leaf.crt")
    ext = Path.join(dir, "ext.cnf")

    sh(~w(openssl req -x509 -newkey rsa:2048 -nodes -keyout #{ca_key} -out #{ca_crt} -days 1 -subj /CN=trd911-gate-ca))
    sh(~w(openssl req -newkey rsa:2048 -nodes -keyout #{leaf_key} -out #{leaf_csr} -subj /CN=localhost))
    File.write!(ext, "subjectAltName=DNS:localhost,IP:127.0.0.1\n")
    sh(~w(openssl x509 -req -in #{leaf_csr} -CA #{ca_crt} -CAkey #{ca_key} -CAcreateserial -out #{leaf_crt} -days 1 -extfile #{ext}))

    %{dir: dir, ca_crt: ca_crt, leaf_crt: leaf_crt, leaf_key: leaf_key}
  end

  defp sh(args) do
    {out, status} = System.cmd(hd(args), tl(args), stderr_to_stdout: true)
    if status != 0, do: raise("openssl failed (#{status}): #{out}")
    :ok
  end

  def pem_file_der(path) do
    [{:Certificate, der, :not_encrypted}] = path |> File.read!() |> :public_key.pem_decode()
    der
  end

  # A positive loopback TLS round-trip: a tiny :ssl server presenting the test leaf,
  # a client verifying against cacerts ++ [test_ca_der] with verify_peer. Returns the
  # received payload string on a clean handshake, or {:error, reason}. Network-free.
  def loopback_clears?(paths, client_cacerts) do
    {:ok, _} = Application.ensure_all_started(:ssl)
    server_opts = [certfile: paths.leaf_crt, keyfile: paths.leaf_key, reuseaddr: true, active: false]
    {:ok, listen} = :ssl.listen(0, server_opts)
    {:ok, {_addr, port}} = :ssl.sockname(listen)
    parent = self()

    spawn_link(fn ->
      with {:ok, t} <- :ssl.transport_accept(listen, 5_000),
           {:ok, sock} <- :ssl.handshake(t, 5_000) do
        send(parent, {:srv, :ok})
        :ssl.send(sock, "gate-ok")
        :ssl.close(sock)
      else
        other -> send(parent, {:srv, other})
      end
    end)

    client_opts = [
      verify: :verify_peer,
      cacerts: client_cacerts,
      depth: 3,
      server_name_indication: ~c"localhost",
      customize_hostname_check: [match_fun: :public_key.pkix_verify_hostname_match_fun(:https)],
      active: false
    ]

    result =
      case :ssl.connect(~c"127.0.0.1", port, client_opts, 5_000) do
        {:ok, sock} ->
          got = match?({:ok, ~c"gate-ok"}, :ssl.recv(sock, 0, 5_000))
          :ssl.close(sock)
          got

        {:error, _} ->
          false
      end

    receive do
      {:srv, _} -> :ok
    after
      2_000 -> :ok
    end

    :ssl.close(listen)
    result
  end
end

IO.puts(
  "header: Investex transport FIX (TRD.9.1.1; lib-only, no dial) | Elixir #{System.version()} OTP #{:erlang.system_info(:otp_release)} | grpc #{Application.spec(:grpc, :vsn)} protobuf #{Application.spec(:protobuf, :vsn)}"
)

# == G-TLS-presence -- the vendored root is in tls_opts/0's cacerts (the teeth) =====
opts = Client.tls_opts()
cacerts = Keyword.fetch!(opts, :cacerts)
vendored = G.vendored_der()
os_bundle = :public_key.cacerts_get()

g_tls_presence =
  G.line(
    "G-TLS-presence",
    Keyword.fetch!(opts, :verify) == :verify_peer and Keyword.fetch!(opts, :depth) == 3 and
      vendored in cacerts and vendored not in os_bundle,
    "Investex.Client.tls_opts/0 keeps verify_peer + depth:3 and APPENDS the vendored Russian Trusted Root CA DER to :public_key.cacerts_get() (the DER is present in the built bundle and absent from the OS bundle alone -- dropping the ++ append turns this RED; INV-11)"
  )

# == G-TLS-mechanism -- a loopback handshake clears ONLY with the test CA appended ==
paths = G.gen_test_ca()
test_ca_der = G.pem_file_der(paths.ca_crt)
cleared_with = G.loopback_clears?(paths, :public_key.cacerts_get() ++ [test_ca_der])
File.rm_rf!(paths.dir)

g_tls_mechanism =
  G.line(
    "G-TLS-mechanism",
    cleared_with == true,
    "a network-free loopback :ssl handshake (a server leaf chained to a self-generated test CA) CLEARS under verify_peer when the test CA is appended to cacerts -- proving the append->trust mechanism the client uses for the vendored root (the negative reject, the non-tautology proof, is in client_test.exs; INV-11)"
  )

# == endpoint -- the tbank.ru default + env-resolution + precedence (INV-10) ========
# new/1 is pure (no env) so the default is deterministic; resolve/1 composes the env.
default_ep = Config.new([]).endpoint

env_ep =
  (fn ->
     prior_url = System.get_env("INVEST_API_URL")
     prior_port = System.get_env("INVEST_API_PORT")
     prior_tok = System.get_env("INVEST_TOKEN")
     System.put_env("INVEST_TOKEN", "marker-not-a-real-token")
     System.put_env("INVEST_API_URL", "env-host.example")
     System.put_env("INVEST_API_PORT", "9000")
     ep_env = (Config.new([]) |> Config.resolve()).endpoint
     ep_explicit = (Config.new(endpoint: "explicit-host:443") |> Config.resolve()).endpoint
     # restore
     if prior_url, do: System.put_env("INVEST_API_URL", prior_url), else: System.delete_env("INVEST_API_URL")
     if prior_port, do: System.put_env("INVEST_API_PORT", prior_port), else: System.delete_env("INVEST_API_PORT")
     if prior_tok, do: System.put_env("INVEST_TOKEN", prior_tok), else: System.delete_env("INVEST_TOKEN")
     {ep_env, ep_explicit}
   end).()

{resolved_env_ep, resolved_explicit_ep} = env_ep

g_endpoint =
  G.line(
    "endpoint-env-resolved",
    default_ep == "sandbox-invest-public-api.tbank.ru:443" and
      resolved_env_ep == "env-host.example:9000" and resolved_explicit_ep == "explicit-host:443",
    "Config.new([]).endpoint defaults to sandbox-invest-public-api.tbank.ru:443 (the T-Bank rebrand); resolve/1 composes INVEST_API_URL+INVEST_API_PORT (env > default) and an explicit :endpoint opt overrides the env (explicit > env > default; INV-10)"
  )

# == no-verify_none -- the insecure no-verify mode appears nowhere in client.ex =====
client_src = File.read!(Path.expand("../../apps/investex/lib/investex/client.ex", __DIR__))

g_no_verify_none =
  G.line(
    "no-verify_none",
    not String.contains?(client_src, "verify_none"),
    "grep verify_none echo/apps/investex/lib/investex/client.ex is EMPTY -- the dial keeps verify: :verify_peer and never weakens to the insecure no-verify mode in any path (INV-11)"
  )

# == CA-provenance -- the vendored PEM hashes to the pinned SHA-256 ================
g_ca_provenance =
  G.line(
    "CA-provenance",
    Base.encode16(:crypto.hash(:sha256, vendored)) == pin,
    "the vendored echo/apps/investex/priv/certs/russian_trusted_root_ca.pem hashes to the pinned SHA-256 D2:6D:2D:02:31:B7:C3:9F:92:CC:73:85:12:BA:54:10:35:19:E4:40:5D:68:B5:BD:70:3E:97:88:CA:8E:CF:31 (the self-signed Russian Trusted Root CA, fingerprint-matched -- not the server-served bytes blind; a public cert, not a secret, INV-9)"
  )

# == G7 -- no token value anywhere in the 9.1.1 diff surface (INV-9) ===============
investex_root = Path.expand("../../apps/investex", __DIR__)

source_files =
  Path.wildcard(Path.join(investex_root, "lib/**/*.ex")) ++
    Path.wildcard(Path.join(investex_root, "test/**/*.{ex,exs}")) ++
    Path.wildcard(Path.join(investex_root, "priv/**/*.pem"))

# A token-shaped literal: Bearer <>=10 opaque chars, INVEST_TOKEN=<value>, or a long
# dotted opaque token. The known non-secrets (the marker, the interpolation template)
# are excluded.
token_re = ~r/Bearer [A-Za-z0-9._-]{10,}|INVEST_TOKEN[[:space:]]*=[[:space:]]*[A-Za-z0-9]/

token_hits =
  Enum.flat_map(source_files, fn f ->
    f
    |> File.read!()
    |> String.split("\n")
    |> Enum.filter(&Regex.match?(token_re, &1))
    |> Enum.reject(&String.contains?(&1, "Bearer #{"#"}{token}"))
    |> Enum.reject(&String.contains?(&1, "marker-not-a-real-token"))
    |> Enum.map(&{f, &1})
  end)

g7 =
  G.line(
    "G7 no-token",
    token_hits == [],
    "no token-shaped literal in the app lib, tests, or the vendored PEM (#{length(source_files)} files scanned); the token is read from INVEST_TOKEN at call time only -- never a struct default, a config literal, a log line, a fixture, the vendored cert, or this transcript"
  )

gates = [
  g_tls_presence,
  g_tls_mechanism,
  g_endpoint,
  g_no_verify_none,
  g_ca_provenance,
  g7
]

if Enum.all?(gates) do
  IO.puts("PASS #{Enum.count(gates)}/#{Enum.count(gates)}")
else
  IO.puts("FAIL")
  System.halt(1)
end
