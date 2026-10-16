# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Goblin Things

WoW Forever addon (interface 16001: Classic data on the 12.x engine, game type `camelot`).
Quality-of-life switches in one tabbed Goblin-look window; the README's table is the list, one row
per switch. Docs:

- `docs/superpowers/specs/2026-10-13-goblin-things-design.md`: the first design (its Window is
  superseded by the second's Tabs).
- `docs/superpowers/specs/2026-10-13-tracker-sort-and-tabs-design.md`: the tracker sort and the tabs.
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
- Adding a file to the TOC needs a full client restart, not `/reload`. Say so.
- Calendar versions (`2026.10.13`, `.2` for a second that day), written only in the TOC.
- Commit after each change: `Area: plain sentence`. Push only when the owner asks. CI runs the suite
  on Lua 5.1 and luacheck on every push.
- A release: the owner has ticked the checklist for everything since the last tag, the TOC version
  is bumped to today, then `git tag v<TOC version>` and push the tag. The release workflow checks
  the tag matches the TOC, zips the addon with the licence, writes the changelog from the commits
  since the previous tag, attaches both to a GitHub release, and posts to Wago (project
  `rN4rvyKD`, the TOC's `X-Wago-ID`, listed at addons.wago.io/addons/goblin-things) with the
  repo's `WAGO_API_TOKEN` secret; both are set (2026-10-16). The README's images
  are relative paths (the repo is private); when it goes public, switch them to
  `https://raw.githubusercontent.com/CoffeeAndLoot/goblinthings/master/images/...` as Goblin
  Flyout's are, so they render on Wago too.

## How it fits together

TOC load order is `API, Features, Hands, Vendor, Camera, Cinematics, Decline, Accept, Loot, TrackerSort, Look, Options, Window, MinimapButton, Core`.

1. `Features.LIST` is every switch as data: key, label, section (its tab), optional group (a
   sub-header), control (`check`, `slider`, `choice`) and default; `Features.NOTES` gives a tab its
   dim note. The window builds its tabs and rows from it; `Options.Init` stores every feature with a
   default. One with a `cvar` (the camera, Guild login alerts) has none: the game's own CVar is its store.
2. `Hands` (quests), `Vendor`, `Camera`, `Cinematics`, `Decline`, `Accept` and `Loot` are pure: each takes plain values
   (views built by `API.lua`) and the settings, and says what to do.
3. `Core` routes events to them behind `guard(label, ...)` (one error per label per session) and has
   `API` carry out the result. `Core.Get(key)` / `Core.Set(key, value)` are the one door to every
   setting, the camera's CVar included.
4. Holding Shift as an NPC or vendor window opens skips every quest and vendor action that visit.
5. The tracker sort (`TrackerSort`, pure) wraps `QuestObjectiveTracker.BuildQuestWatchInfos` via
   `API.SetTrackerSort` once a tier is set, Only this zone is on or Hide quests above me is set (it also filters); all None leaves it in as a pass-through until /reload
   (XML `mixin=` copies methods onto the frame, so setting the field to nil would delete the
   tracker's own method). A player who never sorts never has the tracker touched.

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

## Deploy

The addon folder is junctioned into the client:
`New-Item -ItemType Junction -Path "D:\World of Warcraft\_classic_beta_\Interface\AddOns\GoblinThings" -Target "D:\GoblinThings\GoblinThings"`

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
