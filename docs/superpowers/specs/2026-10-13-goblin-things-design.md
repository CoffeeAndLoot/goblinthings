# Goblin Things: design

Date: 2026-10-13. Status: approved in conversation, awaiting review of this file.

## Purpose

A WoW Forever addon (interface 16001: Classic data on the 12.x engine) of small
quality-of-life switches, set once and forgotten: quest pick-up and turn-in,
vendor chores, camera distance, cinematics, and refusing duels and guild invites.
It is a new addon in its own folder and repo, not part of Goblin Flyout or
GoblinQuest (shelved).

Success: a player installs it, opens the window once, sets what they want, and
from then on stops clicking through quest text, vendors, repeat cinematics and
unwanted invites. Each switch does exactly what its row says, and an answer the
game does not give is a reason to do nothing.

## Rules (carried from Goblin Flyout)

- Blizzard source of truth: `D:\wow-api\1.60.1.70291\Interface\AddOns` (the
  `forever` branch). Never guess an API, event or template name.
- `API.lua` is the only file that calls Blizzard game APIs, each through
  `attempt()`.
- Pure modules touch no Blizzard global at file load; `test/run.lua` loads them.
- No libraries. Files copied from Goblin Flyout or GoblinQuest are copies, kept
  in this repo.
- The window, options page and minimap button wear the Goblin look (`Look.lua`,
  copied from Goblin Flyout): plain frames and colour textures, no Blizzard frame
  templates, colours only from `Look.COLOUR`.
- "Verified in source" is not "verified in game". In-game checks live in
  `docs/manual-test-checklist.md`; every UI or behaviour change adds an entry.
- Calendar versions in the TOC only. Commit after each change: `Area: plain
  sentence`. Push only when the owner asks.

## Scope: version 1

Eight switches. Defaults are what a new install gets.

| Key | Label | Section | Control | Default |
|---|---|---|---|---|
| `autoAccept` | Auto accept quests | Quests | checkbox | on |
| `autoTurnIn` | Auto turn-in quests | Quests | checkbox | on |
| `autoSellJunk` | Auto sell junk | Vendors | checkbox | on |
| `autoRepair` | Auto repair | Vendors | checkbox | on |
| `declineDuels` | Decline duels | Social | checkbox | off |
| `declineGuild` | Decline guild invites | Social | checkbox | off |
| `cameraDistance` | Camera distance | Camera | slider 1.0 to 4.0, step 0.1 | untouched |
| `cinematics` | Skip cinematics | Cinematics | Off / Repeats only / All | Repeats only |

Out of scope for version 1 (YAGNI): a switch for dungeon quests, exceptions for
friends on the declines, picking quest rewards, guild-bank repair, petition
signing, and any feature not in the table.

## Behaviour

### Quests (`Hands.lua`, lifted from GoblinQuest)

The pure decision module from `D:\goblinquest\GoblinQuest\Hands.lua`, without
the planner's pieces (the `allowed` route filter and `Hands.Record`).

- **Auto accept** takes an offered quest at a gossip, greeting or detail window,
  except: trivial (gray), repeatable, ignored, dungeon or raid tagged
  (Enum.QuestTag 81 and 62), a suggested group of 5 or more, and PvP. Those
  wait for the player. Dungeon skipping is always on: no switch.
- **Auto turn-in** selects a complete active quest, completes it at the progress
  window, and takes the reward at the complete window, except when the quest
  costs gold or offers more than one reward choice. Those wait for the player.
- One try per action per visit. A visit ends at `GOSSIP_CLOSED` or
  `QUEST_FINISHED`.

### Vendors (`Vendor.lua`, lifted from GoblinQuest)

At `MERCHANT_SHOW`:

