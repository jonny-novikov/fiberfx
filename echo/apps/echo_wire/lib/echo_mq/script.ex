defmodule EchoMQ.Script do
  @moduledoc """
  A server-side script with its SHA1 precomputed, so the connector can run
  EVALSHA-first with a load-on-NOSCRIPT fallback. Every key a script touches
  is declared in KEYS — the v2 law; ARGV carries values only.
  """

  defstruct [:name, :source, :sha]

  @type t :: %__MODULE__{name: atom(), source: binary(), sha: binary()}

  @spec new(atom(), binary()) :: t()
  def new(name, source) when is_atom(name) and is_binary(source) do
    sha = :crypto.hash(:sha, source) |> Base.encode16(case: :lower)
    %__MODULE__{name: name, source: source, sha: sha}
  end
end
