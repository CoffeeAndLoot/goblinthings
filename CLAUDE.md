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
- `docs/superpowers/specs/2026-11-10-map-zone-readout-design.md`: the world map's corner readout.
- `docs/superpowers/specs/2026-11-14-map-gathering-lists-design.md`: herbs, ore, fish and skins on
  that readout (its plan is `docs/superpowers/plans/2026-11-14-map-gathering-lists.md`). Read its
  dated amendments: they overturn parts of the text above them.
- `docs/cvar-candidates.md`: console-only settings that could become switches (researched
  2026-11-15 from the client exe's own strings; a list to pick from, nothing built or seen in game).
- `docs/manual-test-checklist.md`: every in-game check, ticked only by the owner.
- `docs/art-spec.md`: the brief for the plaque banner the window wore until 2026-11-14; kept for
  the record, no longer built.

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
- The window, options page, minimap button and the map readout's lists wear **the game's own look**
  (`Look.lua`; the owner's "back to roots", 2026-11-14): the palette is sampled from WoW Forever's
  Statistics and Professions windows (brown panels, bronze edges, bright gold titles, white words),
  drawn with plain frames and colour textures. **No Blizzard frame templates or art files**, so no
  texture name is guessed and a renamed template cannot break it; colours only from `Look.COLOUR`.
  Do not add art to the window: a title bar, not a banner. Goblin Flyout keeps the older Goblin
  look, so the two no longer match.
- Art is generated, never hand-edited: `python tools/make_art.py [preview_dir]` cuts
  `Media/icon.tga` plus `images/thumbnail.png` (the round goblin: the minimap button and the
  AddOns-list icon) from `tools/art/concept-sheet.png`. `Media/icons/close-*.tga` are Goblin
  Flyout's, copied. `images/banner.png` is the README's hero only. A new or changed TGA needs a
  full client restart.
- The gathering lists are generated too, never hand-edited: `python tools/make_gathering.py` writes
  `GoblinThings/MapData.lua` from three sources in `tools/gathering/`. `wowhead-forever.json`
  (`wowhead.com/forever/zone=<area id>`, Forever's own database) is the authority for herbs, ore
  and fish; `wowhead-classic.json` is the fallback for a fish list Forever has too few catches
  for, marked in `CLASSIC_NODES` / `CLASSIC_FISH` and footnoted in the list;
  `wowhead-forever-skins.json` is each leather's skinned-from list (`/forever/item=<id>`).
  - The sources are read out of the pages in the browser pane. Wowhead answers a script with 403
    and asks for human verification about every 28 pages whatever the pace; **only the owner may
    pass it**, so stop and ask.
  - The script writes nothing unless every check passes. A node name it does not know stops it:
    add it to `HERBS`, `ORE` or `QUEST_OBJECTS` (Wowhead types quest objects as herbs and veins).
  - UiMap ID to Wowhead area ID is the script's `ZONES`; UiMap IDs come from
    `D:\GoblinPS\docs\research\data\UiMap.csv` (the client's own table).
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
  the README, so edit it in its style rather than pasting the README over it. Its banner and five
  screenshots (three tabs, the Map tab, the map readout) are the README's raw `master` URLs, so a replaced screenshot shows there on its own; a new
  image file needs its own line.

## How it fits together

TOC load order is `API, Features, Hands, Vendor, Trainer, Camera, Cinematics, Decline, Accept, Loot, TrackerSort, MapData, MapInfo, Kills, Look, Options, Window, MinimapButton, MapReadout, KillsReadout, Core`.

1. `Features.LIST` is every switch as data: key, label, section (its tab), optional group (a
   sub-header), control (`check`, `slider`, `choice`) and default; `Features.NOTES` gives a tab its
   dim note. The window builds its tabs and rows from it; `Options.Init` stores every feature with a
   default. One with a `cvar` (the camera, Guild login alerts) has none: the game's own CVar is its store.
2. `Hands` (quests), `Vendor`, `Trainer`, `Camera`, `Cinematics`, `Decline`, `Accept`, `Loot` and
   `Kills` are pure: each takes plain values (views built by `API.lua`) and the settings, and says
   what to do.
3. `Core` routes events to them behind `guard(label, ...)` (one error per label per session) and has
   `API` carry out the result. `Core.Get(key)` / `Core.Set(key, value)` are the one door to every
   setting, the camera's CVar included.
4. Holding Shift as an NPC or vendor window opens skips every quest and vendor action that visit.
5. The tracker sort (`TrackerSort`, pure) wraps `QuestObjectiveTracker.BuildQuestWatchInfos` via
   `API.SetTrackerSort` once a tier is set, Only this zone is on or Hide quests above me is set (it
   also filters); all None leaves it in as a pass-through until /reload
   (XML `mixin=` copies methods onto the frame, so setting the field to nil would delete the
   tracker's own method). A player who never sorts never has the tracker touched.
6. The world map readout: up to six lines on a small card at the map canvas's bottom right (name,
   levels, fishing, herbs, ore, skins), checked each frame the map is shown. The card is the game's
   look (letters straight on the parchment washed out) and is sized to the lines showing.
   - `MapInfo` (pure) holds hand-written level ranges and fishing skills by UiMap ID, reads the
     generated `MapData` inside its functions, and decides everything: `Pick(shown, hovered, show)`
     the map to describe, `Lines(mapID, name, show)` each line as `{ text, kind }`, and
     `List(kind, mapID)` a list's title, rows and footnote. `show` is the four list switches
     (`mapHerbs`, `mapOre`, `mapFish`, `mapSkins`); a zone known only by its lists (Shen'dralas)
     is known only while one is on, and a catch list with no known skill (Riverglades, Zephras
     Isle) gets a bare "Fishing" line.
   - `MapReadout` draws and decides nothing. It finds the hovered zone with `API.MapUnderCursor`,
     as Blizzard's area label does. A line with a `kind` ends in an icon only when the readout
     describes the map that is open: on a continent the cursor would cross other zones on its way
     to the corner. The frame is mouse-off so the canvas keeps its hover; the icons are its only
     mouse-live frames, and hovering one opens the list.
   - Icons are `API.ProfessionIcon(kind)`, a spell's texture (see Client facts); a letter square is
     drawn whenever the game gives nothing.
   - `C_Map.GetMapLevels` exists on this build and answers for no zone, so never switch to it
     without an in-game check; `/gt probe` counts the hover API's answers and the icons given.
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
- A zone's own map names its neighbours (2026-11-14, Mount Hyjal's map): `C_Map.GetMapInfoAtPosition`
  answers with Winterspring's map where Winterspring's edge is drawn; likewise Durotar round
  Orgrimmar's map (2026-11-15). `MapInfo.Pick` therefore never lets a zone (a map with a level range)
  take over a map that has its own card; a city on its zone's map still does.
- Profession icons (2026-11-14, `/gt probe` and the owner's screenshot of Riverglades' map):
  `C_Spell.GetSpellTexture` answers for spells 2366 (Herbalism), 2575 (Mining), 7620 (Fishing) and
  8613 (Skinning), and each picture is that profession's own icon.
- The map hover (2026-11-14, `/gt probe`): `C_Map.GetMapInfoAtPosition` answered 267 of 267 asks.
- Solo XP lines (2026-11-14, `/gt probe`, Riverglades): "Glade Viper dies, you gain 260 experience."
  and the `UnitXP` change that follows is the same 260. One `PLAYER_XP_UPDATE` arrived with no
  change (+0) between kills.
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

The generators, from the repo root (each rewrites its outputs whole; see Rules):

```
python tools/make_art.py [preview_dir]
python tools/make_gathering.py
```

The Bash tool here is Git Bash and has twice failed to parse a heredoc holding Lua or Python with
apostrophes ("unexpected EOF while looking for matching `'`"), running nothing. For a multi-file
edit write a script with the Write tool and run that, or use Edit.
