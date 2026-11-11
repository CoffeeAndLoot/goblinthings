# World map zone readout

2026-11-10. The owner asked for it ("that way you could tell what's in what area and what's needed
if you just want to use the map") and chose to skip the design questions, so every choice below is
Claude's call, stated so the owner can overturn it.

## What it does

With the world map open, the bottom-right corner of the map shows, in the map's own lettering:

```
                    The Barrens
                   Levels 10-25
      Fishing 1 (no getaways at 75)
```

- **Continent view** (Kalimdor, Eastern Kingdoms): the zone under the cursor. Nothing when the
  cursor is off the map or over the sea.
- **A zone's own map**: that zone, all the time, no hover needed. A city drawn inside the zone's map
  (Orgrimmar on Durotar's) shows the city while the cursor is on it.
- A line the addon has no data for is left out; a map it knows nothing about shows nothing.

## Choices (Claude's call)

- **A switch**, "Zone levels and fishing on the map", on a new **Map** tab, **on by default**: it
  only reads, never changes anything, and a fresh install should show it. The window widens from 520
  to 600 so seven tabs keep their 82 px each.
- **Where**: anchored to the map canvas's bottom-right, 40 px in from the right so it clears the
  quest-log toggle Blizzard puts in that corner (32 px at -2, 1; `Blizzard_WorldMap.lua:337`).
- **Style**: Friz Quadrata with an outline, as the map's own area label (`WorldMapTextFont`,
  `SubZoneTextFont` are thick-outlined Friz). The name in the label's colour
  (`AREA_NAME_FONT_COLOR`, 1.0 / 0.9294 / 0.7607), the lines in white
  (`AREA_DESCRIPTION_FONT_COLOR` is `HIGHLIGHT_FONT_COLOR`). Both live in `Look.COLOUR` like
  every other colour. No textures, no backdrop.
- **Level ranges**: hand-written, copied (not shared) from GoblinPS's `Data/Zones.lua`. Classic
  ranges, with Forever's Mount Hyjal and Riverglades. `C_Map.GetMapLevels` is not used: it exists on
  this build and answers for no zone (GoblinPS, verified in game), which is also why Blizzard's own
  hover label shows only the name. `AreaTable.ContentTuningID` is 0 for these zones on 70862.
- **Fishing skill**: hand-written Classic values. The client's data has no fishing column
  (`AreaTable` on wago.tools for 1.60.1.70862: none), because in Classic the server holds it. Two
  numbers per zone: the skill to fish there at all and the skill at which nothing gets away
  (that skill + 95). Source: Blizzard Watch's Classic fishing guide (2019-09-16) for the first four
  tiers, Warcraft Tavern's Fishing 1-300 guide for the fifth (330 / 425). Where they disagree (the
  starter zones' "no getaways" 25 vs 96) Blizzard Watch's split wins: it keeps the two first tiers
  apart (25 and 75) as the -70 / -20 zone bases do. **Unverified on Forever**: Forever may have
  changed fishing; the checklist asks the owner to compare one zone. Subzones with their own skill
  (Jaguero Isle, Bay of Storms, Jademir Lake) are not shown: the readout is per zone.
- **Zones without data**: Badlands, Searing Gorge and Blasted Lands have levels but no fishing line;
  the cities have fishing but no levels; Shen'dralas and Zephras Isle show nothing.

## How it works (verified in source, 1.60.1.70862; not yet in game)

Blizzard's area label (`Blizzard_SharedMapDataProviders/AreaLabelDataProvider.lua`) finds the zone
under the cursor every frame with `map:IsCanvasMouseFocus()`, `map:GetNormalizedCursorPosition()`
and `C_Map.GetMapInfoAtPosition(map:GetMapID(), x, y)`, treating an answer whose `mapID` differs
from the shown map as the hovered child. The readout does the same, with
`map:IsCanvasMouseFocusOrPinFocus()` in place of the first so a flight point or quest pin under the
cursor keeps its zone shown:

- `MapInfo.lua` (pure, tested): the two tables, `Pick(shown, hovered)` and `Lines(mapID, name)`.
- `API.MapUnderCursor(map)` makes those calls through `call()`, and counts how often it asked and how
  often a map came back; `/gt probe` prints both and says plainly when nothing ever answered.
- `MapReadout.lua` builds three outlined FontStrings on a frame parented to
  `WorldMapFrame:GetCanvasContainer()` at strata HIGH (as the area label is), mouse off so the
  canvas keeps its hover. An `OnUpdate` on that frame (it only runs while the map is shown) asks
  each frame and redraws only when the picked map changes. `WorldMapFrame` loads at startup (its TOC
  is not load-on-demand); if it is missing at login, the readout is built on `ADDON_LOADED` for
  `Blizzard_WorldMap`.

## Not doing

Colouring the range by the player's level (Blizzard's label would, if `GetMapLevels` answered),
showing the player's own fishing skill, dungeon maps, the battlefield minimap. All easy later.