- **Auto sell junk** sells every gray (`Enum.ItemQuality.Poor`) that has a sell
  value and is not locked. One chat line: "Sold 4 junk for 12s 5c." (or "Sold 4
  junk." when a price is unknown).
- **Auto repair** repairs with the player's own gold when the vendor can repair
  and the cost is above 0. Short of gold: "Not enough gold to repair (costs 1g
  2s)." and nothing is repaired; grays still sell.
- Reopening a vendor acts again, once.

### Shift

Holding Shift as an NPC quest window or a vendor opens skips every quest and
vendor action for that visit.

### Social (`Decline.lua`)

- **Decline duels**: on `DUEL_REQUESTED` (payload: the challenger's name),
  call `CancelDuel()` (what Blizzard's own `DUEL_REQUESTED` popup calls,
  `Blizzard_StaticPopup_Game/GameDialogDefs.lua`). Line: "Declined a duel from
  Bob."
- **Decline guild invites**: on `GUILD_INVITE_REQUEST` (payload: inviter,
  guild name, ...), call `DeclineGuild()` (Blizzard's Decline button,
  `Blizzard_FrameXML/GuildInviteFrame.xml:152`). Line: "Declined a guild invite
  from Bob (<Guild Name>)."
- Blizzard's popups should close on their own (`DUEL_FINISHED`,
  `GUILD_INVITE_CANCEL`); if either lingers in game, `API.lua` hides it.

### Camera (`Camera.lua`)

- The slider reads the `cameraDistanceMaxZoomFactor` CVar every time the window
  shows and writes it when moved, clamped to 1.0 to 4.0 and rounded to 0.1.
  Nothing is saved by the addon: the game saves the CVar.
- Until the player moves the slider, the addon never writes the CVar.
- Blizzard's own slider (Options > Controls, 1.0 to 2.0,
  `Blizzard_SettingsDefinitions_Frame/Camelot/ControlsOverrides.lua`) and ours
  share the CVar; whichever moved last wins.
- Verified in game on 2026-10-13: the client keeps 2.6 and 4, the camera zooms
  further than at 2.0, and opening Options > Controls does not reset it.

### Cinematics (`Cinematics.lua`)

Mode `off` does nothing; `all` stops every cinematic and movie; `repeats` stops
only ones seen before and marks new ones seen.

