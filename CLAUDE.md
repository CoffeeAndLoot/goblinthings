# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Goblin Things

WoW Forever addon (interface 16001: Classic data on the 12.x engine, game type `camelot`).
Quality-of-life switches in one tabbed Goblin-look window; the README's table is the list, one row
per switch. Docs:

- `docs/superpowers/specs/2026-10-13-goblin-things-design.md`: the first design (its Window is
  superseded by the second's Tabs).
- `docs/superpowers/specs/2026-10-13-tracker-sort-and-tabs-design.md`: the tracker sort and the tabs.
- `docs/superpowers/specs/2026-11-11-kills-to-level-design.md`: the kills-to-level number (its plan is
  `docs/superpowers/plans/2026-11-11-kills-to-level.md`).
- `docs/superpowers/specs/2026-11-14-map-gathering-lists-design.md`: herbs, ore and fish lists on the
  map readout (its plan is `docs/superpowers/plans/2026-11-14-map-gathering-lists.md`).
- `docs/manual-test-checklist.md`: every in-game check, ticked only by the owner.
- `docs/art-spec.md`: the brief for regenerating the header banner.

Sibling of Goblin Flyout (`D:\GoblinFlyout`); the quest and vendor rules came from GoblinQuest
(`D:\goblinquest`, shelved).

## Rules

- Blizzard source of truth: `D:\wow-api\1.60.1.70291\Interface\AddOns` (the `forever` branch).
  `12.1.5.*` is Retail and never the authority. Never guess an API, event or template name.
- "Verified in source" is not "verified in game". Only the owner runs the client; in-game
  checks live in `docs/manual-test-checklist.md` and every UI or behaviour change adds an entry.
  Tick a box only for what the owner saw; `[-]` means skipped by choice, with the reason.
- `API.lua` is the only file that calls Blizzard game APIs, each through `attempt()`.
- Pure modules touch no Blizzard global at file load; test/run.lua loads them.
- No libraries. An unknown answer from the game means do nothing.
- The window, options page and minimap button wear the Goblin look (`Look.lua`, from Goblin
  Flyout): plain frames and colour textures, **no Blizzard frame templates**, colours only from
  `Look.COLOUR`.
- Art is generated, never hand-edited: `python tools/make_art.py [preview_dir]` cuts
  `GoblinThings/Media/header.tga` (the plaque banner) from `tools/art/header-source.png` (made to
  `docs/art-spec.md`) and `Media/icon.tga` plus `images/thumbnail.png` (the round goblin) from
  `tools/art/concept-sheet.png`. The banner keeps its source pixels (sharp at 4K) and its backdrop
  is set to `Look.COLOUR.window`, so it is laid edge to edge; `Window.BANNER` must match the
  script's crop box. `Media/icons/close-*.tga` are Goblin Flyout's, copied. `images/banner.png` is
  the README's hero only. A new or changed TGA needs a full client restart.
- The gathering lists are generated too: `python tools/make_gathering.py` writes
  `GoblinThings/MapData.lua` from `tools/gathering/wowhead-forever.json` (Wowhead's Forever database,
  `wowhead.com/forever/zone=<area id>`, the authority) and `wowhead-classic.json` (Classic Era's, the
  fallback for a zone or fish list Forever's lacks, marked in `CLASSIC_NODES` / `CLASSIC_FISH` and
  footnoted in the list). Both are read out of the pages in a browser: Wowhead answers a script with
  403, and after about 30 pages asks for human verification whatever the pace, which only the owner
  may pass. A node name the script does not know stops it: add it to `HERBS`, `ORE` or `QUEST_OBJECTS`.
  Zone area IDs are in the script's `ZONES` (Mount Hyjal 616, Riverglades 16591). Never hand-edit
  `MapData.lua`; the script's `PENDING` set (empty since 2026-11-14) names any zone not read yet.
- Adding a file to the TOC needs a full client restart, not `/reload`. Say so.
- Calendar versions (`2026.10.13`, `.2` for a second that day), written only in the TOC.
- Commit after each change: `Area: plain sentence`. Push only when the owner asks. CI runs the suite
  on Lua 5.1 and luacheck on every push.
- A release: the owner has ticked the checklist for everything since the last tag, the TOC version
  is bumped to today, then `git tag v<TOC version>` and push the tag. The release workflow checks
  the tag matches the TOC, zips the addon with the licence, writes the changelog from the commits
  since the previous tag, attaches both to a GitHub release, and posts to Wago (project
  `rN4rvyKD`, the TOC's `X-Wago-ID`, listed at addons.wago.io/addons/goblin-things) with the
  repo's `WAGO_API_TOKEN` secret; both are set (2026-10-16). The repo is public and
  the README's images are `raw.githubusercontent.com` URLs, as Goblin Flyout's are, so they render
  on Wago too. The Wago project is deliberately **not** linked to the GitHub repo (Wago only links at
  creation; the link's features, its own release automation and README import, are not wanted:
  the workflow uploads each release itself, and both on would post every release twice).
  So Wago never sees the README: when a switch was added or changed since the last tag, edit the Wago
  project's Summary and Description by hand (addons.wago.io/developers/projects/goblin-things/settings;
  Wago's API uploads versions only, docs.wago.io). The description is its own shorter Markdown version of
  the README, so edit it in its style rather than pasting the README over it. Its banner and three tab
  screenshots are the README's raw `master` URLs, so a replaced screenshot shows there on its own; a new
  image file needs its own line.

## How it fits together

TOC load order is `API, Features, Hands, Vendor, Trainer, Camera, Cinematics, Decline, Accept, Loot, TrackerSort, MapData, MapInfo, Kills, Look, Options, Window, MinimapButton, MapReadout, KillsReadout, Core`.

1. `Features.LIST` is every switch as data: key, label, section (its tab), optional group (a
   sub-header), control (`check`, `slider`, `choice`) and default; `Features.NOTES` gives a tab its
   dim note. The window builds its tabs and rows from it; `Options.Init` stores every feature with a
   default. One with a `cvar` (the camera, Guild login alerts) has none: the game's own CVar is its store.
2. `Hands` (quests), `Vendor`, `Trainer`, `Camera`, `Cinematics`, `Decline`, `Accept`, `Loot` and `Kills` are pure: each takes plain values
   (views built by `API.lua`) and the settings, and says what to do.
3. `Core` routes events to them behind `guard(label, ...)` (one error per label per session) and has
   `API` carry out the result. `Core.Get(key)` / `Core.Set(key, value)` are the one door to every
   setting, the camera's CVar included.
4. Holding Shift as an NPC or vendor window opens skips every quest and vendor action that visit.
5. The tracker sort (`TrackerSort`, pure) wraps `QuestObjectiveTracker.BuildQuestWatchInfos` via
   `API.SetTrackerSort` once a tier is set, Only this zone is on or Hide quests above me is set (it also filters); all None leaves it in as a pass-through until /reload
   (XML `mixin=` copies methods onto the frame, so setting the field to nil would delete the
   tracker's own method). A player who never sorts never has the tracker touched.
6. The world map readout (`docs/superpowers/specs/2026-11-10-map-zone-readout-design.md`):
   `MapInfo` (pure) holds hand-written level ranges (copied from GoblinPS) and Classic fishing
   skills by UiMap ID, and picks the map to describe; `MapReadout` draws it at the map canvas's
   bottom right each frame the map is shown, from `API.MapUnderCursor` (as Blizzard's area label
   finds the hovered zone). `C_Map.GetMapLevels` exists on this build and answers for no zone, so
   never switch to it without an in-game check; `/gt probe` counts the hover API's answers.
   `MapData` (generated, pure) adds herbs, ore and fish per zone: `MapInfo.Lines` gives each line as
   `{ text, kind }` and `MapInfo.List(kind, mapID)` a list's rows. A line with a `kind` ends in an
   icon only when the readout describes the map that is open (on a continent the cursor would cross
   other zones on its way to the corner). The icons are the readout's only mouse-live frames; their
   pictures come from `API.ProfessionIcon` (a spell's texture), a letter when the game gives none.
7. Kills to level: `Kills` (pure) keeps the last ten kills' XP and divides the XP still needed by
   their average; `KillsReadout` draws the one ghosted number `Core`'s `drawKills` hands it, on
   `UIParent` at strata BACKGROUND with the mouse off. A kill is a `CHAT_MSG_COMBAT_XP_GAIN` line
   matching the pattern `Kills.Pattern` builds from the game's own `COMBATLOG_XPGAIN_FIRSTPERSON`, so
   it follows the client's language; its figure is the sample. Samples are session-only and taken
   only while the switch is on. Quest, exploration and unnamed XP lower the count but are no sample.
   The window's XP tab shows a sample `37` while it is open, to tune the look.

## Client facts (verified in game)

- `cameraDistanceMaxZoomFactor` keeps 2.6 and 4, the camera zooms further than at 2.0, and opening
  Options > Controls does not reset it (2026-10-13).
- Quest tracker order (2026-10-13): the watch list keeps the game's own order; `RemoveQuestWatch` +
  `AddQuestWatch` does **not** move a quest (1483 stayed first; its watch type stayed 1, Manual).
  Setting `QuestObjectiveTracker.BuildQuestWatchInfos` to a wrapper that sorts Blizzard's result
  and calling `QuestObjectiveTracker:MarkDirty()` reorders the tracker (A→Z and Z→A both seen).
  Untested: whether that taint blocks the tracker's quest-item button (`UseQuestLogSpecialItem`).
- "On this map" (2026-10-13, the Crossroads, map 1413): `C_QuestLog.GetQuestsOnMap(1413)` also lists
  Stonetalon quests (1060, 1069, 1483) with `mapID` 1442, and `C_QuestLog.IsOnMap` counts them as
  on the map. Only an entry whose `mapID` is the player's map is really here (`TrackerSort.HereSet`).
  `GetMapForQuestPOIs()` and `GetBestMapForUnit("player")` both read 1413 there.
- XP lines (2026-11-11, `/gt probe` in a party, the owner's screenshot): `CHAT_MSG_COMBAT_XP_GAIN`'s text is readable
  (not secret). `COMBATLOG_XPGAIN_FIRSTPERSON` is "%s dies, you gain %d experience.",
  `COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED` is "You gain %d experience." and
  `COMBATLOG_XPGAIN_EXHAUSTION1` is "%s dies, you gain %d experience. (%s exp %s bonus)". A kill reads
  "Witherbark Witch Doctor dies, you gain 64 experience. (+19 group bonus)": the figure is the whole
  gain (the `UnitXP` change that follows is the same 64), bonus included. One gain arrived unnamed
  ("You gain 64 experience. (+19 group bonus)"). Not yet seen: a quest turn-in's or a discovery's line.

## Deploy

The addon folder is junctioned into the live client (`_forever_`; the beta folder is gone):
`New-Item -ItemType Junction -Path "D:\World of Warcraft\_forever_\Interface\AddOns\GoblinThings" -Target "D:\GoblinThings\GoblinThings"`

## Commands (this Windows box)

Tests through `lupa` from the repo root; there is no per-test filter, always run it all:

```
python -c "import lupa.lua51 as L; lua=L.LuaRuntime(unpack_returned_tuples=True); print(lua.execute(open('test/run.lua').read().replace('os.exit(harness.run())','return harness.run()')))"
```

`test/run.lua` keeps two **hand-kept lists**: pure modules (TOC order) and suites. A new module or
`test/test_*.lua` must be added there or it silently does not run.

luacheck and lua-language-server:

```
$env:PATH = "$HOME\AppData\Local\Programs\Lua\bin;$env:PATH"
$env:LUA_PATH = "$HOME\.luarocks\share\lua\5.4\?.lua;$HOME\.luarocks\share\lua\5.4\?\init.lua;;"
lua "$HOME\.luarocks\share\lua\5.4\luacheck\main.lua" GoblinThings test --no-color --no-cache
lua-language-server --check D:\GoblinThings --checklevel=Warning --check_out_path=$env:TEMP\gt-luals.json
```

Keep both at zero warnings. A new WoW global goes in both `.luacheckrc` and `.luarc.json`.
