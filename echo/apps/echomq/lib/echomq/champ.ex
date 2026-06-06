defmodule EchoMQ.Champ do
  @moduledoc """
  Branded message types for cross-runtime EchoMQ communication.

  CHAMP = Channel Message Protocol

  This module provides branded ID types and message envelopes for traceable
  communication between Elixir (Phoenix) and Node.js (EchoMQ workers).

  Built on top of `EchoData.Snowflake` and `EchoData.Base62` for shared
  ID generation and encoding.

  ## Branded ID Format

  All IDs follow the format: `{NS}{BASE62}` = 3 + 11 = 14 characters

  - **Namespace (NS)**: 3 uppercase ASCII characters identifying the entity type
  - **Base62**: 11-character encoding of a 64-bit snowflake

  ## Namespaces

  | NS  | Entity       | Description                          |
  |-----|--------------|--------------------------------------|
  | JOB | Job          | Individual job in a queue            |
  | EVT | Event        | Queue event (completed, failed, etc) |
  | FLW | Flow         | Parent-child flow                    |
  | QUE | Queue        | Queue identifier                     |
  | WRK | Worker       | Worker instance                      |
  | TRC | Trace        | Distributed trace span               |

  ## Split Topology

  The split topology places writes where workers process and reads where consumers serve:

  ```
  ┌─────────────────────────────────────────────────────────────────┐
  │                    SPLIT TOPOLOGY                                │
  ├─────────────────────────────────────────────────────────────────┤
  │                                                                  │
  │  CHAMP/PRIMARY (Redis Machine)           PHOENIX/REPLICA        │
  │  ═══════════════════════════             ═══════════════        │
  │                                                                  │
  │  ┌─────────────────────────┐    repl    ┌─────────────────────┐ │
  │  │  Node.js EchoMQ Worker  │───────────>│  Elixir QueueEvents │ │
  │  │                         │  <1ms      │                     │ │
  │  │  WRITES job results     │            │  READS via Streams  │ │
  │  └─────────────────────────┘            └─────────────────────┘ │
  │           │                                      │               │
  │           │ localhost:6379                       │ .internal     │
  │           ▼                                      ▼               │
  │  ┌─────────────────────────────────────────────────────────────┐│
  │  │                         Redis                               ││
  │  │  bull:{queue}:* (jobs)    bull:{queue}:events (streams)     ││
  │  └─────────────────────────────────────────────────────────────┘│
  └─────────────────────────────────────────────────────────────────┘
  ```

  ## Usage

      # Generate branded IDs
      job_id = EchoMQ.Champ.generate_id(:job)
      # => "JOB0K48QjihpC4"

      # Create a message envelope
      msg = EchoMQ.Champ.envelope(:job_completed, %{result: "ok"}, job_id)
      # => %{id: "EVT0K48Qx...", type: :job_completed, payload: ..., trace_context: ...}

      # Parse a branded ID
      {:ok, :job, snowflake} = EchoMQ.Champ.parse("JOB0K48QjihpC4")

      # Extract timestamp from any branded ID
      datetime = EchoMQ.Champ.timestamp("JOB0K48QjihpC4")

  ## W3C Trace Context

  All message envelopes include W3C Trace Context fields for distributed tracing:

      %{
        trace_context: %{
          trace_id: "abc123...",     # 32 hex chars
          span_id: "def456...",       # 16 hex chars
          trace_flags: 1              # Sampling flags
        }
      }

  This enables seamless trace stitching across Elixir → Redis → Node.js → Redis → Elixir.
  """

  alias EchoData.{Snowflake, Base62}

  # ===========================================================================
  # CONSTANTS
  # ===========================================================================

  # Namespace definitions
  @namespaces %{
    job: "JOB",
    event: "EVT",
    flow: "FLW",
    queue: "QUE",
    worker: "WRK",
    trace: "TRC"
  }

  @namespace_atoms Map.new(@namespaces, fn {k, v} -> {v, k} end)

  # ===========================================================================
  # TYPES
  # ===========================================================================

  @typedoc "Branded ID: 14 characters = {NS}{BASE62}"
  @type branded_id :: <<_::112>>

  @typedoc "Namespace: 3 uppercase ASCII characters"
  @type namespace :: <<_::24>>

  @typedoc "Namespace atom"
  @type namespace_atom :: :job | :event | :flow | :queue | :worker | :trace

  @typedoc "Snowflake: 64-bit integer with embedded timestamp"
  @type snowflake :: non_neg_integer()

  @typedoc "Job ID with JOB namespace"
  @type job_id :: branded_id()

  @typedoc "Event ID with EVT namespace"
  @type event_id :: branded_id()

  @typedoc "Flow ID with FLW namespace"
  @type flow_id :: branded_id()

  @typedoc "Queue ID with QUE namespace"
  @type queue_id :: branded_id()

  @typedoc "Worker ID with WRK namespace"
  @type worker_id :: branded_id()

  @typedoc "Trace ID with TRC namespace"
  @type trace_id :: branded_id()

  @typedoc """
  Message type for queue events.

  Maps to EchoMQ event lifecycle:
  - `:job_created` - Job added to queue
  - `:job_active` - Worker picked up job
  - `:job_progress` - Job reported progress
  - `:job_completed` - Job finished successfully
  - `:job_failed` - Job errored
  - `:job_stalled` - Worker died during processing
  - `:job_delayed` - Job moved to delayed queue
  - `:job_retrying` - Job being retried
  - `:flow_started` - Parent-child flow initiated
  - `:flow_child_completed` - Child job in flow completed
  - `:state_transition` - Game state machine transition
  """
  @type message_type ::
          :job_created
          | :job_active
          | :job_progress
          | :job_completed
          | :job_failed
          | :job_stalled
          | :job_delayed
          | :job_retrying
          | :flow_started
          | :flow_child_completed
          | :state_transition

  @typedoc """
  W3C Trace Context for distributed tracing.

  See: https://www.w3.org/TR/trace-context/
  """
  @type trace_context :: %{
          trace_id: String.t(),
          span_id: String.t(),
          trace_flags: non_neg_integer()
        }

  @typedoc """
  Message envelope for cross-runtime communication.

  All fields are JSON-serializable for Redis transport.
  """
  @type champ_message :: %{
          required(:id) => event_id(),
          required(:type) => message_type(),
          required(:payload) => map(),
          required(:timestamp) => non_neg_integer(),
          optional(:ref_id) => branded_id(),
          optional(:trace_context) => trace_context(),
          optional(:source) => :elixir | :nodejs,
          optional(:queue) => String.t()
        }

  @typedoc "Snowflake components after extraction"
  @type snowflake_components :: %{
          timestamp: DateTime.t(),
          timestamp_ms: non_neg_integer(),
          worker_id: non_neg_integer(),
          sequence: non_neg_integer()
        }

  # ===========================================================================
  # ID GENERATION
  # ===========================================================================

  @doc """
  Generates a new branded ID for the given namespace.

  Uses the current timestamp, a worker ID derived from the node/PID,
  and an atomic sequence counter.

  ## Examples

      iex> EchoMQ.Champ.generate_id(:job)
      "JOB0K48QjihpC4"

      iex> EchoMQ.Champ.generate_id(:event)
      "EVT0K48Qxyz123"

  """
  @spec generate_id(namespace_atom()) :: branded_id()
  def generate_id(ns_atom) when is_map_key(@namespaces, ns_atom) do
    ns = Map.fetch!(@namespaces, ns_atom)
    snowflake = generate_snowflake()
    ns <> encode_base62(snowflake)
  end

  @doc """
  Generates a branded ID with a specific snowflake value.

  Useful for testing or when you need deterministic IDs.

  ## Examples

      iex> EchoMQ.Champ.build_id(:job, 12345678901234)
      "JOB0K48QjihpC4"

  """
  @spec build_id(namespace_atom(), snowflake()) :: branded_id()
  def build_id(ns_atom, snowflake)
      when is_map_key(@namespaces, ns_atom) and is_integer(snowflake) and snowflake >= 0 do
    ns = Map.fetch!(@namespaces, ns_atom)
    ns <> encode_base62(snowflake)
  end

  # ===========================================================================
  # ID PARSING
  # ===========================================================================

  @doc """
  Parses a branded ID into its components.

  Returns `{:ok, namespace_atom, snowflake}` on success, `:error` on failure.

  ## Examples

      iex> EchoMQ.Champ.parse("JOB0K48QjihpC4")
      {:ok, :job, 12345678901234}

      iex> EchoMQ.Champ.parse("invalid")
      :error

  """
  @spec parse(branded_id()) :: {:ok, namespace_atom(), snowflake()} | :error
  def parse(id) when is_binary(id) and byte_size(id) == 14 do
    <<ns::binary-size(3), base62::binary-size(11)>> = id

    with {:ok, ns_atom} <- Map.fetch(@namespace_atoms, ns),
         {:ok, snowflake} <- decode_base62(base62) do
      {:ok, ns_atom, snowflake}
    else
      _ -> :error
    end
  end

  def parse(_), do: :error

  @doc """
  Validates that a string is a valid branded ID.

  ## Examples

      iex> EchoMQ.Champ.valid?("JOB0K48QjihpC4")
      true

      iex> EchoMQ.Champ.valid?("invalid")
      false

  """
  @spec valid?(term()) :: boolean()
  def valid?(id), do: parse(id) != :error

  @doc """
  Extracts the namespace atom from a branded ID.

  ## Examples

      iex> EchoMQ.Champ.namespace("JOB0K48QjihpC4")
      {:ok, :job}

  """
  @spec namespace(branded_id()) :: {:ok, namespace_atom()} | :error
  def namespace(id) when is_binary(id) and byte_size(id) == 14 do
    <<ns::binary-size(3), _::binary>> = id
    Map.fetch(@namespace_atoms, ns)
  end

  def namespace(_), do: :error

  @doc """
  Extracts the timestamp from a branded ID as a DateTime.

  ## Examples

      iex> EchoMQ.Champ.timestamp("JOB0K48QjihpC4")
      ~U[2024-01-15 12:30:45.123Z]

  """
  @spec timestamp(branded_id()) :: DateTime.t() | nil
  def timestamp(id) when is_binary(id) and byte_size(id) == 14 do
    case parse(id) do
      {:ok, _ns, snowflake} ->
        extract_timestamp(snowflake)

      :error ->
        nil
    end
  end

  def timestamp(_), do: nil

  @doc """
  Extracts all snowflake components from a branded ID.

  ## Examples

      iex> EchoMQ.Champ.extract("JOB0K48QjihpC4")
      {:ok, %{timestamp: ~U[...], timestamp_ms: ..., worker_id: ..., sequence: ...}}

  """
  @spec extract(branded_id()) :: {:ok, snowflake_components()} | :error
  def extract(id) when is_binary(id) and byte_size(id) == 14 do
    case parse(id) do
      {:ok, _ns, snowflake} ->
        {:ok, extract_snowflake(snowflake)}

      :error ->
        :error
    end
  end

  def extract(_), do: :error

  # ===========================================================================
  # MESSAGE ENVELOPES
  # ===========================================================================

  @doc """
  Creates a message envelope for cross-runtime communication.

  ## Parameters

  - `type` - Message type (`:job_completed`, `:job_failed`, etc.)
  - `payload` - Message payload (must be JSON-serializable)
  - `ref_id` - Optional reference ID (e.g., the job ID this event relates to)
  - `opts` - Additional options:
    - `:trace_context` - W3C Trace Context (auto-generated if not provided)
    - `:source` - Source runtime (`:elixir` or `:nodejs`)
    - `:queue` - Queue name

  ## Examples

      iex> EchoMQ.Champ.envelope(:job_completed, %{result: "ok"}, "JOB0K48QjihpC4")
      %{
        id: "EVT0K48Xyz...",
        type: :job_completed,
        payload: %{result: "ok"},
        ref_id: "JOB0K48QjihpC4",
        timestamp: 1704067200123,
        trace_context: %{trace_id: "...", span_id: "...", trace_flags: 1},
        source: :elixir
      }

  """
  @spec envelope(message_type(), map(), branded_id() | nil, keyword()) :: champ_message()
  def envelope(type, payload, ref_id \\ nil, opts \\ []) do
    event_id = generate_id(:event)
    timestamp = System.system_time(:millisecond)

    base = %{
      id: event_id,
      type: type,
      payload: payload,
      timestamp: timestamp,
      source: :elixir
    }

    base
    |> maybe_add(:ref_id, ref_id)
    |> maybe_add(:trace_context, opts[:trace_context] || generate_trace_context())
    |> maybe_add(:queue, opts[:queue])
  end

  @doc """
  Generates a W3C Trace Context.

  ## Examples

      iex> EchoMQ.Champ.generate_trace_context()
      %{trace_id: "abc123...", span_id: "def456...", trace_flags: 1}

  """
  @spec generate_trace_context() :: trace_context()
  def generate_trace_context do
    %{
      trace_id: random_hex(32),
      span_id: random_hex(16),
      trace_flags: 1
    }
  end

  @doc """
  Creates a child trace context from a parent.

  Preserves the trace_id and generates a new span_id.

  ## Examples

      iex> parent = %{trace_id: "abc123", span_id: "def456", trace_flags: 1}
      iex> EchoMQ.Champ.child_trace_context(parent)
      %{trace_id: "abc123", span_id: "xyz789...", trace_flags: 1}

  """
  @spec child_trace_context(trace_context()) :: trace_context()
  def child_trace_context(%{trace_id: trace_id, trace_flags: flags}) do
    %{
      trace_id: trace_id,
      span_id: random_hex(16),
      trace_flags: flags
    }
  end

  @doc """
  Formats trace context as a W3C traceparent header value.

  Format: `{version}-{trace_id}-{span_id}-{trace_flags}`

  ## Examples

      iex> ctx = %{trace_id: "abc123...", span_id: "def456...", trace_flags: 1}
      iex> EchoMQ.Champ.format_traceparent(ctx)
      "00-abc123...-def456...-01"

  """
  @spec format_traceparent(trace_context()) :: String.t()
  def format_traceparent(%{trace_id: trace_id, span_id: span_id, trace_flags: flags}) do
    flags_hex = flags |> Integer.to_string(16) |> String.pad_leading(2, "0")
    "00-#{trace_id}-#{span_id}-#{flags_hex}"
  end

  @doc """
  Parses a W3C traceparent header value into a trace context.

  ## Examples

      iex> EchoMQ.Champ.parse_traceparent("00-abc123...-def456...-01")
      {:ok, %{trace_id: "abc123...", span_id: "def456...", trace_flags: 1}}

  """
  @spec parse_traceparent(String.t()) :: {:ok, trace_context()} | :error
  def parse_traceparent(traceparent) when is_binary(traceparent) do
    case String.split(traceparent, "-") do
      ["00", trace_id, span_id, flags_hex] when byte_size(trace_id) == 32 and byte_size(span_id) == 16 ->
        case Integer.parse(flags_hex, 16) do
          {flags, ""} ->
            {:ok, %{trace_id: trace_id, span_id: span_id, trace_flags: flags}}

          _ ->
            :error
        end

      _ ->
        :error
    end
  end

  def parse_traceparent(_), do: :error

  # ===========================================================================
  # JSON SERIALIZATION
  # ===========================================================================

  @doc """
  Encodes a message envelope to JSON for Redis transport.

  ## Examples

      iex> msg = EchoMQ.Champ.envelope(:job_completed, %{result: "ok"})
      iex> EchoMQ.Champ.to_json(msg)
      "{\"id\":\"EVT0K48...\",\"type\":\"job_completed\",...}"

  """
  @spec to_json(champ_message()) :: String.t()
  def to_json(message) do
    message
    |> Map.update!(:type, &Atom.to_string/1)
    |> Map.update(:source, nil, fn
      nil -> nil
      atom -> Atom.to_string(atom)
    end)
    |> Jason.encode!()
  end

  @doc """
  Decodes a JSON string into a message envelope.

  ## Examples

      iex> json = "{\"id\":\"EVT0K48...\",\"type\":\"job_completed\",...}"
      iex> EchoMQ.Champ.from_json(json)
      {:ok, %{id: "EVT0K48...", type: :job_completed, ...}}

  """
  @spec from_json(String.t()) :: {:ok, champ_message()} | {:error, term()}
  def from_json(json) when is_binary(json) do
    case Jason.decode(json) do
      {:ok, data} ->
        message = %{
          id: data["id"],
          type: String.to_existing_atom(data["type"]),
          payload: data["payload"],
          timestamp: data["timestamp"]
        }

        message =
          message
          |> maybe_add(:ref_id, data["ref_id"])
          |> maybe_add(:queue, data["queue"])
          |> maybe_add(:source, data["source"] && String.to_existing_atom(data["source"]))

        message =
          if data["trace_context"] do
            tc = data["trace_context"]

            Map.put(message, :trace_context, %{
              trace_id: tc["trace_id"],
              span_id: tc["span_id"],
              trace_flags: tc["trace_flags"]
            })
          else
            message
          end

        {:ok, message}

      {:error, reason} ->
        {:error, reason}
    end
  rescue
    ArgumentError -> {:error, :invalid_atom}
  end

  # ===========================================================================
  # NAMESPACE HELPERS
  # ===========================================================================

  @doc """
  Returns all defined namespaces.

  ## Examples

      iex> EchoMQ.Champ.namespaces()
      [:job, :event, :flow, :queue, :worker, :trace]

  """
  @spec namespaces() :: [namespace_atom()]
  def namespaces, do: Map.keys(@namespaces)

  @doc """
  Returns the string prefix for a namespace atom.

  ## Examples

      iex> EchoMQ.Champ.namespace_prefix(:job)
      "JOB"

  """
  @spec namespace_prefix(namespace_atom()) :: namespace()
  def namespace_prefix(ns_atom) when is_map_key(@namespaces, ns_atom) do
    Map.fetch!(@namespaces, ns_atom)
  end

  # ===========================================================================
  # PRIVATE FUNCTIONS
  # ===========================================================================

  # Generate a snowflake using EchoData.Snowflake
  defp generate_snowflake do
    Snowflake.generate()
  end

  # Extract timestamp from snowflake using EchoData.Snowflake
  defp extract_timestamp(snowflake) do
    Snowflake.timestamp(snowflake)
  end

  # Extract all components from snowflake using EchoData.Snowflake
  defp extract_snowflake(snowflake) do
    Snowflake.extract(snowflake)
  end

  # Base62 encoding using EchoData.Base62
  defp encode_base62(n) when is_integer(n) and n >= 0 do
    Base62.encode(n)
  end

  # Base62 decoding using EchoData.Base62
  defp decode_base62(str) when is_binary(str) do
    Base62.decode(str)
  end

  # Generate random hex string
  defp random_hex(length) do
    :crypto.strong_rand_bytes(div(length, 2))
    |> Base.encode16(case: :lower)
  end

  # Conditionally add a key to a map
  defp maybe_add(map, _key, nil), do: map
  defp maybe_add(map, key, value), do: Map.put(map, key, value)
end
