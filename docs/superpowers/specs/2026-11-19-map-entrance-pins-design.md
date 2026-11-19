# Dungeon and raid entrances on the world map

2026-11-19. Short design: one switch, one table, one drawing file.

## Intent

The owner wants to open a zone's map and see where its dungeons and raids are: the game's blue
swirl at each dungeon door, the green swirl at each raid door, upcoming raids included.

## What the game gives (seen in game, 2026-11-19, the owner's `/run` lines)

- `C_CVar.GetCVar("showDungeonEntrancesOnMap")` reads `1`: Blizzard's own entrance pins are on.
- `#C_EncounterJournal.GetDungeonEntrancesForMap(1413)` reads `0` on the Barrens: the game has no
  entrance data on Forever, so its pins never draw. A switch for the CVar would do nothing.
- `C_Texture.GetAtlasInfo("Dungeon")` and `("Raid")` both answer: the two swirls ship with the
  client (Forever's own `Camelot/MapLegendFrameData.lua` lists them).

## Goals

- A swirl at every entrance whose spot is known, on that entrance's own zone or city map.
- Hovering a swirl names what is behind the door and its level range.
- One switch on the Map tab, `mapEntrances`, "Dungeon and raid entrances on the map", default on.

## Non-goals

- Continent and world maps: the owner chose zone maps only.
- The minimap, waypoints, click actions, a dungeon journal.
- A pin for a door whose spot is not known. No guessed coordinates, ever.

## Approaches

1. **Plain frames on the map canvas (chosen).** As `MapReadout` already sits there. No Blizzard
   template, nothing of theirs to break.
2. **Blizzard's pin system (a data provider and an XML pin template), as HandyNotes does.** Free
   scaling and overlap handling, but it needs their templates and mixins, which the rules forbid,
   and risks taint on the map. Rejected.
3. **A switch for the game's own pins.** Ruled out by the in-game reads above.

The table is hand-kept in the pure module, like `MapInfo.LEVELS`: about forty rows from one guide
page do not earn a generator.

## Design

- **`MapPins.lua` (pure, new, in the TOC before `Look`; needs a full client restart).**
  - `MapPins.ENTRANCES`: rows `{ map = UiMap ID, x =, y =, kind = "dungeon" | "raid", name =,
    low =, high = }`, x and y in map percent as Wowhead's `/way` gives them. `low`/`high` may be
    nil (a raid).
  - `MapPins.For(mapID)`: the pins for a map, each `{ x, y, kind, rows = { { name, levels } ... } }`
    with x and y as 0-1 fractions. Rows at the same spot on the same map merge into one pin
    (Blackrock Mountain's three); the pin is a raid's green only when every row is a raid. A
    malformed row is dropped, never an error. Unknown map: an empty list.
- **`MapEntrances.lua` (draws, decides nothing; new, after `MapReadout`).** A pool of small frames
  parented to the map canvas, placed at each pin's fraction of the canvas, redrawn when the shown
  map changes or the switch flips. Hover opens a small card in the game's look (`Look.COLOUR`)
  listing the pin's rows. Pins take hover only and let clicks through
  (`SetMouseClickEnabled(false)`), so right-click zoom-out still works over one.
- **`API.EntranceIcon(kind)`**: the atlas name `Dungeon` or `Raid` when
  `C_Texture.GetAtlasInfo` answers for it, else nil; the pin then draws a coloured square (blue or
  green from `Look.COLOUR`), as the readout's letter squares do.
- **The rule's exception.** These two atlases are the only Blizzard art the addon uses; CLAUDE.md's
  "no Blizzard art files" rule gets that exception written in, with the date and the in-game read.
- **`/gt probe`** gains two lines: the two atlas answers, and the player's map ID and position
  (`C_Map.GetBestMapForUnit`, `C_Map.GetPlayerMapPosition`), so the owner can stand at a door and
  read out a missing spot.

## The table at first build

From Wowhead's Forever dungeon guide (updated 2026-11-15), zone map and `/way` as given:

| Map | Spot | Entrance | Levels |
|---|---|---|---|
| Orgrimmar 1454 | 52.0, 49.0 | Ragefire Chasm | 13-18 |
| Ironforge 1455 | 43, 51 | The Hall of Thanes (a reader's comment; unchecked) | 13-18 |
| The Barrens 1413 | 45.5, 35.5 | Wailing Caverns | 15-25 |
| Westfall 1436 | 42.4, 70.4 | The Deadmines | 18-23 |
| Silverpine Forest 1421 | 42.6, 66.6 | Shadowfang Keep | 22-30 |
| Stormwind City 1453 | 41.0, 57.0 | The Stockade | 22-30 |
| Ashenvale 1440 | 13.4, 12.8 | Blackfathom Deeps | 24-32 |
| Tirisfal Glades 1420 | 83.5, 32.0 | Scarlet Monastery | 28-45 |
| Dun Morogh 1426 | 30.5, 36.3 | Gnomeregan | 29-38 |
| The Barrens 1413 | 42.6, 88.5 | Razorfen Kraul | 30-40 |
| The Barrens 1413 | 50.0, 92.0 | Razorfen Downs | 40-50 |
| Badlands 1418 | 42.6, 10.8 | Uldaman | 42-52 |
| Tanaris 1446 | 39.5, 21.3 | Zul'Farrak | 44-54 |
| Desolace 1443 | 29.5, 57.8 | Maraudon | 45-57 |
| Swamp of Sorrows 1435 | 69.6, 53.2 | Temple of Atal'Hakkar | 50-60 |
| Searing Gorge 1427 | 35.2, 84.2 | Blackrock Depths | 52-60 |
| Searing Gorge 1427 | 35.2, 84.2 | Lower Blackrock Spire | 55-60 |
| Searing Gorge 1427 | 35.2, 84.2 | Upper Blackrock Spire | 58-60 |
| Feralas 1444 | 58.9, 41.5 | Dire Maul | 58-60 |
| Western Plaguelands 1422 | 69.8, 76.0 | Scholomance | 58-60 |
| Eastern Plaguelands 1423 | 30.9, 15.2 | Stratholme: Living Side | 58-60 |
| Eastern Plaguelands 1423 | 48.3, 21.8 | Stratholme: Undead Side | 58-60 |

**No pin until the owner reads out the spot** (the guide has none): Ruins of Lordaeron, Excavation
Site, City of Dalaran, The Drowned City, Krol'dok Stronghold, Alcaz Prison, Blackmaw Hold, Shaper's
Terrace; the raids Barrow Deeps, Hyjal Summit and Onyxia's Lair (all three due 2026-12-09, per
Wowhead's roadmap). The 2027 raids are not yet named. Onyxia's Classic spot is not copied in: no
source for Forever has it, and the owner can read it off the door.

## Left to the builder

- Pin size, and whether pins hold their size as the map zooms (the canvas scales its children;
  Blizzard's pins counter it). Pick the simpler one that looks right; it is a checklist item.
- How the redraw is triggered (the readout already checks the shown map each frame).
- Frame level against the readout card and Blizzard's own pins.

## Checks

Pure tests for `MapPins.For` (merge, kind of a merged pin, bad rows, unknown map, fractions).
In game, added to `docs/manual-test-checklist.md`: a blue swirl at each of the Barrens' three;
hover names and levels; one merged pin at Blackrock Mountain listing three; no swirl on Kalimdor's
map; the switch off removes them; right-click over a pin still zooms out; the probe's position line.
The README's table gains the switch's row; the Wago description is edited by hand at release.
