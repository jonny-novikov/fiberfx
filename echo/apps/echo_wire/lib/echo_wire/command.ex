defmodule EchoWire.Command do
  @moduledoc """
  The immutable command value — a faithful Elixir port of the rueidis
  `Completed` (`go/valkey-go/internal/cmds/cmds.go:117`,
  `{cs *CommandSlice; cf uint16; ks uint16}`): a command's parts, its
  bit-packed command flags, and its cluster key-slot, as pure data.

      EchoWire.Cmd.get("user:1") |> EchoWire.Cmd.build()
      # => %EchoWire.Command{parts: ["GET", "user:1"], flags: 8320, slot: 14116}

  ## What the value carries — and what reads it

  - `parts` — the flat `[binary | integer | atom]` token list, the same shape
    `EchoWire.Pipe` flushes (`pipe.ex:50`).
  - `flags` — the **full `cf` flag vocabulary** (`cmds.go:5-23`) as an integer
    bitfield mirroring the rueidis `uint16`, **with the bit-inclusion
    preserved** (a `readonly` command answers `retryable?` true, because the
    `readonly` constant *includes* `retryableTag`). The predicates read this
    bitfield by subset-match, exactly as the rueidis accessors do
    (`cmds.go:147-212`).
  - `slot` — the cluster key-slot integer `0..16_383`
    (`crc16(key | {hashtag}) & 16_383`, `slot.go:5`), or `nil` when no key is
    identifiable.

  ## The flags are STATIC per-verb, and ADVISORY this rung

  A command's flags are stamped from the **verb's static property** at build
  time (`EchoWire.Cmd` looks the verb up in a per-verb table — `GET` is
  `readonly`, `SET` is a write), **never** parsed from the assembled `parts`
  (the rueidis `Builder.<Verb>()` stamp, `gen_string.go:232`). And nothing in
  the wire reads them this rung — the flags are **advisory** (the roadmap's
  seam 4: no retry / cluster-routing / caching consumer exists yet). They are
  carried on the value for a future consumer; the proof the value is sound is
  byte-equivalence (a flagged command runs identically to the bare verb).

  ## The curated builder is never a ceiling

  Any command expressible as a `[[binary]]` list is reachable as a value via
  `raw/1` (or `raw/2` to identify the slot key) — the conservative
  write/unknown default. `EchoWire.Cmd`'s curated builders are convenience;
  `raw/1` guarantees completeness, exactly as `EchoWire.Pipe.command/2` does
  for the batch surface.
  """

  # -- the cf flag vocabulary (cmds.go:5-23, bit-inclusion preserved) ------
  #
  # Ported verbatim from the rueidis `uint16` constants, including the
  # composite bit-inclusion: `readonly` carries `retryableTag`; `noreply`
  # (rueidis `noRetTag`) carries `readonly | pipe`; `unsub` carries `noreply`.
  # The predicates below subset-match these constants (`flags &&& tag == tag`),
  # the exact rueidis accessor semantics (`cmds.go:147-212`).

  import Bitwise

  @retryable 1 <<< 7
  @pipe 1 <<< 8
  @readonly (1 <<< 13) ||| @retryable
  @noreply (1 <<< 12) ||| @readonly ||| @pipe
  @mt_get (1 <<< 11) ||| @readonly
  @scr_ro (1 <<< 10) ||| @readonly
  @unsub (1 <<< 9) ||| @noreply
  @block 1 <<< 14
  @opt_in 1 <<< 15
  @static_ttl 1 <<< 6

  # A write command leaves cf zero (rueidis `Set()` does not stamp a flag).
  @write 0

  @typedoc "The bit-packed `cf` flag set (an integer mirroring the rueidis `uint16`)."
  @type flags :: non_neg_integer()

  @typedoc "One command token (the `EchoWire.Pipe` token shape)."
  @type part :: binary() | integer() | atom()

  @type t :: %__MODULE__{
          parts: [part()],
          flags: flags(),
          slot: 0..16_383 | nil
        }

  defstruct parts: [], flags: @write, slot: nil

  # -- the flag-constant readers (so EchoWire.Cmd can stamp by name) -------

  @doc false
  def flag(:readonly), do: @readonly
  def flag(:write), do: @write
  def flag(:mt_get), do: @mt_get
  def flag(:scr_ro), do: @scr_ro
  def flag(:noreply), do: @noreply
  def flag(:unsub), do: @unsub
  def flag(:block), do: @block
  def flag(:opt_in), do: @opt_in
  def flag(:static_ttl), do: @static_ttl
  def flag(:pipe), do: @pipe
  def flag(:retryable), do: @retryable

  # -- construction --------------------------------------------------------

  @doc false
  # Build a `%Command{}` from parts, a flag set, and an explicit slot (used by
  # `EchoWire.Cmd.build/1`).
  @spec new([part()], flags(), 0..16_383 | nil) :: t()
  def new(parts, flags, slot) when is_list(parts) and is_integer(flags) do
    %__MODULE__{parts: parts, flags: flags, slot: slot}
  end

  @doc """
  Construct a command value from a raw command-list verbatim — the curated
  builder is never a ceiling. The parts are taken as given; the flags default
  to **write/unknown** (the conservative assume-mutating, non-replayable
  default); the slot is computed from the second token (the conventional key
  position) when it is a binary, else `nil`.

      EchoWire.Command.raw(["CLIENT", "INFO"])
      EchoWire.Command.raw(["GET", "user:1"])   # slot from "user:1"

  Use `raw/2` to identify the slot key explicitly for a verb whose key is not
  the second token.
  """
  @spec raw([part()]) :: t()
  def raw(parts) when is_list(parts) do
    %__MODULE__{parts: parts, flags: @write, slot: slot_of(key_from(parts))}
  end

  @doc """
  Construct a command value from a raw command-list, identifying `key` as the
  slot key — for an un-modeled verb whose key is not the second token.
  """
  @spec raw([part()], binary() | nil) :: t()
  def raw(parts, key) when is_list(parts) do
    %__MODULE__{parts: parts, flags: @write, slot: slot_of(key)}
  end

  # -- the predicates + accessors (the full cf reader set, advisory) -------
  #
  # Each predicate subset-matches the bitfield exactly as the rueidis accessor
  # does (`flags &&& tag == tag`). The bit-inclusion therefore holds for free:
  # a `readonly`-flagged command also answers `retryable?` true, because the
  # `@readonly` constant carries `@retryable`'s bit.

  @doc "Client-side-caching opt-in command (`IsOptIn()`, cmds.go:147)."
  @spec opt_in?(t()) :: boolean()
  def opt_in?(%__MODULE__{flags: f}), do: (f &&& @opt_in) == @opt_in

  @doc "A cacheable command whose reply commits directly to the cache (`IsStaticTTL()`, cmds.go:155)."
  @spec static_ttl?(t()) :: boolean()
  def static_ttl?(%__MODULE__{flags: f}), do: (f &&& @static_ttl) == @static_ttl

  @doc "A blocking command needing a dedicated connection — BLPOP/BRPOP/BLMOVE/… (`IsBlock()`, cmds.go:168)."
  @spec block?(t()) :: boolean()
  def block?(%__MODULE__{flags: f}), do: (f &&& @block) == @block

  @doc "One of SUBSCRIBE/PSUBSCRIBE/UNSUBSCRIBE/… — replies arrive out of band (`NoReply()`, cmds.go:173)."
  @spec noreply?(t()) :: boolean()
  def noreply?(%__MODULE__{flags: f}), do: (f &&& @noreply) == @noreply

  @doc "One of UNSUBSCRIBE/PUNSUBSCRIBE/SUNSUBSCRIBE (`IsUnsub()`, cmds.go:178)."
  @spec unsub?(t()) :: boolean()
  def unsub?(%__MODULE__{flags: f}), do: (f &&& @unsub) == @unsub

  @doc """
  A readonly command — retryable on a network error (`IsReadOnly()`,
  cmds.go:183). The rueidis bit-inclusion holds: a `readonly?`-true command is
  also `retryable?`-true.
  """
  @spec readonly?(t()) :: boolean()
  def readonly?(%__MODULE__{flags: f}), do: (f &&& @readonly) == @readonly

  @doc "Not a readonly command (`IsWrite()`, cmds.go:188)."
  @spec write?(t()) :: boolean()
  def write?(%__MODULE__{} = cmd), do: not readonly?(cmd)

  @doc "Prefers auto-pipelining (`IsPipe()`, cmds.go:193)."
  @spec pipe?(t()) :: boolean()
  def pipe?(%__MODULE__{flags: f}), do: (f &&& @pipe) == @pipe

  @doc "Retryable on a network error (`IsRetryable()`, cmds.go:198)."
  @spec retryable?(t()) :: boolean()
  def retryable?(%__MODULE__{flags: f}), do: (f &&& @retryable) == @retryable

  @doc "An MGET-class multi-key read (`mtGetTag`, cmds.go:10). Implies `readonly?`."
  @spec mt_get?(t()) :: boolean()
  def mt_get?(%__MODULE__{flags: f}), do: (f &&& @mt_get) == @mt_get

  @doc "A readonly script call (`scrRoTag`, cmds.go:11). Implies `readonly?`."
  @spec scr_ro?(t()) :: boolean()
  def scr_ro?(%__MODULE__{flags: f}), do: (f &&& @scr_ro) == @scr_ro

  @doc "The command's cluster key-slot integer, or `nil` (`Slot()`, cmds.go:210)."
  @spec slot(t()) :: 0..16_383 | nil
  def slot(%__MODULE__{slot: slot}), do: slot

  @doc "The raw token list a flush would carry (`Commands()`, cmds.go:205)."
  @spec parts(t()) :: [part()]
  def parts(%__MODULE__{parts: parts}), do: parts

  # -- the key-slot (slot.go) ----------------------------------------------

  @doc """
  The cluster key-slot for a key: `crc16(key) & 16_383`, or `crc16` over the
  `{hashtag}` substring when a non-empty `{...}` is present — the redis-cluster
  slot rule (`slot.go:5`). `nil` for `nil`.

  Ground vectors: `slot_of("123456789") == 12_739`;
  `slot_of("{user}:1") == slot_of("{user}:2")`.
  """
  @spec slot_of(binary() | nil) :: 0..16_383 | nil
  def slot_of(nil), do: nil

  def slot_of(key) when is_binary(key) do
    crc16(hashtag(key)) &&& 16_383
  end

  # The `{hashtag}` rule: if the key has a `{`, then a `}` after it with at
  # least one char between, hash only that inner substring; else hash the whole
  # key (slot.go:5-24).
  defp hashtag(key) do
    case :binary.match(key, "{") do
      :nomatch ->
        key

      {open, 1} ->
        rest_from = open + 1
        rest = binary_part(key, rest_from, byte_size(key) - rest_from)

        case :binary.match(rest, "}") do
          :nomatch -> key
          {0, 1} -> key
          {close, 1} -> binary_part(rest, 0, close)
        end
    end
  end

  # The conventional key position for `raw/1`: the second token when binary.
  defp key_from([_verb, key | _]) when is_binary(key), do: key
  defp key_from(_), do: nil

  # CRC16-CCITT (XMODEM) — the redis-cluster standard (slot.go:54-109).
  # Output for "123456789" is 0x31C3.
  @crc16tab {0x0000, 0x1021, 0x2042, 0x3063, 0x4084, 0x50A5, 0x60C6, 0x70E7,
             0x8108, 0x9129, 0xA14A, 0xB16B, 0xC18C, 0xD1AD, 0xE1CE, 0xF1EF,
             0x1231, 0x0210, 0x3273, 0x2252, 0x52B5, 0x4294, 0x72F7, 0x62D6,
             0x9339, 0x8318, 0xB37B, 0xA35A, 0xD3BD, 0xC39C, 0xF3FF, 0xE3DE,
             0x2462, 0x3443, 0x0420, 0x1401, 0x64E6, 0x74C7, 0x44A4, 0x5485,
             0xA56A, 0xB54B, 0x8528, 0x9509, 0xE5EE, 0xF5CF, 0xC5AC, 0xD58D,
             0x3653, 0x2672, 0x1611, 0x0630, 0x76D7, 0x66F6, 0x5695, 0x46B4,
             0xB75B, 0xA77A, 0x9719, 0x8738, 0xF7DF, 0xE7FE, 0xD79D, 0xC7BC,
             0x48C4, 0x58E5, 0x6886, 0x78A7, 0x0840, 0x1861, 0x2802, 0x3823,
             0xC9CC, 0xD9ED, 0xE98E, 0xF9AF, 0x8948, 0x9969, 0xA90A, 0xB92B,
             0x5AF5, 0x4AD4, 0x7AB7, 0x6A96, 0x1A71, 0x0A50, 0x3A33, 0x2A12,
             0xDBFD, 0xCBDC, 0xFBBF, 0xEB9E, 0x9B79, 0x8B58, 0xBB3B, 0xAB1A,
             0x6CA6, 0x7C87, 0x4CE4, 0x5CC5, 0x2C22, 0x3C03, 0x0C60, 0x1C41,
             0xEDAE, 0xFD8F, 0xCDEC, 0xDDCD, 0xAD2A, 0xBD0B, 0x8D68, 0x9D49,
             0x7E97, 0x6EB6, 0x5ED5, 0x4EF4, 0x3E13, 0x2E32, 0x1E51, 0x0E70,
             0xFF9F, 0xEFBE, 0xDFDD, 0xCFFC, 0xBF1B, 0xAF3A, 0x9F59, 0x8F78,
             0x9188, 0x81A9, 0xB1CA, 0xA1EB, 0xD10C, 0xC12D, 0xF14E, 0xE16F,
             0x1080, 0x00A1, 0x30C2, 0x20E3, 0x5004, 0x4025, 0x7046, 0x6067,
             0x83B9, 0x9398, 0xA3FB, 0xB3DA, 0xC33D, 0xD31C, 0xE37F, 0xF35E,
             0x02B1, 0x1290, 0x22F3, 0x32D2, 0x4235, 0x5214, 0x6277, 0x7256,
             0xB5EA, 0xA5CB, 0x95A8, 0x8589, 0xF56E, 0xE54F, 0xD52C, 0xC50D,
             0x34E2, 0x24C3, 0x14A0, 0x0481, 0x7466, 0x6447, 0x5424, 0x4405,
             0xA7DB, 0xB7FA, 0x8799, 0x97B8, 0xE75F, 0xF77E, 0xC71D, 0xD73C,
             0x26D3, 0x36F2, 0x0691, 0x16B0, 0x6657, 0x7676, 0x4615, 0x5634,
             0xD94C, 0xC96D, 0xF90E, 0xE92F, 0x99C8, 0x89E9, 0xB98A, 0xA9AB,
             0x5844, 0x4865, 0x7806, 0x6827, 0x18C0, 0x08E1, 0x3882, 0x28A3,
             0xCB7D, 0xDB5C, 0xEB3F, 0xFB1E, 0x8BF9, 0x9BD8, 0xABBB, 0xBB9A,
             0x4A75, 0x5A54, 0x6A37, 0x7A16, 0x0AF1, 0x1AD0, 0x2AB3, 0x3A92,
             0xFD2E, 0xED0F, 0xDD6C, 0xCD4D, 0xBDAA, 0xAD8B, 0x9DE8, 0x8DC9,
             0x7C26, 0x6C07, 0x5C64, 0x4C45, 0x3CA2, 0x2C83, 0x1CE0, 0x0CC1,
             0xEF1F, 0xFF3E, 0xCF5D, 0xDF7C, 0xAF9B, 0xBFBA, 0x8FD9, 0x9FF8,
             0x6E17, 0x7E36, 0x4E55, 0x5E74, 0x2E93, 0x3EB2, 0x0ED1, 0x1EF0}

  defp crc16(key) do
    key
    |> :binary.bin_to_list()
    |> Enum.reduce(0, fn byte, crc ->
      idx = bxor(crc >>> 8, byte) &&& 0x00FF
      bxor((crc <<< 8) &&& 0xFFFF, elem(@crc16tab, idx))
    end)
  end
end
