# 05 — Stories (sharable cards)

The story cards are the image payload of the [Sharing surface](04-sections.md#sharing) — six designed variants (`v1..v6`), each authored as a Russian master `COMPONENT` and surfaced as an English `INSTANCE` (with one English variant authored as a stand-alone `FRAME` rather than an instance). They are designed to be embedded in Telegram messages a player sends from the sharing surface and rendered as a recipient-facing first impression of the game.

These screens carry **no** game-system state on their own — they are post-game flourishes and referral collateral, not a live channel surface. The system data they reference (a player's nickname, a winning score, a multiplier) is composed onto the card client-side from `PLR` props the sharing surface already has; the bus / `cm.notify` lane is **not** involved (that lane is system → player only, see [notifications.md](../../../echo/apps/codemojex/docs/notifications.md)).

The pairing is one master component per variant + one English instance (or frame). The instances inherit layout + tokens from the masters; localize text by overriding the slot on the instance, not by forking the master.

### Framing — these are brand cards, not win templates

The six cards are **general share / referral collateral**, all six built from the same codemoji brand vocabulary — the **safe** (сейф), the **diamonds** (алмазы), the **key** (ключ), the crowd of emoji characters, the `CODE/MOJI` wordmark. The vocabulary is the codemoji metaphor for the prize layer (the safe holds the diamonds; the player earns the key) and is used **uniformly across all six** as marketing/invite imagery — **none of the six is a Golden-Room-specific win narrative** ("player X just won N boosted diamonds in room Y"). If/when a Golden-Room win card variant ships it would be a separate card composed at the [Sharing surface](04-sections.md#sharing) with the player's `PLR` + the boosted pool + the `gold_multiplier` — flagged here as an absence, not invented.

Vocabulary referenced here is defined in [`README.md`](README.md).

---

## story RU v1

| field | value |
|---|---|
| figma id | `521:12680` |
| figma label | `story RU v1` |
| figma type | COMPONENT |
| figma page | UI |
| asset | [`assets/story-ru-v1-521-12680.png`](assets/story-ru-v1-521-12680.png) |
| role | sharable story card (RU master component v1) |
| game state | n/a |
| mode | n/a |
| entities | `PLR` |
| en_instance | [`726:14576` (`story EN v1`)](#story-en-v1) |

**Depicts** — headline `Время открывать сейф!` ("Time to open the safe!") with a dark cracked-safe character (the codemoji safe icon — `$$` eyes + a wide grin), the `CODEMOJI` wordmark above. The opening **invite/CTA** card: the player asks a friend to come crack a code with them. The first share-card master in Russian; the English instance at `726:14576` overrides the headline.

![story RU v1](assets/story-ru-v1-521-12680.png)

---

## story EN v1

| field | value |
|---|---|
| figma id | `726:14576` |
| figma label | `story EN v1` |
| figma type | INSTANCE |
| figma page | UI |
| asset | [`assets/story-en-v1-726-14576.png`](assets/story-en-v1-726-14576.png) |
| role | sharable story card (EN instance of v1) |
| game state | n/a |
| mode | n/a |
| entities | `PLR` |
| instance_of | [`521:12680` (`story RU v1`)](#story-ru-v1) |

**Depicts** — the v1 safe-CTA framing translated for the English audience; the dark safe character, the wordmark, and the layout come from the master `521:12680`. Text-override only.

![story EN v1](assets/story-en-v1-726-14576.png)

---

## story RU v2

| field | value |
|---|---|
| figma id | `521:12681` |
| figma label | `story RU v2` |
| figma type | COMPONENT |
| figma page | UI |
| asset | [`assets/story-ru-v2-521-12681.png`](assets/story-ru-v2-521-12681.png) |
| role | sharable story card (RU master component v2) |
| game state | n/a |
| mode | n/a |
| entities | `PLR` |
| en_instance | [`726:14577` (`story EN v2`)](#story-en-v2) |

**Depicts** — headline `Получаю ключ для сейфа` ("I'm getting the key for the safe") over the codemoji character motif. The **reward-moment** card — the player frames the win as having earned the *key* (the path to the prize layer), not the diamonds themselves. Useful for sharing after a play session as a personal-achievement note.

![story RU v2](assets/story-ru-v2-521-12681.png)

---

## story EN v2

| field | value |
|---|---|
| figma id | `726:14577` |
| figma label | `story EN v2` |
| figma type | INSTANCE |
| figma page | UI |
| asset | [`assets/story-en-v2-726-14577.png`](assets/story-en-v2-726-14577.png) |
| role | sharable story card (EN instance of v2) |
| game state | n/a |
| mode | n/a |
| entities | `PLR` |
| instance_of | [`521:12681` (`story RU v2`)](#story-ru-v2) |

**Depicts** — the v2 key-reward framing translated for the English audience. Master layout from `521:12681`; text-override only.

![story EN v2](assets/story-en-v2-726-14577.png)

---

## story RU v3

| field | value |
|---|---|
| figma id | `727:14849` |
| figma label | `story RU v3` |
| figma type | COMPONENT |
| figma page | UI |
| asset | [`assets/story-ru-v3-727-14849.png`](assets/story-ru-v3-727-14849.png) |
| role | sharable story card (RU master component v3) |
| game state | n/a |
| mode | n/a |
| entities | `PLR` |
| en_instance | [`727:14850` (`story EN v3`)](#story-en-v3) |

**Depicts** — headline `Алмазы в сейфе` ("Diamonds in the safe") with the `CODEMOJI` wordmark above and a dense **crowd of emoji characters** filling the lower half. The emphasis is the prize layer (`diamonds`, the codemojex prize currency — see [README.md#currencies](README.md#currencies)) sitting behind the social density of the game. The widest-audience pitch of the safe-and-diamonds metaphor.

![story RU v3](assets/story-ru-v3-727-14849.png)

---

## story EN v3

| field | value |
|---|---|
| figma id | `727:14850` |
| figma label | `story EN v3` |
| figma type | INSTANCE |
| figma page | UI |
| asset | [`assets/story-en-v3-727-14850.png`](assets/story-en-v3-727-14850.png) |
| role | sharable story card (EN instance of v3) |
| game state | n/a |
| mode | n/a |
| entities | `PLR` |
| instance_of | [`727:14849` (`story RU v3`)](#story-ru-v3) |

**Depicts** — the v3 diamonds-in-the-safe framing translated for the English audience. Master layout + crowd-of-emojis composition from `727:14849`; text-override only.

![story EN v3](assets/story-en-v3-727-14850.png)

---

## story RU v4

| field | value |
|---|---|
| figma id | `727:14964` |
| figma label | `story RU v4` |
| figma type | COMPONENT |
| figma page | UI |
| asset | [`assets/story-ru-v4-727-14964.png`](assets/story-ru-v4-727-14964.png) |
| role | sharable story card (RU master component v4) |
| game state | n/a |
| mode | n/a |
| entities | `PLR` |
| en_instance | [`732:15272` (`story EN v4`)](#story-en-v4) |

**Depicts** — headline `Игра года НОМЕР 1` ("Game of the year — #1") with the `CODEMOJI` wordmark and a small character motif. The boldest **marketing-claim** card in the set; reads as the strongest external pitch rather than a reward or invite. Useful as an introduction card with no prior play context required.

![story RU v4](assets/story-ru-v4-727-14964.png)

---

## story EN v4

| field | value |
|---|---|
| figma id | `732:15272` |
| figma label | `story EN v4` |
| figma type | FRAME |
| figma page | UI |
| asset | [`assets/story-en-v4-732-15272.png`](assets/story-en-v4-732-15272.png) |
| role | sharable story card (EN translation of v4, FRAME rather than INSTANCE) |
| game state | n/a |
| mode | n/a |
| entities | `PLR` |
| translation_of | [`727:14964` (`story RU v4`)](#story-ru-v4) |

**Depicts** — the v4 "game of the year #1" marketing claim translated for the English audience. The v4 EN is authored as a standalone `FRAME` rather than as an instance — outside the master/instance discipline the other versions follow. Worth deciding whether to re-author it as an instance for consistency, or to leave it as the divergence the file ships with today.

![story EN v4](assets/story-en-v4-732-15272.png)

---

## story RU v5

| field | value |
|---|---|
| figma id | `861:65455` |
| figma label | `story RU v5` |
| figma type | COMPONENT |
| figma page | UI |
| asset | [`assets/story-ru-v5-861-65455.png`](assets/story-ru-v5-861-65455.png) |
| role | sharable story card (RU master component v5) |
| game state | n/a |
| mode | n/a |
| entities | `PLR` |
| en_instance | [`862:16637` (`story EN v5`)](#story-en-v5) |

**Depicts** — the `CODE/MOJI` wordmark (with the safe character substituting for the `O`, `$$` eyes intact) centered over a **dense emoji-character wallpaper**. No headline copy — this is the pure **brand-presence** card, useful as the fallback share when no narrative slot fits (no win to celebrate, no key to claim, no game-of-the-year claim to make).

![story RU v5](assets/story-ru-v5-861-65455.png)

---

## story EN v5

| field | value |
|---|---|
| figma id | `862:16637` |
| figma label | `story EN v5` |
| figma type | INSTANCE |
| figma page | UI |
| asset | [`assets/story-en-v5-862-16637.png`](assets/story-en-v5-862-16637.png) |
| role | sharable story card (EN instance of v5) |
| game state | n/a |
| mode | n/a |
| entities | `PLR` |
| instance_of | [`861:65455` (`story RU v5`)](#story-ru-v5) |

**Depicts** — the v5 brand-presence card; since v5 has no headline copy, the EN instance largely preserves the master `861:65455`. The `CODE/MOJI` wordmark is brand-neutral and reads the same in both locales.

![story EN v5](assets/story-en-v5-862-16637.png)

---

## story RU v6

| field | value |
|---|---|
| figma id | `862:16636` |
| figma label | `story RU v6` |
| figma type | COMPONENT |
| figma page | UI |
| asset | [`assets/story-ru-v6-862-16636.png`](assets/story-ru-v6-862-16636.png) |
| role | sharable story card (RU master component v6) |
| game state | n/a |
| mode | n/a |
| entities | `PLR` |
| en_instance | [`862:16638` (`story EN v6`)](#story-en-v6) |

**Depicts** — the `CODE/MOJI` wordmark over a layered background that brings the **diamond/treasure** motif forward against a varied emoji bg. The most visually layered of the brand cards — pairs the brand mark with the prize-layer visual without committing to a specific headline.

![story RU v6](assets/story-ru-v6-862-16636.png)

---

## story EN v6

| field | value |
|---|---|
| figma id | `862:16638` |
| figma label | `story EN v6` |
| figma type | INSTANCE |
| figma page | UI |
| asset | [`assets/story-en-v6-862-16638.png`](assets/story-en-v6-862-16638.png) |
| role | sharable story card (EN instance of v6) |
| game state | n/a |
| mode | n/a |
| entities | `PLR` |
| instance_of | [`862:16636` (`story RU v6`)](#story-ru-v6) |

**Depicts** — the v6 brand + diamond/treasure card with English text overrides where applicable. Master composition from `862:16636`.

![story EN v6](assets/story-en-v6-862-16638.png)
