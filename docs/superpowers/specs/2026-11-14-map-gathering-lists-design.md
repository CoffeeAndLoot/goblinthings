# Herbs, ore and fish on the world map

2026-11-14. The owner asked: "can we also add what fish are found in each zone? ... can we also add
other herbs, skins, ore, etc as options?" It extends the corner readout of
`2026-11-10-map-zone-readout-design.md`. Choices the owner made are marked **(owner)**; the rest are
Claude's calls, stated so the owner can overturn them.

## Why

The corner already says whether a zone suits your level and your fishing skill. A gatherer asks the
same of herbs and ore ("is this zone worth my time, and what will I find?") and today has to leave
the game to answer it.

## What it does

On a zone's own map the corner grows from three lines to five, each gathering line ending in a small
profession icon:

```
                          The Barrens
                         Levels 10-25
     Fishing 1 (no getaways at 75) [F]
                      Herbs 1-125 [H]
                         Ore 1-75 [O]
```

- **Herbs** and **Ore** lines **(owner: layout B of the mockup)**: the lowest and highest skill among
  that zone's nodes. One number when they are equal (`Ore 1`), as the level line does.
- **Hovering an icon** **(owner)** opens a list above the corner in the Goblin look:
  - Herbalism and Mining: each node's name and the skill to gather it, easiest first, ties by name.
  - Fishing: each catch's name and its share of the zone's catch as a whole percent, most common
    first, then one dim footnote: `Classic figures, not checked on Forever`.
- **A zone's own map only** **(owner)**: the icons are drawn only when the readout describes the map
  that is open. On a continent the cursor would cross other zones on its way to the corner, so the
  icons could never be reached for the zone you meant.
- On a continent, hovering a zone shows the Herbs and Ore **text** lines with no icons: the text is
  harmless and answers the "worth my time" question from the continent view.
- A zone with no herbs, or no ore, or no fish list has no such line or icon. A city shown on its
  zone's map has none.
- The fish icon lives on the Fishing line, so a zone with no Fishing line (Badlands, Searing Gorge,
  Blasted Lands have no fishing skill in `MapInfo.FISHING`) shows no fish list even if Wowhead has
  one; the script leaves those out of `FISH`.
- **No skins** **(owner)**: Wowhead has no skinning list per zone, and working leather out from beast
  levels is an estimate, not data.

## Switches

Three check boxes on the **Map** tab under "Zone levels and fishing on the map", **on by default**
(they only read):

| Key | Label | Off means |
|---|---|---|
| `mapHerbs` | Herbs on the map | no Herbs line or icon |
| `mapOre` | Ore on the map | no Ore line or icon |
| `mapFish` | Fish list on the map | no icon on the Fishing line; the line stays |

All three do nothing while `mapInfo` is off. The Map tab's note becomes
"Read a zone at the world map's bottom right; open the zone for its lists".

## The data

The client cannot say what grows in a zone (as with the fishing skill, the server holds it), so the
lists ship with the addon.

- **Source**: Wowhead's Classic zone pages (`wowhead.com/classic/zone=<area id>`), read 2026-11-14 for
  the Barrens to confirm the shape. Each page embeds its lists as JSON:
  - `objects`: every object in the zone with `name`, `type` and `skill`. `type == -3` is a herb,
    `-4` a mining node. A name appears once per object ID (three "Copper Vein" rows in the Barrens),
    so rows are de-duplicated by name, keeping the lowest skill. `location` holds only the object's
    three busiest zones and a `-1` for "more", so it cannot be used to filter: the page listing the
    object is the fact that it is in the zone.
  - `fishing`: every item ever fished there with `id`, `name` and `count`.