- Movies: `PLAY_MOVIE` carries a `movieID`. Stop with `MovieFrame:FinishMovie()`
  (Blizzard's own confirm-skip button, `Blizzard_FrameXML/MovieFrame.lua`).
- In-engine cinematics: `CINEMATIC_START` carries no ID (payload
  `canBeCancelled`, `forcedAspectRatio`). The key is the player's race and map
  (`Scourge:1420`): each race's intro plays once, in its starting zone.
  `GetCurrentCinematicSummary()` is recorded at each start and shown by
  `/gt probe`; if it turns out to name the cinematic, it may replace the key.
  Stop with `StopCinematic()` (what `CinematicFrame_CancelCinematic` calls),
  only when `canBeCancelled` is true: false means a vehicle ride, never touched.
- Unknown key (no race or map) in Repeats only: do nothing.
- The seen list is account-wide: `{ movies = { [id] = true }, cinematics = {
  [key] = true } }`.

## Architecture

```
GoblinThings/
  GoblinThings.toc
  API.lua  Features.lua  Hands.lua  Vendor.lua  Camera.lua  Cinematics.lua
  Decline.lua  Look.lua  Options.lua  Window.lua  MinimapButton.lua  Core.lua
  Media/icon.tga  Media/icons/close-*.tga
```

TOC load order: `API, Features, Hands, Vendor, Camera, Cinematics, Decline,
Look, Options, Window, MinimapButton, Core`.

- **`Features.lua`** (pure): `Features.LIST`, the table above as data (key,
  label, section, control, default; slider min, max, step; choice values and
  labels). The window builds its rows from it; nothing else lists the switches.
- **`Hands`, `Vendor`, `Camera`, `Cinematics`, `Decline`** (pure): each takes a
  plain view (built by `API.lua`) and the settings, and returns what to do. None
  calls the game.
- **`API.lua`**: reads the game into views and carries out decisions, every call
  through `attempt()`.
- **`Options.lua`**: `Options.Init(db)` makes the SavedVariable valid (pure); a
  stub page under Esc > Options > AddOns > Goblin Things opens the window.
- **`Window.lua`**: the Goblin-look window, built from `Features.LIST`.
- **`MinimapButton.lua`**: the round "GT" button, draggable round the minimap,
  hideable.
- **`Core.lua`**: events to modules, every handler behind `guard(label, ...)`
  (one error per label per session); slash commands; chat lines.

Events: `GOSSIP_SHOW`, `QUEST_GREETING`, `QUEST_DETAIL`, `QUEST_PROGRESS`,
`QUEST_COMPLETE` → Hands; `GOSSIP_CLOSED`, `QUEST_FINISHED` end the visit;
`MERCHANT_SHOW` → Vendor; `DUEL_REQUESTED`, `GUILD_INVITE_REQUEST` → Decline;
`PLAY_MOVIE`, `CINEMATIC_START` → Cinematics.

### SavedVariable

`GoblinThingsDB`, account-wide:

```lua
{
  features = { autoAccept = true, ..., cinematics = "repeats" },  -- no cameraDistance: the CVar is the store
  seen = { movies = {}, cinematics = {} },
  minimap = { angle = 225, hide = false },
  window = { point, relativePoint, x, y } | nil,
}
```

`Options.Init` fills any missing or wrong-typed field with its default and keeps
the table it was given.

## Window

- Movable Goblin-look window; remembers its position. Opened by `/gt`,
  `/goblinthings`, the minimap button, or the options-page stub.
- Rows grouped under gold section headers: Quests, Vendors, Social, Camera,
  Cinematics.
- Controls: a Look checkbox; a Look slider with its value shown (e.g. "3.2"); a
  three-segment switch for Off | Repeats only | All, styled like Goblin Flyout's
  Horizontal | Vertical.
- Footer: "Show minimap button" checkbox, and the line "Hold Shift at an NPC or
  vendor to skip."

## Commands

| Command | Does |
|---|---|
| `/gt` | Opens the window |
| `/gt minimap` | Hides or shows the minimap button |
| `/gt probe` | Prints each setting, the camera CVar, the seen counts, this spot's cinematic key, the last `GetCurrentCinematicSummary()` this session, and `attempt()` errors |

## Errors

- Every game call through `attempt()`; every handler behind `guard()`.
- An unknown answer (nil quality, price, quest ID, tag) means do nothing.
- Nothing here is secure or blocked in combat by the source. The camera write
  still goes through `attempt()`; if a combat failure shows in `/gt probe`, it
  waits for `PLAYER_REGEN_ENABLED`.

## Testing

- Pure modules (`Features`, `Hands`, `Vendor`, `Camera`, `Cinematics`,
  `Decline`, `Options.Init`) under `test/run.lua` through lupa, with
  GoblinQuest's `Hands` and `Vendor` suites brought along and trimmed to match.
- luacheck and lua-language-server at zero warnings; CI runs both on every push
  (copied from Goblin Flyout).
- `docs/manual-test-checklist.md`, one entry per switch, including what
  GoblinQuest never walked in game: Shift skip, vendor reopen, short of gold,
  the popups gone after a decline, and the cinematic summary string.

## Open facts (settle in game)

1. What `GetCurrentCinematicSummary()` returns during a race intro: a better
   key than race and map, or not.
2. Whether the duel and guild-invite popups close on their own after a decline.
3. Whether the camera CVar can be written in combat.

## Release

Same path as Goblin Flyout when the owner asks: public repo
`CoffeeAndLoot/goblinthings`, MIT, a Wago project whose ID goes in the TOC as
`X-Wago-ID`, and a `v<TOC version>` tag that triggers the release workflow.
