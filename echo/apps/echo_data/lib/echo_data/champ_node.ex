defmodule EchoData.ChampNode do
  @moduledoc """
  Internal node structure for CHAMP (Compressed Hash-Array Mapped Prefix-trie).

  A CHAMP node uses two 32-bit bitmaps to achieve compression:
  - `datamap`: Indicates which hash positions contain inline key-value pairs
  - `nodemap`: Indicates which hash positions contain child nodes

  The actual data/children are stored in a compact array, indexed by
  popcount of the bitmap prefix up to the target bit.

  ## Bit Layout

  - 5 bits per level (32-way branching)
  - Max 7 levels for 32-bit hash before collision handling
  - Hash fragment at level N: `band(bsr(hash, 5 * N), 0x1F)`

  ## Node Structure

      %ChampNode{
        datamap: 0b00010100,  # entries at positions 2 and 4
        nodemap: 0b00001000,  # child node at position 3
        content: [k1, v1, k2, v2, child_node]  # compact array
      }

  The content array contains:
  1. Inline key-value pairs (for datamap bits), interleaved: [k, v, k, v, ...]
  2. Child nodes (for nodemap bits)

  Entries come before child nodes in the content array.

  ## Performance

  - O(log32 n) ≈ O(1) for lookup, insert, delete
  - Structural sharing enables efficient immutable updates
  - Compact memory layout due to bitmap compression
  """

  import Bitwise

  @type key :: binary() | integer()
  @type value :: any()
  @type hash :: non_neg_integer()

  @type t :: %__MODULE__{
          datamap: non_neg_integer(),
          nodemap: non_neg_integer(),
          content: tuple()
        }

  defstruct datamap: 0, nodemap: 0, content: {}

  # 5 bits per level = 32 positions
  @hash_bits 5
  @hash_mask (1 <<< @hash_bits) - 1

  @doc """
  Creates a new empty node.
  """
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc """
  Creates a leaf node with a single key-value pair.
  """
  @spec singleton(key(), value(), hash(), non_neg_integer()) :: t()
  def singleton(key, value, hash, level) do
    frag = hash_fragment(hash, level)
    bit = 1 <<< frag

    %__MODULE__{
      datamap: bit,
      nodemap: 0,
      content: {key, value}
    }
  end

  @doc """
  Looks up a key in the node, returning `{:ok, value}` or `:error`.
  """
  @spec fetch(t(), key(), hash(), non_neg_integer()) :: {:ok, value()} | :error
  def fetch(%__MODULE__{datamap: 0, nodemap: 0, content: content}, key, _hash, _level) do
    # Handle collision node or empty node
    case content do
      {{:collision, pairs}} ->
        case List.keyfind(pairs, key, 0) do
          {^key, value} -> {:ok, value}
          nil -> :error
        end

      {} ->
        :error
    end
  end

  def fetch(%__MODULE__{datamap: datamap, nodemap: nodemap, content: content}, key, hash, level) do
    frag = hash_fragment(hash, level)
    bit = 1 <<< frag

    cond do
      # Key-value pair at this position
      (datamap &&& bit) != 0 ->
        idx = data_index(datamap, bit)
        stored_key = elem(content, idx * 2)

        if stored_key == key do
          {:ok, elem(content, idx * 2 + 1)}
        else
          :error
        end

      # Child node at this position
      (nodemap &&& bit) != 0 ->
        child_idx = node_index(datamap, nodemap, bit)
        child = elem(content, child_idx)
        fetch(child, key, hash, level + 1)

      # Nothing at this position
      true ->
        :error
    end
  end

  @doc """
  Inserts or updates a key-value pair, returning the new node.
  """
  @spec put(t(), key(), value(), hash(), non_neg_integer()) :: t()
  def put(
        %__MODULE__{datamap: 0, nodemap: 0, content: {{:collision, pairs}}},
        key,
        value,
        _hash,
        _level
      ) do
    # Handle collision node - update or append to pairs list
    new_pairs =
      case List.keyfind(pairs, key, 0) do
        nil -> [{key, value} | pairs]
        _ -> List.keyreplace(pairs, key, 0, {key, value})
      end

    %__MODULE__{datamap: 0, nodemap: 0, content: {{:collision, new_pairs}}}
  end

  def put(
        %__MODULE__{datamap: datamap, nodemap: nodemap, content: content} = node,
        key,
        value,
        hash,
        level
      ) do
    frag = hash_fragment(hash, level)
    bit = 1 <<< frag

    cond do
      # Empty slot - insert inline
      (datamap &&& bit) == 0 and (nodemap &&& bit) == 0 ->
        idx = data_index(datamap, bit)
        new_content = tuple_insert_at(content, idx * 2, key, value)

        %__MODULE__{node | datamap: datamap ||| bit, content: new_content}

      # Existing key-value at this position
      (datamap &&& bit) != 0 ->
        idx = data_index(datamap, bit)
        stored_key = elem(content, idx * 2)

        if stored_key == key do
          # Update existing key
          new_content = put_elem(content, idx * 2 + 1, value)
          %__MODULE__{node | content: new_content}
        else
          # Hash collision at this level - create child node
          stored_value = elem(content, idx * 2 + 1)
          stored_hash = compute_hash(stored_key)

          child =
            merge_into_node(stored_key, stored_value, stored_hash, key, value, hash, level + 1)

          # Remove inline entry, add child node at correct position
          new_datamap = bxor(datamap, bit)
          new_nodemap = nodemap ||| bit

          # Calculate insertion position for the new child node
          # Child nodes are stored after inline entries, ordered by their bit position
          data_count_after = popcount(new_datamap)
          node_offset = popcount(nodemap &&& bit - 1)
          child_insert_pos = data_count_after * 2 + node_offset

          new_content =
            content
            |> tuple_delete_at(idx * 2, 2)
            |> tuple_insert_child_at(child_insert_pos, child)

          %__MODULE__{node | datamap: new_datamap, nodemap: new_nodemap, content: new_content}
        end

      # Child node at this position - recurse
      (nodemap &&& bit) != 0 ->
        child_idx = node_index(datamap, nodemap, bit)
        child = elem(content, child_idx)
        new_child = put(child, key, value, hash, level + 1)
        new_content = put_elem(content, child_idx, new_child)

        %__MODULE__{node | content: new_content}
    end
  end

  @doc """
  Deletes a key from the node, returning the new node.
  Returns the original node if key not found.
  """
  @spec delete(t(), key(), hash(), non_neg_integer()) :: t()
  def delete(
        %__MODULE__{datamap: 0, nodemap: 0, content: {{:collision, pairs}}} = node,
        key,
        _hash,
        _level
      ) do
    # Handle collision node - remove from pairs list
    case List.keydelete(pairs, key, 0) do
      ^pairs ->
        # Key not found
        node

      [] ->
        # Empty collision node
        %__MODULE__{datamap: 0, nodemap: 0, content: {}}

      [{remaining_key, remaining_value}] ->
        # Single entry left - this should be handled by collapse_if_needed
        %__MODULE__{
          datamap: 0,
          nodemap: 0,
          content: {{:collision, [{remaining_key, remaining_value}]}}
        }

      new_pairs ->
        %__MODULE__{datamap: 0, nodemap: 0, content: {{:collision, new_pairs}}}
    end
  end

  def delete(
        %__MODULE__{datamap: datamap, nodemap: nodemap, content: content} = node,
        key,
        hash,
        level
      ) do
    frag = hash_fragment(hash, level)
    bit = 1 <<< frag

    cond do
      # Key-value at this position
      (datamap &&& bit) != 0 ->
        idx = data_index(datamap, bit)
        stored_key = elem(content, idx * 2)

        if stored_key == key do
          new_content = tuple_delete_at(content, idx * 2, 2)
          new_datamap = bxor(datamap, bit)

          %__MODULE__{node | datamap: new_datamap, content: new_content}
        else
          # Key not found
          node
        end

      # Child node at this position
      (nodemap &&& bit) != 0 ->
        child_idx = node_index(datamap, nodemap, bit)
        child = elem(content, child_idx)
        new_child = delete(child, key, hash, level + 1)

        case collapse_if_needed(new_child) do
          {:collapse, k, v} ->
            # Child collapsed to single entry - inline it
            new_content =
              content
              |> tuple_delete_at(child_idx, 1)
              |> tuple_insert_at(data_index(datamap, bit) * 2, k, v)

            new_datamap = datamap ||| bit
            new_nodemap = bxor(nodemap, bit)

            %__MODULE__{node | datamap: new_datamap, nodemap: new_nodemap, content: new_content}

          :keep ->
            new_content = put_elem(content, child_idx, new_child)
            %__MODULE__{node | content: new_content}
        end

      # Nothing at this position
      true ->
        node
    end
  end

  @doc """
  Counts the number of entries in this node and all children.
  """
  @spec size(t()) :: non_neg_integer()
  def size(%__MODULE__{datamap: 0, nodemap: 0, content: content}) do
    # Handle collision node or empty node
    case content do
      {{:collision, pairs}} -> length(pairs)
      {} -> 0
    end
  end

  def size(%__MODULE__{datamap: datamap, nodemap: nodemap, content: content}) do
    data_count = popcount(datamap)
    node_count = popcount(nodemap)

    # Count entries in child nodes
    child_sizes =
      if node_count > 0 do
        Enum.reduce(0..(node_count - 1), 0, fn i, acc ->
          child_idx = data_count * 2 + i
          child = elem(content, child_idx)
          acc + size(child)
        end)
      else
        0
      end

    data_count + child_sizes
  end

  @doc """
  Converts the node to a list of {key, value} pairs.
  """
  @spec to_list(t()) :: [{key(), value()}]
  def to_list(%__MODULE__{datamap: 0, nodemap: 0, content: content}) do
    # Handle collision node or empty node
    case content do
      {{:collision, pairs}} -> pairs
      {} -> []
    end
  end

  def to_list(%__MODULE__{datamap: datamap, nodemap: nodemap, content: content}) do
    data_count = popcount(datamap)
    node_count = popcount(nodemap)

    # Collect inline entries
    inline_entries =
      if data_count > 0 do
        Enum.map(0..(data_count - 1), fn i ->
          key = elem(content, i * 2)
          value = elem(content, i * 2 + 1)
          {key, value}
        end)
      else
        []
      end

    # Collect entries from child nodes
    child_entries =
      if node_count > 0 do
        Enum.reduce(0..(node_count - 1), [], fn i, acc ->
          child_idx = data_count * 2 + i
          child = elem(content, child_idx)
          acc ++ to_list(child)
        end)
      else
        []
      end

    inline_entries ++ child_entries
  end

  # Private functions

  defp hash_fragment(hash, level) do
    hash >>> (@hash_bits * level) &&& @hash_mask
  end

  defp data_index(datamap, bit) do
    popcount(datamap &&& bit - 1)
  end

  defp node_index(datamap, nodemap, bit) do
    data_count = popcount(datamap)
    node_offset = popcount(nodemap &&& bit - 1)
    data_count * 2 + node_offset
  end

  defp popcount(n) when n >= 0 do
    do_popcount(n, 0)
  end

  defp do_popcount(0, acc), do: acc
  defp do_popcount(n, acc), do: do_popcount(n &&& n - 1, acc + 1)

  defp compute_hash(key) when is_binary(key) do
    :erlang.phash2(key, 0xFFFFFFFF)
  end

  # Integer hash using splitmix64 algorithm (matches Go implementation)
  defp compute_hash(key) when is_integer(key) and key >= 0 do
    h = band(key, 0xFFFFFFFFFFFFFFFF)
    h = bxor(h, bsr(h, 33))
    h = band(h * 0xFF51AFD7ED558CCD, 0xFFFFFFFFFFFFFFFF)
    h = bxor(h, bsr(h, 33))
    band(h, 0xFFFFFFFF)
  end

  defp merge_into_node(key1, value1, hash1, key2, value2, hash2, level) when level < 7 do
    frag1 = hash_fragment(hash1, level)
    frag2 = hash_fragment(hash2, level)

    if frag1 == frag2 do
      # Same fragment - need to go deeper
      child = merge_into_node(key1, value1, hash1, key2, value2, hash2, level + 1)
      bit = 1 <<< frag1

      %__MODULE__{
        datamap: 0,
        nodemap: bit,
        content: {child}
      }
    else
      # Different fragments - can store both inline
      bit1 = 1 <<< frag1
      bit2 = 1 <<< frag2

      if frag1 < frag2 do
        %__MODULE__{
          datamap: bit1 ||| bit2,
          nodemap: 0,
          content: {key1, value1, key2, value2}
        }
      else
        %__MODULE__{
          datamap: bit1 ||| bit2,
          nodemap: 0,
          content: {key2, value2, key1, value1}
        }
      end
    end
  end

  # Collision node at max depth - store as list
  defp merge_into_node(key1, value1, _hash1, key2, value2, _hash2, _level) do
    %__MODULE__{
      datamap: 0,
      nodemap: 0,
      content: {{:collision, [{key1, value1}, {key2, value2}]}}
    }
  end

  defp collapse_if_needed(%__MODULE__{datamap: 0, nodemap: 0, content: {{:collision, [{k, v}]}}}) do
    # Collision node with single entry - collapse
    {:collapse, k, v}
  end

  defp collapse_if_needed(%__MODULE__{datamap: 0, nodemap: 0, content: {}}) do
    # Empty node - can be collapsed (caller should handle)
    :keep
  end

  defp collapse_if_needed(%__MODULE__{datamap: datamap, nodemap: 0, content: content}) do
    if popcount(datamap) == 1 do
      {:collapse, elem(content, 0), elem(content, 1)}
    else
      :keep
    end
  end

  defp collapse_if_needed(_node), do: :keep

  # Tuple manipulation helpers

  defp tuple_insert_at(tuple, index, key, value) do
    list = Tuple.to_list(tuple)
    {before, after_list} = Enum.split(list, index)
    List.to_tuple(before ++ [key, value] ++ after_list)
  end

  defp tuple_delete_at(tuple, index, count) do
    list = Tuple.to_list(tuple)
    {before, rest} = Enum.split(list, index)
    {_deleted, after_list} = Enum.split(rest, count)
    List.to_tuple(before ++ after_list)
  end

  defp tuple_insert_child_at(tuple, index, child) do
    list = Tuple.to_list(tuple)
    {before, after_list} = Enum.split(list, index)
    List.to_tuple(before ++ [child] ++ after_list)
  end
end