- **Fish filter**: a row's share is its `count` over the sum of all the page's counts. Keep rows at 3%
  or more, the eight largest at most. In the Barrens that keeps exactly the seven real catches (Oily
  Blackmouth 41%, Longjaw Mud Snapper 16%, Slitherskin Mackerel 13%, Rainbow Fin Albacore 10%,
  Stranglekelp 6%, Bristle Whisker Catfish 6%, Brilliant Smallfish 4%) and drops the gear, potions
  and crates. The share alone is not enough elsewhere (Darkshore's quest item Gaffer Jack is 16% of
  its catch, Hillsbrad's Watertight Trunk 25%), so a row must also be of an item class a fisher
  means by a catch: meat, herbs, clams, reagents (Oily Blackmouth, the eels) or food and drink. A page whose counts sum to under 100 gives no fish list: too few
  casts to trust.
- **Generated, never hand-edited**, as the art is, in two steps because Wowhead refuses a plain
  script (HTTP 403 to Python on 2026-11-14) and serves a browser:
  - `tools/gathering/wowhead-classic.json` is the **source**, as `tools/art/*.png` are: per zone, the
    page's title, its herb and ore rows (name, skill) and its fishing rows (item ID, name, count) with
    the sum of all counts. It is read out of the pages in a browser, one page at a time with a pause,
    sending nothing about the owner. The file records the day it was read.
  - `python tools/make_gathering.py` turns that source into `GoblinThings/MapData.lua`, applying the
    de-duplication, the fish filter and the sorting. It holds the one hand-kept table, UiMap ID to
    Wowhead area ID (the Barrens: 1413 to 17), for every zone in `MapInfo.LEVELS` that Wowhead Classic
    has, each with the zone's name.
  - **It fails loudly, writing nothing**, when: a zone in its table is missing from the source; a
    page's title does not start with the zone's name; a zone has no `objects` list at all (every zone
    page has one; `fishing` is allowed to be absent, a landlocked zone has none); or fewer than 25
    zones yield herbs, 25 yield ore or 20 yield fish (a changed page layout would empty them all).
- **Node names are checked against Classic's**: Wowhead types quest objects as herbs and veins
  (Darkshore's Beached Sea Creature) and its Classic pages carry other seasons' nodes, so the script
  keeps a hand-kept list of Classic herb and vein names, folds an "Ooze Covered" vein into its plain
  one, and prints every name it drops. Dropped on 2026-11-14: Beached Sea Creature, Cold Iron
  Deposit, Doom Weed, Dreamroot, Fool's Gold Vein, Gloom Weed, Greater Moonstone Formation, Incendia
  Agave, Moonroot, Nightmare Moss, Skeletal Sea Turtle. If Forever has any of those as real nodes,
  add the name to the script's list.
- **Not read yet**: Wowhead asked for human verification after 32 of the 40 pages. Swamp of
  Sorrows, The Hinterlands, Searing Gorge, Blasted Lands, Burning Steppes, Western and Eastern
  Plaguelands and Deadwind Pass are in the script's `PENDING` set and get no lists until read. The
  three spell pages were not reached either, so the icons' spell IDs are from memory.
- **Not in the data**: Mount Hyjal and Riverglades are Forever's own and Wowhead Classic does not have
  them, so they get no gathering lines.
- **English names**: node and fish names are Wowhead's English, not the client's language.
- **Standing**: Classic Era figures, **unverified on Forever**. The checklist asks the owner to
  compare one zone's herbs, ore and fish against what is seen in game.
- **Known weak spot**: a zone page lists a node however rare it is there (the Barrens lists Grave
  Moss and Wild Steelbloom). The page gives no per-zone count to cut strays with. Accepted for now;
  if a list reads wrong in game, the fix is a per-zone drop list in the script, not an edit to the
  generated file.

## How it fits (verified in source where said; nothing yet in game)

- `MapData.lua` (new, generated, pure): `ns.MapData = { HERBS = { [uiMapID] = { { "Peacebloom", 1 },
  ... } }, ORE = { ... }, FISH = { [uiMapID] = { { "Oily Blackmouth", 41 }, ... } } }`, each list
  already filtered and sorted by the script. **A new TOC file: a full client restart, not `/reload`.**
  It loads before `MapInfo`, and `test/run.lua`'s hand-kept module list gains it.
- `MapInfo.lua` (pure, tested) grows; it reads `ns.MapData` inside its functions, never at file load:
  - `known(mapID)` also counts a zone that has only gathering data.
  - `Lines(mapID, name, settings)` returns the lines as before plus, per switch, the Herbs and Ore
    lines; each line now says which list it carries (`fish`, `herbs`, `ore` or none) so the readout
    knows where an icon goes.
  - `List(kind, mapID)` returns the title, the rows as `{ left, right }` text pairs and the optional
    footnote: everything the tooltip prints, so the readout decides nothing.
- `MapReadout.lua`:
  - Five lines instead of three (`LAYOUT.SIZES` gains two 13s).
  - Each line can show a 14 px icon at its right end; the text is inset to make room. The readout
    frame itself stays mouse-off so the canvas keeps its hover; **only the icons take the mouse**.
    Icons are shown only when the picked map is the shown map.
  - One list frame, built once in the Goblin look (`Look.COLOUR.window` fill, `line` border, gold
    title, dim right column and footnote; no `GameTooltip`, no Blizzard template), anchored above the
    corner, shown on an icon's `OnEnter`, hidden on `OnLeave` and when the map hides.
  - The redraw key becomes the picked map plus whether icons show plus the three switches, so
    flipping a switch with the map open redraws.
  - While the cursor is on an icon it is off the canvas, so `API.MapUnderCursor` reports no hovered
    child and the pick stays the shown map: the list cannot flicker away under the cursor. This is
    from reading `IsCanvasMouseFocusOrPinFocus`, not from the game; the checklist covers it.
- **Icons**: the game's own profession icons, in one pass. `API.ProfessionIcon(kind)` asks
  `C_Spell.GetSpellTexture` (`SpellDocumentation.lua`: returns nothing for an unknown spell) for the
  profession's Apprentice spell: Herbalism 2366, Mining 2575, Fishing 7620, IDs from memory, not yet checked
  against anything (see "Not read yet"). The texture names themselves are
  not in the Blizzard addon source, so none is written down. Whenever the game gives no texture the
  icon is a Goblin-look square with the letter H, O or F, so a list is always reachable; `/gt probe`
  says which of the three the game answered, and the checklist has the owner look at them.
- `Features.LIST` gains the three switches (section `Map`); `Options.Init` stores their defaults.
- Tests: `MapInfo`'s new lines and lists against a small fake `MapData`; a data test that every
  shipped list is non-empty, sorted as promised and keyed by a zone `MapInfo` knows.
- Docs: README table rows for the three switches, `CLAUDE.md` (load order, item 6, the art rule's
  sibling for `make_gathering.py`), `docs/manual-test-checklist.md` entries, and at the next release
  the Wago description by hand.

## Amendment, 2026-11-14: Wowhead's Forever database

Found after the first build: Wowhead has a **Forever** section (`wowhead.com/forever/zone=<area id>`)
with the same lists. It is Forever's own data, so it replaces Classic's as the authority, and what is
said above changes as follows.

- **Two sources.** `tools/gathering/wowhead-forever.json` (42 zones; Wowhead asks for human
  verification about every 28 pages, even at 5 seconds a page) and `wowhead-classic.json` (32 zones). Per zone the
  script takes herbs and ore from Forever's page, else Classic's; and fish from Forever's when its
  whole catch is 100 or more, else Classic's on the same rule. Forever is young, so its high zones
  have few casts (Felwood 18, Winterspring 28, Silithus 3): those fish lists are Classic's.
- **The footnote marks the source, not the kind.** `MapData.CLASSIC_NODES` and `CLASSIC_FISH` name the
  zones whose lists are Classic's; only those lists carry "Classic figures, not checked on Forever".
  A Forever list has no footnote. On 2026-11-14: nodes for Alterac, Arathi, Badlands and
  Stranglethorn; fish for Alterac, Arathi, Stranglethorn, Felwood, Silithus and Winterspring.
- **Node names: known, quest object, or stop.** Forever's pages carry nodes Classic Era lacks, each
  with a real skill, so they are kept: Wilted Peacebloom, Stunted Silverleaf, Poor Copper Vein,
  Chunk of Amber and Large Chunk of Amber (Teldrassil), Dreamroot, Moonroot, Nightmare Moss, Fool's
  Gold Vein, Cold Iron Deposit, Greater Moonstone Formation. The first build dropped six of those
  as "not Classic"; that was wrong for Forever. Quest objects are dropped by name (Beached Sea
  Creature, Skeletal Sea Turtle, Incendia Agave, Gloom Weed, Doom Weed, Tomb Weed, Serpentbloom).
  A name in neither list stops the script, so a new one is a person's decision.
- **Fish classes.** Forever files Oily Blackmouth, the eels and clams under trade goods "other"
  (7.11), so that class is kept too.
- **All 42 zones read** (the owner passed Wowhead's check twice): the 40 Classic zones plus Mount
  Hyjal (area 616) and Riverglades (area 16591), which only Forever's database has. Herbs and ore
  are Forever's for every zone; `CLASSIC_NODES` is empty. Fish are Classic's for Felwood, Silithus
  and Winterspring only. More Forever nodes kept: Star Lotus and Starsilver Vein (The Hinterlands),
  Demonsage and Heavy Thorium Vein (Mount Hyjal); more quest objects dropped: Violet Tragan, Hyjal
  Silphium (skill 1 in a level 60 zone: Claude's guess that it is a quest object).
- **Forever's new zones** (the owner: "add in the new zones data"). Zephras Isle (UiMap 2521, area
  16593) and Shen'dralas (UiMap 2652, area 16651) join Mount Hyjal and Riverglades; the UiMap IDs
  are from GoblinPS's client export (`docs/research/data/UiMap.csv`). `MapInfo.LEVELS` gains Zephras
  Isle 1-12 and Riverglades changes from 35-45 to 36-44, both Wowhead's Forever figures. Wowhead
  gives Shen'dralas and Mount Hyjal no level range. Darkspear Islands (area 16606) has no objects
  or fishing list on its page and is left out.
- **A fish list no longer needs a fishing skill.** Riverglades (4,478 casts) and Zephras Isle
  (14,709) have catches and no known skill, so with "Fish list on the map" on they get a bare
  "Fishing" line carrying the icon. This overturns "a zone with no Fishing line shows no fish
  list" above. No skill was guessed for either.
- **A zone known only by its lists** (Shen'dralas) counts as known only while one of those lists'
  switches is on: `MapInfo.Pick` and `Lines` take the switches, so it never shows a bare name and
  is never picked over the map it sits on when it has nothing to say.
- **Still missing**: fish for Un'Goro, Eastern Plaguelands, Burning Steppes and Deadwind Pass (too
  few catches in both sources); fishing skills for Riverglades and Zephras Isle.
- **Other sources looked at**: LibTourist Classic Era (MIT) holds zones, flight points and fishing
  skill only, no nodes; its fishing skills agree with `MapInfo.FISHING` on the 19 zones compared.
  GatherMate2's Classic data states no licence. ItemTree_Data is All Rights Reserved.

## Amendment, 2026-11-14: skins

The owner, a skinner: "i am interested in the types of skin i find in each zone, light, medium,
heavy, rugged, the different types oh hides, devilsaur leather, etc." "No skins" above is overturned:
Wowhead's zone pages have no skinning list, but each leather's **item** page has a "skinned from"
list of creatures with their zones and how often each was skinned. That is data, not an estimate.

- **What shows**: a sixth line, "Skins: Light, Medium", naming the leather grades (Ruined, Light,
  Medium, Heavy, Thick, Rugged, lowest first) that are a tenth or more of the zone's skins; a bare
  "Skins" when none is (Silithus is all chitin). On the zone's own map it ends in an icon whose list,
  "Skinning", reads every type and its share of the zone's skins, most common first; a rare one
  reads "<1%". A fourth switch, "Skins on the map" (`mapSkins`), on by default.
- **Source**: `tools/gathering/wowhead-forever-skins.json`. The item list is Wowhead's own
  (`/forever/items/trade-goods/leather`, the items it marks as skinned), not memory: 37 read. Per
  item, per zone: creatures, skins, lowest and highest creature level.
- **Rules** (Claude's calls): a creature counts for the first zone Wowhead lists it in (it gives up
  to three and one total, so counting all would hand Silverpine Hillsbrad's turtles). A zone's row
  whose lowest creature is level 63 or more is a raid boss and is dropped (Duskwood's Dreamscale).
  The eleven everyday leathers and hides need 2% of the zone's skins to be listed; anything else
  (Devilsaur Leather, a scale, a special hide) is listed however rare, from five skins up. Ten rows
  at most. A zone with under 100 skins recorded gets no list.
- **Levels and skill are not shown.** Wowhead gives creature levels, not the skill to skin them, and
  the level spans are thrown wide by rares and bosses. The owner asked for types.
- **All of Wowhead's skinned items are read** (37): the last five after the owner passed its check
  again. Pristine Leather, Pristine Hide and Pristine Scale are Forever's own: a rare extra skin
  off ordinary beasts in most zones, so they show in most lists at a percent or two. Irradiated
  Leather Scraps' page has no lists at all and is left out.
- **The icon**: `API.ProfessionIcon("skins")` asks for spell 8613's texture (from memory, like the
  other three); the letter is S.

## Not doing

Skins. Colouring a row by the player's own skill. Node positions or map pins. Icons on the continent
view. Subzone or dungeon lists. Translating names. Fishing pools as their own list. All possible
later.

## Left to the builder

- The UiMap to Wowhead area ID table: from the client's own data or Wowhead's zone list, each one
  checked by the page's title matching the zone's name.
- Exact pixel offsets of the icons and the list frame, within the Goblin look.
