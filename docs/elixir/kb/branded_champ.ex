defmodule EchoData.BrandedChamp do
  @moduledoc """
  CHAMP HashMap optimized for branded IDs.

  Branded IDs follow the format: `{NAMESPACE}{BASE62}` (3 + 11 = 14 chars)
  Examples: `PLR7FXC4K8M9N2P`, `ROM3QR5T7V9W2X4`, `SES0K48QjihpC4`

  This implementation uses namespace-based partitioning for O(1) access by type,
  with CHAMP tries for the Base62 portion within each namespace.

  ## Features

  - Namespace partitioning (PLR, ROM, ADM, etc.) for efficient type queries
  - Immutable, persistent data structure (structural sharing)
  - O(log32 n) ≈ O(1) lookup, insert, delete within namespace
  - Implements Access protocol for `champ[id]` syntax
  - Implements Enumerable for iteration

  ## Usage

      # Create a new CHAMP
      champ = BrandedChamp.new()

      # Insert entries
      champ = BrandedChamp.put(champ, "PLR7FXC4K8M9N2P", %{name: "Alice"})
      champ = BrandedChamp.put(champ, "ROM3QR5T7V9W2X4", %{code: "XYZZY"})

      # Lookup
      {:ok, player} = BrandedChamp.fetch(champ, "PLR7FXC4K8M9N2P")
      player = BrandedChamp.get(champ, "PLR7FXC4K8M9N2P")

      # Access protocol
      player = champ["PLR7FXC4K8M9N2P"]

      # Get all entries for a namespace
      players = BrandedChamp.get_namespace(champ, "PLR")

      # Delete
      champ = BrandedChamp.delete(champ, "PLR7FXC4K8M9N2P")

      # Size and iteration
      count = BrandedChamp.size(champ)
      entries = BrandedChamp.to_list(champ)

  ## Performance

  - `fetch/2`: O(1) namespace + O(log32 n) trie lookup
  - `put/3`: O(1) namespace + O(log32 n) trie insert
  - `delete/2`: O(1) namespace + O(log32 n) trie delete
  - `get_namespace/2`: O(1) lookup + O(m) iteration within namespace
  - `namespace_size/2`: O(1) - cached per-namespace counts
  - `size/1`: O(1) - cached total count
  """

  alias EchoData.{ChampNode, Base62}

  # 14 bytes = 112 bits
  @type branded_id :: <<_::112>>
  # 3 bytes = 24 bits
  @type namespace :: <<_::24>>
  @type snowflake :: non_neg_integer()
  @type value :: any()

  @type t :: %__MODULE__{
          namespaces: %{optional(namespace()) => ChampNode.t()},
          namespace_sizes: %{optional(namespace()) => non_neg_integer()},
          size: non_neg_integer()
        }

  defstruct namespaces: %{}, namespace_sizes: %{}, size: 0

  @behaviour Access

  @doc """
  Creates a new empty BrandedChamp.
  """
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc """
  Creates a BrandedChamp from a list of `{id, value}` pairs.
  """
  @spec new([{branded_id(), value()}]) :: t()
  def new(entries) when is_list(entries) do
    Enum.reduce(entries, new(), fn {id, value}, acc ->
      put(acc, id, value)
    end)
  end

  @doc """
  Fetches the value for a branded ID.

  Returns `{:ok, value}` if found, `:error` otherwise.
  This also serves as the Access protocol callback.
  """
  @impl Access
  @spec fetch(t(), branded_id()) :: {:ok, value()} | :error
  def fetch(%__MODULE__{namespaces: namespaces}, id) when is_binary(id) and byte_size(id) == 14 do
    <<ns::binary-size(3), base62::binary-size(11)>> = id

    case Base62.decode(base62) do
      {:ok, snowflake} ->
        case Map.fetch(namespaces, ns) do
          {:ok, node} ->
            hash = compute_hash_int(snowflake)
            ChampNode.fetch(node, snowflake, hash, 0)

          :error ->
            :error
        end

      :error ->
        :error
    end
  end

  def fetch(_champ, _id), do: :error

  @doc """
  Gets the value for a branded ID, returning `default` if not found.
  """
  @spec get(t(), branded_id(), value()) :: value()
  def get(champ, id, default \\ nil) do
    case fetch(champ, id) do
      {:ok, value} -> value
      :error -> default
    end
  end

  @doc """
  Inserts or updates a branded ID with the given value.

  Returns a new BrandedChamp with the entry added/updated.
  """
  @spec put(t(), branded_id(), value()) :: t()
  def put(%__MODULE__{namespaces: namespaces, namespace_sizes: ns_sizes, size: size} = champ, id, value)
      when byte_size(id) == 14 do
    <<ns::binary-size(3), base62::binary-size(11)>> = id

    case Base62.decode(base62) do
      {:ok, snowflake} ->
        hash = compute_hash_int(snowflake)

        {new_node, size_delta} =
          case Map.fetch(namespaces, ns) do
            {:ok, node} ->
              # Check if updating or inserting
              existing = ChampNode.fetch(node, snowflake, hash, 0)
              delta = if existing == :error, do: 1, else: 0
              {ChampNode.put(node, snowflake, value, hash, 0), delta}

            :error ->
              {ChampNode.singleton(snowflake, value, hash, 0), 1}
          end

        new_namespaces = Map.put(namespaces, ns, new_node)
        new_ns_sizes = Map.update(ns_sizes, ns, size_delta, &(&1 + size_delta))
        %__MODULE__{champ | namespaces: new_namespaces, namespace_sizes: new_ns_sizes, size: size + size_delta}

      :error ->
        # Invalid base62 - return unchanged
        champ
    end
  end

  @doc """
  Deletes a branded ID from the CHAMP.

  Returns a new BrandedChamp without the entry.
  """
  @spec delete(t(), branded_id()) :: t()
  def delete(%__MODULE__{namespaces: namespaces, namespace_sizes: ns_sizes, size: size} = champ, id)
      when byte_size(id) == 14 do
    <<ns::binary-size(3), base62::binary-size(11)>> = id

    case Base62.decode(base62) do
      {:ok, snowflake} ->
        case Map.fetch(namespaces, ns) do
          {:ok, node} ->
            hash = compute_hash_int(snowflake)

            # Check if key exists before deleting
            case ChampNode.fetch(node, snowflake, hash, 0) do
              {:ok, _} ->
                new_node = ChampNode.delete(node, snowflake, hash, 0)
                new_ns_size = Map.get(ns_sizes, ns, 1) - 1

                {new_namespaces, new_ns_sizes} =
                  if new_ns_size == 0 do
                    {Map.delete(namespaces, ns), Map.delete(ns_sizes, ns)}
                  else
                    {Map.put(namespaces, ns, new_node), Map.put(ns_sizes, ns, new_ns_size)}
                  end

                %__MODULE__{champ | namespaces: new_namespaces, namespace_sizes: new_ns_sizes, size: size - 1}

              :error ->
                champ
            end

          :error ->
            champ
        end

      :error ->
        # Invalid base62 - return unchanged
        champ
    end
  end

  @doc """
  Checks if a branded ID exists in the CHAMP.
  """
  @spec has_key?(t(), branded_id()) :: boolean()
  def has_key?(champ, id) do
    fetch(champ, id) != :error
  end

  @doc """
  Returns the total number of entries in the CHAMP.
  """
  @spec size(t()) :: non_neg_integer()
  def size(%__MODULE__{size: size}), do: size

  @doc """
  Checks if the CHAMP is empty.
  """
  @spec empty?(t()) :: boolean()
  def empty?(%__MODULE__{size: 0}), do: true
  def empty?(_), do: false

  @doc """
  Returns all entries for a specific namespace.

  Useful for queries like "get all players" or "get all rooms".
  """
  @spec get_namespace(t(), namespace()) :: [{branded_id(), value()}]
  def get_namespace(%__MODULE__{namespaces: namespaces}, ns) when byte_size(ns) == 3 do
    case Map.fetch(namespaces, ns) do
      {:ok, node} ->
        node
        |> ChampNode.to_list()
        |> Enum.map(fn {snowflake, value} -> {ns <> Base62.encode(snowflake), value} end)

      :error ->
        []
    end
  end

  @doc """
  Returns the count of entries for a specific namespace.

  This is O(1) as namespace sizes are cached.
  """
  @spec namespace_size(t(), namespace()) :: non_neg_integer()
  def namespace_size(%__MODULE__{namespace_sizes: ns_sizes}, ns) when byte_size(ns) == 3 do
    Map.get(ns_sizes, ns, 0)
  end

  @doc """
  Returns all namespaces that have entries.
  """
  @spec namespaces(t()) :: [namespace()]
  def namespaces(%__MODULE__{namespaces: namespaces}) do
    Map.keys(namespaces)
  end

  @doc """
  Converts the CHAMP to a list of `{id, value}` pairs.
  """
  @spec to_list(t()) :: [{branded_id(), value()}]
  def to_list(%__MODULE__{namespaces: namespaces}) do
    Enum.flat_map(namespaces, fn {ns, node} ->
      node
      |> ChampNode.to_list()
      |> Enum.map(fn {snowflake, value} -> {ns <> Base62.encode(snowflake), value} end)
    end)
  end

  @doc """
  Converts the CHAMP to a regular Map.
  """
  @spec to_map(t()) :: %{optional(branded_id()) => value()}
  def to_map(champ) do
    champ
    |> to_list()
    |> Map.new()
  end

  @doc """
  Returns all keys in the CHAMP.
  """
  @spec keys(t()) :: [branded_id()]
  def keys(champ) do
    champ
    |> to_list()
    |> Enum.map(fn {k, _v} -> k end)
  end

  @doc """
  Returns all values in the CHAMP.
  """
  @spec values(t()) :: [value()]
  def values(champ) do
    champ
    |> to_list()
    |> Enum.map(fn {_k, v} -> v end)
  end

  @doc """
  Merges two BrandedChamps. Values from `champ2` take precedence.
  """
  @spec merge(t(), t()) :: t()
  def merge(champ1, champ2) do
    champ2
    |> to_list()
    |> Enum.reduce(champ1, fn {id, value}, acc ->
      put(acc, id, value)
    end)
  end

  @doc """
  Updates a value using a function.

  If the key exists, calls `fun` with the current value.
  If the key doesn't exist, inserts `default`.
  """
  @spec update(t(), branded_id(), value(), (value() -> value())) :: t()
  def update(champ, id, default, fun) when is_function(fun, 1) do
    case fetch(champ, id) do
      {:ok, value} -> put(champ, id, fun.(value))
      :error -> put(champ, id, default)
    end
  end

  @doc """
  Filters entries based on a predicate function.
  """
  @spec filter(t(), ({branded_id(), value()} -> boolean())) :: t()
  def filter(champ, fun) when is_function(fun, 1) do
    champ
    |> to_list()
    |> Enum.filter(fun)
    |> new()
  end

  @doc """
  Maps values using a function.
  """
  @spec map_values(t(), (value() -> value())) :: t()
  def map_values(champ, fun) when is_function(fun, 1) do
    champ
    |> to_list()
    |> Enum.map(fn {k, v} -> {k, fun.(v)} end)
    |> new()
  end

  # ===========================================================================
  # DIRECT SNOWFLAKE OPERATIONS
  # ===========================================================================

  @doc """
  Fetches a value by namespace and snowflake.

  More efficient than `fetch/2` when you already have the snowflake,
  as it skips ID validation overhead.

  ## Examples

      iex> {:ok, player} = BrandedChamp.fetch_by_snowflake(champ, "PLR", 12345678901234)
      iex> BrandedChamp.fetch_by_snowflake(champ, "PLR", 99999)
      :error

  """
  @spec fetch_by_snowflake(t(), namespace(), snowflake()) :: {:ok, value()} | :error
  def fetch_by_snowflake(%__MODULE__{namespaces: namespaces}, ns, snowflake)
      when is_binary(ns) and byte_size(ns) == 3 and is_integer(snowflake) and snowflake >= 0 do
    case Map.fetch(namespaces, ns) do
      {:ok, node} ->
        hash = compute_hash_int(snowflake)
        ChampNode.fetch(node, snowflake, hash, 0)

      :error ->
        :error
    end
  end

  @doc """
  Gets a value by namespace and snowflake, returning `default` if not found.
  """
  @spec get_by_snowflake(t(), namespace(), snowflake(), value()) :: value()
  def get_by_snowflake(champ, ns, snowflake, default \\ nil) do
    case fetch_by_snowflake(champ, ns, snowflake) do
      {:ok, value} -> value
      :error -> default
    end
  end

  @doc """
  Inserts or updates a value by namespace and snowflake.

  Returns a new BrandedChamp with the entry added/updated.

  ## Examples

      iex> champ = BrandedChamp.put_by_snowflake(champ, "PLR", 12345678901234, %Player{})

  """
  @spec put_by_snowflake(t(), namespace(), snowflake(), value()) :: t()
  def put_by_snowflake(%__MODULE__{namespaces: namespaces, namespace_sizes: ns_sizes, size: size} = champ, ns, snowflake, value)
      when is_binary(ns) and byte_size(ns) == 3 and is_integer(snowflake) and snowflake >= 0 do
    hash = compute_hash_int(snowflake)

    {new_node, size_delta} =
      case Map.fetch(namespaces, ns) do
        {:ok, node} ->
          existing = ChampNode.fetch(node, snowflake, hash, 0)
          delta = if existing == :error, do: 1, else: 0
          {ChampNode.put(node, snowflake, value, hash, 0), delta}

        :error ->
          {ChampNode.singleton(snowflake, value, hash, 0), 1}
      end

    new_namespaces = Map.put(namespaces, ns, new_node)
    new_ns_sizes = Map.update(ns_sizes, ns, size_delta, &(&1 + size_delta))
    %__MODULE__{champ | namespaces: new_namespaces, namespace_sizes: new_ns_sizes, size: size + size_delta}
  end

  @doc """
  Deletes an entry by namespace and snowflake.

  Returns a new BrandedChamp without the entry.
  """
  @spec delete_by_snowflake(t(), namespace(), snowflake()) :: t()
  def delete_by_snowflake(%__MODULE__{namespaces: namespaces, namespace_sizes: ns_sizes, size: size} = champ, ns, snowflake)
      when is_binary(ns) and byte_size(ns) == 3 and is_integer(snowflake) and snowflake >= 0 do
    case Map.fetch(namespaces, ns) do
      {:ok, node} ->
        hash = compute_hash_int(snowflake)

        case ChampNode.fetch(node, snowflake, hash, 0) do
          {:ok, _} ->
            new_node = ChampNode.delete(node, snowflake, hash, 0)
            new_ns_size = Map.get(ns_sizes, ns, 1) - 1

            {new_namespaces, new_ns_sizes} =
              if new_ns_size == 0 do
                {Map.delete(namespaces, ns), Map.delete(ns_sizes, ns)}
              else
                {Map.put(namespaces, ns, new_node), Map.put(ns_sizes, ns, new_ns_size)}
              end

            %__MODULE__{champ | namespaces: new_namespaces, namespace_sizes: new_ns_sizes, size: size - 1}

          :error ->
            champ
        end

      :error ->
        champ
    end
  end

  @doc """
  Checks if a snowflake exists in a namespace.
  """
  @spec has_key_by_snowflake?(t(), namespace(), snowflake()) :: boolean()
  def has_key_by_snowflake?(champ, ns, snowflake) do
    fetch_by_snowflake(champ, ns, snowflake) != :error
  end

  # ===========================================================================
  # SNOWFLAKE ENCODING/DECODING UTILITIES
  # ===========================================================================

  @doc """
  Extracts the snowflake integer from a branded ID.

  ## Examples

      iex> BrandedChamp.extract_snowflake("PLR0K48QjihpC4")
      {:ok, 12345678901234}

      iex> BrandedChamp.extract_snowflake("PLR0K48Q")
      :error

  """
  @spec extract_snowflake(branded_id()) :: {:ok, snowflake()} | :error
  def extract_snowflake(id) when is_binary(id) and byte_size(id) == 14 do
    <<_ns::binary-size(3), base62::binary-size(11)>> = id
    Base62.decode(base62)
  end

  def extract_snowflake(_), do: :error

  @doc """
  Parses a branded ID into namespace and snowflake components.

  ## Examples

      iex> BrandedChamp.parse_branded_id("PLR0K48QjihpC4")
      {:ok, "PLR", 12345678901234}

      iex> BrandedChamp.parse_branded_id("invalid")
      :error

  """
  @spec parse_branded_id(branded_id()) :: {:ok, namespace(), snowflake()} | :error
  def parse_branded_id(id) when is_binary(id) and byte_size(id) == 14 do
    <<ns::binary-size(3), base62::binary-size(11)>> = id

    case Base62.decode(base62) do
      {:ok, snowflake} -> {:ok, ns, snowflake}
      :error -> :error
    end
  end

  def parse_branded_id(_), do: :error

  @doc """
  Builds a branded ID from namespace and snowflake.

  ## Examples

      iex> BrandedChamp.build_branded_id("PLR", 12345678901234)
      "PLR0K48QjihpC4"

  """
  @spec build_branded_id(namespace(), snowflake()) :: branded_id()
  def build_branded_id(ns, snowflake)
      when is_binary(ns) and byte_size(ns) == 3 and is_integer(snowflake) and snowflake >= 0 do
    ns <> Base62.encode(snowflake)
  end

  # Access protocol implementation
  # Note: fetch/2 is defined above with @impl Access

  @impl Access
  def get_and_update(champ, id, fun) do
    current = get(champ, id)

    case fun.(current) do
      {get_value, update_value} ->
        {get_value, put(champ, id, update_value)}

      :pop ->
        {current, delete(champ, id)}
    end
  end

  @impl Access
  def pop(champ, id) do
    case fetch(champ, id) do
      {:ok, value} -> {value, delete(champ, id)}
      :error -> {nil, champ}
    end
  end

  # Private functions

  import Bitwise

  # Integer hash using splitmix64 algorithm (matches Go implementation)
  defp compute_hash_int(key) when is_integer(key) and key >= 0 do
    h = band(key, 0xFFFFFFFFFFFFFFFF)
    h = bxor(h, bsr(h, 33))
    h = band(h * 0xFF51AFD7ED558CCD, 0xFFFFFFFFFFFFFFFF)
    h = bxor(h, bsr(h, 33))
    band(h, 0xFFFFFFFF)
  end
