defmodule Portal.ID do
  @moduledoc """
  Branded Snowflake ids — a 3-letter uppercase namespace + Base62(snowflake).

  The integer snowflake is the **canonical** id; the branded string is its
  **transport** form (e.g. `"ENR0KHTOWnGLuC"`). This is a thin wrapper over the
  `:echo_data` primitives: `EchoData.Snowflake` (time-ordered 64-bit ints) and
  `EchoData.Base62` (the `0-9A-Za-z`, width-11 encoding). Pure except the clock
  and the per-process sequence inside `EchoData.Snowflake`.
  """

  # Fixed node/worker id for F5 (single node); F6.8 derives it per machine.
  @node 1

  @typedoc "A branded id: 3-letter namespace followed by an 11-char Base62 snowflake."
  @type t :: String.t()

  @doc "Mints a fresh branded id for the 3-letter uppercase `namespace`."
  @spec new(binary()) :: t()
  def new(<<_::binary-size(3)>> = namespace) do
    namespace <> EchoData.Base62.encode(EchoData.Snowflake.generate(worker_id: @node))
  end

  @doc "Decodes a branded id back to its canonical integer snowflake."
  @spec snowflake(t()) :: non_neg_integer()
  def snowflake(<<_namespace::binary-size(3), encoded::binary>>) do
    EchoData.Base62.decode!(encoded)
  end

  @doc "Returns the 3-letter namespace prefix of a branded id."
  @spec namespace(t()) :: binary()
  def namespace(<<namespace::binary-size(3), _::binary>>), do: namespace

  @doc "Returns the UTC `DateTime` a branded id was minted at."
  @spec at(t()) :: DateTime.t()
  def at(branded_id) when is_binary(branded_id) do
    EchoData.Snowflake.timestamp(snowflake(branded_id))
  end

  @doc ~S'''
  True only for a well-formed branded id: a 3-letter uppercase namespace followed
  by an 11-character Base62 snowflake (14 bytes total). Placeholders like `"USR1"`
  are **not** valid — a branded id always carries a full encoded snowflake.
  '''
  @spec valid?(term()) :: boolean()
  def valid?(<<ns::binary-size(3), encoded::binary-size(11)>>) do
    uppercase_namespace?(ns) and EchoData.Base62.valid?(encoded)
  end

  def valid?(_), do: false

  defp uppercase_namespace?(<<a, b, c>>) do
    a in ?A..?Z and b in ?A..?Z and c in ?A..?Z
  end
end
