# Map entrance pins: implementation plan

**Goal:** a blue or green swirl at each known dungeon or raid door on its own zone or city map.

**Spec:** `docs/superpowers/specs/2026-11-19-map-entrance-pins-design.md`. Built in this session,
task by task, the owner having said "build it".

## Global constraints

- `API.lua` is the only file calling Blizzard game APIs, each through `call()`/`attempt()`.
- Pure modules touch no Blizzard global at file load; both new files are loaded by `test/run.lua`.
- No Blizzard templates. The only Blizzard art: the atlases `Dungeon` and `Raid`, and only after
  `C_Texture.GetAtlasInfo` answers for them. Colours only from `Look.COLOUR`.
- No guessed coordinates. An unknown answer from the game means do nothing.
- Suite, luacheck and lua-language-server at zero; commit after each task.

## Review focus

- A map with no entrances, or the switch off: every pin hidden, the hover card too.
- The map zoomed: pins stay on their spot and keep their size.
- A pin near the map's right or top edge: its card stays inside the map.
- The game refusing an atlas: a coloured square, never an empty frame.
- A click over a pin: it reaches the map (right-click still zooms out).

## Task 1: `MapPins.lua` (pure) and `test/test_mappins.lua`

- `MapPins.ENTRANCES`: the spec's table, rows `{ map, x, y, kind, name, low, high }`, percent.
- `MapPins.For(mapID)` -> `{ { x =, y =, kind =, rows = { { name, levels } ... } } ... }`, x and y
  as 0-1. Same map and spot merge, in table order; a merged pin is `"raid"` only when every row
  is. `levels` is `"13-18"`, `"60"` for low == high, `"Raid"` for a raid without levels, else `""`.
  A malformed row (bad type, x or y outside 0-100, unknown kind) is dropped.
- `MapPins.For(mapID, entrances)` takes a table in place of `ENTRANCES`, for the tests.
- Tests: the Barrens gives three pins at their fractions; Searing Gorge one pin of three rows;
  a dungeon and a raid on one spot is a dungeon pin; raids alone a raid pin; bad rows dropped;
  unknown map and nil give `{}`; every row of `ENTRANCES` is well formed.
- TOC after `MapInfo.lua`; `test/run.lua` both lists.

## Task 2: `API.lua`, the probe, `test/test_api_map.lua`

- `API.MapID(map)` -> number or nil (`MapUnderCursor` uses it).
- `API.MapCanvas(map)` -> canvas, scale (`map:GetCanvas`, `map:GetCanvasScale`; scale 1 when the
  game gives none or not a positive number); nil without a canvas.
- `API.EntranceIcon(kind)` -> `"Dungeon"` / `"Raid"` when `C_Texture.GetAtlasInfo` gives a table.
- `API.PlayerPosition()` -> mapID, x, y in percent (`C_Map.GetPlayerMapPosition`, `:GetXY()`), or nil.
- `/gt probe`: "entrance icons from the game: dungeon yes, raid yes" and "you stand at 45.5, 35.5
  on map 1413" (or "the game gives no position here").
- `C_Texture` in `.luacheckrc` and `.luarc.json`.

## Task 3: `MapEntrances.lua`, the switch, `Core.lua`

- `Features.LIST`: `mapEntrances`, "Dungeon and raid entrances on the map", Map, check, default
  true, after `mapSkins`. `Look.COLOUR.dungeon` and `.raid` for the fallback squares.
- `MapEntrances.Create(core)` / `.Built()`, as `MapReadout`'s. A driver frame on the canvas
  container runs `update` each frame the map is shown; pins are plain frames on the canvas,
  placed as Blizzard's `ApplyPinPosition` does (scale `1 / canvas scale`, offset divided by it),
  redrawn when the map, the switch, the canvas scale or its size changes.
- A pin takes hover only (`SetMouseClickEnabled(false)`); hovering opens a card in `Look.Frame`
  listing its rows, flipped left or down near the map's right or top edge.
- TOC after `MapReadout.lua`; `test/run.lua`'s module list; `Core` builds it at login and at
  `Blizzard_WorldMap`'s load.

## Task 4: the paperwork

README row, `docs/manual-test-checklist.md` section, CLAUDE.md (docs list, the art rule's
exception, load order, How it fits together, Client facts for the three 2026-11-19 reads).