end

# Enumerable protocol implementation
defimpl Enumerable, for: EchoData.BrandedChamp do
  def count(champ) do
    {:ok, EchoData.BrandedChamp.size(champ)}
  end

  def member?(champ, {key, value}) do
    case EchoData.BrandedChamp.fetch(champ, key) do
      {:ok, ^value} -> {:ok, true}
      _ -> {:ok, false}
    end
  end

  def member?(_champ, _element) do
    {:ok, false}
  end

  def slice(_champ) do
    {:error, __MODULE__}
  end

  def reduce(champ, acc, fun) do
    Enumerable.List.reduce(EchoData.BrandedChamp.to_list(champ), acc, fun)
  end
end

# Collectable protocol implementation
defimpl Collectable, for: EchoData.BrandedChamp do
  def into(champ) do
    collector_fun = fn
      acc, {:cont, {key, value}} ->
        EchoData.BrandedChamp.put(acc, key, value)

      acc, :done ->
        acc

      _acc, :halt ->
        :ok
    end

    {champ, collector_fun}
  end
end

# Inspect protocol implementation
defimpl Inspect, for: EchoData.BrandedChamp do
  import Inspect.Algebra

  def inspect(champ, opts) do
    size = EchoData.BrandedChamp.size(champ)
    namespaces = EchoData.BrandedChamp.namespaces(champ)

    concat([
      "#BrandedChamp<",
      "size: #{size}, ",
      "namespaces: ",
      to_doc(namespaces, opts),
      ">"
    ])
  end
end
