defmodule EchoData.Snowflake do
  @moduledoc """
  Snowflake ID utilities for branded ID systems.

  Snowflakes are 64-bit integers that encode:
  - Timestamp (42 bits) - milliseconds since epoch
  - Worker ID (10 bits) - machine/process identifier
  - Sequence (12 bits) - counter within same millisecond

  ## Bit Layout

      Snowflake (64 bits):
      ├─ Bits 63-22: Timestamp (milliseconds since epoch) - 42 bits
      ├─ Bits 21-12: Worker/Machine ID - 10 bits
      └─ Bits 11-0:  Sequence number - 12 bits

  ## Epoch

  Uses custom epoch: 2024-01-01 00:00:00 UTC (1704067200000 ms)

  This gives us ~139 years of headroom before timestamp overflow.

  ## Examples

      # Extract all components
      components = EchoData.Snowflake.extract(12345678901234)
      # => %{timestamp: ~U[...], timestamp_ms: ..., worker_id: ..., sequence: ...}

      # Extract just the timestamp
      datetime = EchoData.Snowflake.timestamp(12345678901234)

      # Build a snowflake
      snowflake = EchoData.Snowflake.build(~U[2024-06-15 12:30:00Z], 1, 0)

      # Generate a new snowflake
      snowflake = EchoData.Snowflake.generate(worker_id: 1)

      # Compare chronologically
      :lt = EchoData.Snowflake.compare(older_snowflake, newer_snowflake)

  """

  import Bitwise

  # Custom epoch: 2024-01-01 00:00:00 UTC
  @epoch 1_704_067_200_000

  # Bit widths
  @timestamp_bits 42
  @worker_bits 10
  @sequence_bits 12

  # Bit shifts
  @timestamp_shift @worker_bits + @sequence_bits  # 22
  @worker_shift @sequence_bits                     # 12

  # Bit masks
  @worker_mask (1 <<< @worker_bits) - 1            # 0x3FF (1023)
  @sequence_mask (1 <<< @sequence_bits) - 1        # 0xFFF (4095)
  @timestamp_mask (1 <<< @timestamp_bits) - 1      # Max timestamp value

  @type snowflake :: non_neg_integer()
  @type components :: %{
          timestamp: DateTime.t(),
          timestamp_ms: non_neg_integer(),
          worker_id: non_neg_integer(),
          sequence: non_neg_integer()
        }

  @doc """
  Returns the custom epoch used for snowflake timestamps.

  The epoch is 2024-01-01 00:00:00 UTC (1704067200000 milliseconds since Unix epoch).
  """
  @spec epoch() :: non_neg_integer()
  def epoch, do: @epoch

  @doc """
  Returns the bit layout constants.
  """
  @spec bit_layout() :: map()
  def bit_layout do
    %{
      timestamp_bits: @timestamp_bits,
      worker_bits: @worker_bits,
      sequence_bits: @sequence_bits,
      timestamp_shift: @timestamp_shift,
      worker_shift: @worker_shift,
      worker_mask: @worker_mask,
      sequence_mask: @sequence_mask
    }
  end

  @doc """
  Generates a new snowflake with the current timestamp.

  ## Options

  - `:worker_id` - Worker/machine identifier (0-1023, default: derived from PID)
  - `:sequence` - Sequence number (0-4095, default: auto-increment)

  ## Examples

      iex> EchoData.Snowflake.generate()
      123456789012345

      iex> EchoData.Snowflake.generate(worker_id: 42)
      123456789054321

  """
  @spec generate(keyword()) :: snowflake()
  def generate(opts \\ []) do
    timestamp_offset = System.system_time(:millisecond) - @epoch
    worker_id = Keyword.get(opts, :worker_id, default_worker_id())
    sequence = Keyword.get(opts, :sequence, get_and_increment_sequence())

    bsl(timestamp_offset, @timestamp_shift)
    |> bor(bsl(band(worker_id, @worker_mask), @worker_shift))
    |> bor(band(sequence, @sequence_mask))
  end

  @doc """
  Extracts all components from a snowflake.

  Returns a map with:
  - `timestamp` - DateTime of creation
  - `timestamp_ms` - Unix timestamp in milliseconds
  - `worker_id` - Worker/machine identifier (0-1023)
  - `sequence` - Sequence number within millisecond (0-4095)

  ## Examples

      iex> EchoData.Snowflake.extract(12345678901234)
      %{
        timestamp: ~U[2024-01-01 00:00:02.939Z],
        timestamp_ms: 1704067202939,
        worker_id: 878,
        sequence: 2674
      }

  """
  @spec extract(snowflake()) :: components()
  def extract(snowflake) when is_integer(snowflake) and snowflake >= 0 do
    timestamp_offset = bsr(snowflake, @timestamp_shift)
    timestamp_ms = timestamp_offset + @epoch
    worker_id = band(bsr(snowflake, @worker_shift), @worker_mask)
    sequence = band(snowflake, @sequence_mask)

    %{
      timestamp: DateTime.from_unix!(timestamp_ms, :millisecond),
      timestamp_ms: timestamp_ms,
      worker_id: worker_id,
      sequence: sequence
    }
  end

  @doc """
  Extracts the timestamp from a snowflake as a DateTime.

  ## Examples

      iex> EchoData.Snowflake.timestamp(12345678901234)
      ~U[2024-01-01 00:00:02.939Z]

  """
  @spec timestamp(snowflake()) :: DateTime.t()
  def timestamp(snowflake) when is_integer(snowflake) and snowflake >= 0 do
    timestamp_offset = bsr(snowflake, @timestamp_shift)
    timestamp_ms = timestamp_offset + @epoch
    DateTime.from_unix!(timestamp_ms, :millisecond)
  end

  @doc """
  Extracts the raw timestamp offset from a snowflake (milliseconds since custom epoch).

  Useful for comparing snowflakes without the overhead of DateTime conversion.
  """
  @spec timestamp_offset(snowflake()) :: non_neg_integer()
  def timestamp_offset(snowflake) when is_integer(snowflake) and snowflake >= 0 do
    bsr(snowflake, @timestamp_shift)
  end

  @doc """
  Extracts the worker ID from a snowflake.

  Worker IDs are in the range 0-1023 (10 bits).
  """
  @spec worker_id(snowflake()) :: non_neg_integer()
  def worker_id(snowflake) when is_integer(snowflake) and snowflake >= 0 do
    band(bsr(snowflake, @worker_shift), @worker_mask)
  end

  @doc """
  Extracts the sequence number from a snowflake.

  Sequence numbers are in the range 0-4095 (12 bits).
  """
  @spec sequence(snowflake()) :: non_neg_integer()
  def sequence(snowflake) when is_integer(snowflake) and snowflake >= 0 do
    band(snowflake, @sequence_mask)
  end

  @doc """
  Builds a snowflake from components.

  ## Parameters

  - `datetime` - The timestamp as a DateTime
  - `worker_id` - Worker identifier (0-1023)
  - `sequence` - Sequence number (0-4095)

  ## Examples

      iex> EchoData.Snowflake.build(~U[2024-06-15 12:30:00Z], 1, 0)
      59961619456000

  """
  @spec build(DateTime.t(), non_neg_integer(), non_neg_integer()) :: snowflake()
  def build(%DateTime{} = datetime, worker_id, sequence)
      when is_integer(worker_id) and worker_id >= 0 and worker_id <= @worker_mask and
             is_integer(sequence) and sequence >= 0 and sequence <= @sequence_mask do
    timestamp_ms = DateTime.to_unix(datetime, :millisecond)
    timestamp_offset = timestamp_ms - @epoch

    if timestamp_offset < 0 do
      raise ArgumentError, "datetime must be after epoch (2024-01-01 00:00:00 UTC)"
    end

    if timestamp_offset > @timestamp_mask do
      raise ArgumentError, "datetime too far in the future (exceeds 42-bit timestamp)"
    end

    bsl(timestamp_offset, @timestamp_shift)
    |> bor(bsl(worker_id, @worker_shift))
    |> bor(sequence)
  end

  @doc """
  Builds a snowflake from a Unix timestamp in milliseconds.

  ## Examples

      iex> EchoData.Snowflake.build_from_ms(1718451000000, 1, 0)
      59961619456000

  """
  @spec build_from_ms(non_neg_integer(), non_neg_integer(), non_neg_integer()) :: snowflake()
  def build_from_ms(timestamp_ms, worker_id, sequence)
      when is_integer(timestamp_ms) and timestamp_ms >= @epoch and
             is_integer(worker_id) and worker_id >= 0 and worker_id <= @worker_mask and
             is_integer(sequence) and sequence >= 0 and sequence <= @sequence_mask do
    timestamp_offset = timestamp_ms - @epoch

    bsl(timestamp_offset, @timestamp_shift)
    |> bor(bsl(worker_id, @worker_shift))
    |> bor(sequence)
  end

  @doc """
  Compares two snowflakes chronologically.

  Returns `:lt`, `:eq`, or `:gt`.

  First compares by timestamp, then by full snowflake value if timestamps are equal.

  ## Examples

      iex> EchoData.Snowflake.compare(older, newer)
      :lt

  """
  @spec compare(snowflake(), snowflake()) :: :lt | :eq | :gt
  def compare(a, b) when is_integer(a) and is_integer(b) and a >= 0 and b >= 0 do
    ts_a = bsr(a, @timestamp_shift)
    ts_b = bsr(b, @timestamp_shift)

    cond do
      ts_a < ts_b -> :lt
      ts_a > ts_b -> :gt
      a < b -> :lt
      a > b -> :gt
      true -> :eq
    end
  end

  @doc """
  Checks if a snowflake falls within a time range.

  Both bounds are inclusive.

  ## Examples

      iex> start_time = ~U[2024-06-15 00:00:00Z]
      iex> end_time = ~U[2024-06-15 23:59:59Z]
      iex> EchoData.Snowflake.in_range?(snowflake, start_time, end_time)
      true

  """
  @spec in_range?(snowflake(), DateTime.t(), DateTime.t()) :: boolean()
  def in_range?(snowflake, %DateTime{} = start_time, %DateTime{} = end_time)
      when is_integer(snowflake) and snowflake >= 0 do
    ts = timestamp(snowflake)
    DateTime.compare(ts, start_time) in [:eq, :gt] and DateTime.compare(ts, end_time) in [:eq, :lt]
  end

  @doc """
  Returns the minimum possible snowflake for a given DateTime.

  Useful for range queries - all snowflakes created at or after this time
  will be >= the returned value.
  """
  @spec min_for_time(DateTime.t()) :: snowflake()
  def min_for_time(%DateTime{} = datetime) do
    build(datetime, 0, 0)
  end

  @doc """
  Returns the maximum possible snowflake for a given DateTime.

  Useful for range queries - all snowflakes created at or before this time
  will be <= the returned value.
  """
  @spec max_for_time(DateTime.t()) :: snowflake()
  def max_for_time(%DateTime{} = datetime) do
    build(datetime, @worker_mask, @sequence_mask)
  end

  @doc """
  Validates that a value is a valid snowflake.

  Returns `{:ok, snowflake}` if valid, `{:error, reason}` otherwise.
  """
  @spec validate(term()) :: {:ok, snowflake()} | {:error, String.t()}
  def validate(value) when is_integer(value) and value >= 0 do
    timestamp_offset = bsr(value, @timestamp_shift)

    cond do
      timestamp_offset > @timestamp_mask ->
        {:error, "timestamp exceeds maximum value"}

      true ->
        {:ok, value}
    end
  end

  def validate(value) when is_integer(value) do
    {:error, "snowflake must be non-negative"}
  end

  def validate(_value) do
    {:error, "snowflake must be an integer"}
  end

  # Private functions

  defp default_worker_id do
    :erlang.phash2(self(), @worker_mask + 1)
  end

  defp get_and_increment_sequence do
    seq = Process.get(:echo_data_snowflake_sequence, 0)
    next_seq = band(seq + 1, @sequence_mask)
    Process.put(:echo_data_snowflake_sequence, next_seq)
    seq
  end
end
