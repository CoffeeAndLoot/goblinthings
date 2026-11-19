local _, ns = ...

-- Where the dungeon and raid doors are (spec 2026-11-19-map-entrance-pins-
-- design.md): a hand-kept table by UiMap ID, and the pins a map gets from it.
-- The game has no entrance data on Forever (seen in game 2026-11-19:
-- C_EncounterJournal.GetDungeonEntrancesForMap answers with nothing), so the
-- addon keeps its own. Pure: test/run.lua loads this file.
local MapPins = {}
ns.MapPins = MapPins

-- { map, x, y, kind, name, low, high }, or { map, x, y, kind, name, words }
-- for a door with no levels to give (a raid not yet open): x and y in map percent, as Wowhead's
-- /way gives them on the door's own zone or city map. A door goes in only
-- once a source for Forever gives its spot: never a guessed one. The Classic
-- dungeons are from Wowhead's Forever dungeon guide (updated 2026-11-15); the
-- new ones, which that guide leaves blank, from other sites' Forever guides
-- (read 2026-11-19; "others'" below), none yet seen on its door by the owner.
-- Still to come, each read off the door (/gt probe prints the spot):
-- Excavation Site (the guides give 48.1, 56.5 and 53.4, 65.3 in Wetlands and
-- disagree which is the door), and the raids Barrow Deeps, Hyjal Summit and
-- Onyxia's Lair (2026-12-09; no Forever source has a spot).
-- The raids. Onyxia's Lair opens 2026-12-09; its spot is a Forever map
-- site's and a guide's. The other Classic raids are in Wowhead's Forever
-- database but Blizzard has announced none of them for Forever (2026-11-19);
-- the owner wants them pinned all the same, at Classic's spots, the zones
-- not having moved, and the card says so. Molten Core is entered through
-- Blackrock Depths and Blackwing Lair through Upper Blackrock Spire, so both
-- share Blackrock Mountain's spot. Both Ahn'Qiraj raids wait for a spot (no
-- guide gives one), as do Barrow Deeps and Hyjal Summit.
local D, R = "dungeon", "raid"
local UNANNOUNCED = "Raid, not announced"
MapPins.ENTRANCES = {
    { 1454, 52.0, 49.0, D, "Ragefire Chasm", 13, 18 },            -- Orgrimmar
    { 1455, 43.5, 52.0, D, "The Hall of Thanes", 13, 18 },        -- Ironforge; others', several agree
    { 1458, 71.6, 11.4, D, "Ruins of Lordaeron", 15, 20 },        -- Undercity; others', several agree
    { 1420, 61.9, 64.7, D, "Ruins of Lordaeron", 15, 20 },        -- Tirisfal Glades; others', one source
    { 1413, 45.5, 35.5, D, "Wailing Caverns", 15, 25 },           -- The Barrens
    { 1436, 42.4, 70.4, D, "The Deadmines", 18, 23 },             -- Westfall
    { 1421, 42.6, 66.6, D, "Shadowfang Keep", 22, 30 },           -- Silverpine Forest
    { 1453, 41.0, 57.0, D, "The Stockade", 22, 30 },              -- Stormwind City
    { 1440, 13.4, 12.8, D, "Blackfathom Deeps", 24, 32 },         -- Ashenvale
    { 1416, 8.8, 59.6, D, "City of Dalaran", 28, 33 },            -- Alterac Mountains; others', several agree
    { 1420, 83.5, 32.0, D, "Scarlet Monastery", 28, 45 },         -- Tirisfal Glades
    { 1426, 30.5, 36.3, D, "Gnomeregan", 29, 38 },                -- Dun Morogh
    { 1413, 42.6, 88.5, D, "Razorfen Kraul", 30, 40 },            -- The Barrens
    { 1413, 50.0, 92.0, D, "Razorfen Downs", 40, 50 },            -- The Barrens
    { 1434, 21.4, 27.9, D, "The Drowned City", 35, 40 },          -- Stranglethorn Vale; others', underwater
    { 2548, 37.5, 37.5, D, "Krol'dok Stronghold", 40, 45 },       -- Riverglades; others', several near agree
    { 1418, 42.6, 10.8, D, "Uldaman", 42, 52 },                   -- Badlands
    { 1446, 39.5, 21.3, D, "Zul'Farrak", 44, 54 },                -- Tanaris
    { 1443, 29.5, 57.8, D, "Maraudon", 45, 57 },                  -- Desolace
    { 1445, 75.3, 14.1, D, "Alcaz Prison", 48, 53 },              -- Dustwallow Marsh; others', several near agree
    { 1435, 69.6, 53.2, D, "Temple of Atal'Hakkar", 50, 60 },     -- Swamp of Sorrows
    { 1427, 35.2, 84.2, D, "Blackrock Depths", 52, 60 },          -- Searing Gorge
    { 1447, 38.7, 33.4, D, "Blackmaw Hold", 55, 60 },             -- Azshara; others', the tunnel's mouth
    { 1427, 35.2, 84.2, D, "Lower Blackrock Spire", 55, 60 },     -- Searing Gorge
    { 1427, 35.2, 84.2, D, "Upper Blackrock Spire", 58, 60 },     -- Searing Gorge
    { 1449, 48.1, 6.1, D, "Shaper's Terrace", 58, 60 },           -- Un'Goro Crater; others', one source
    { 1445, 52.3, 76.1, R, "Onyxia's Lair" },                     -- Dustwallow Marsh; others', two agree
    { 1434, 53.9, 17.6, R, "Zul'Gurub", UNANNOUNCED },            -- Stranglethorn Vale; Classic's, a guide's 53, 17
    { 1423, 39.0, 26.0, R, "Naxxramas", UNANNOUNCED },            -- Eastern Plaguelands; Classic's, one guide
    { 1427, 35.2, 84.2, R, "Molten Core", UNANNOUNCED },          -- Searing Gorge; through Blackrock Depths
    { 1427, 35.2, 84.2, R, "Blackwing Lair", UNANNOUNCED },       -- Searing Gorge; through Upper Blackrock Spire
    { 1444, 58.9, 41.5, D, "Dire Maul", 58, 60 },                 -- Feralas
    { 1422, 69.8, 76.0, D, "Scholomance", 58, 60 },               -- Western Plaguelands
    { 1423, 30.9, 15.2, D, "Stratholme: Living Side", 58, 60 },   -- Eastern Plaguelands
    { 1423, 48.3, 21.8, D, "Stratholme: Undead Side", 58, 60 },   -- Eastern Plaguelands
}

local function percent(n)
    return type(n) == "number" and n >= 0 and n <= 100
end

-- What a row says after the name: the row's own words, "13-18", "60", "Raid"
-- for a raid with no levels, else nothing.
local function levels(kind, low, high)
    if type(low) == "string" then
        return low
    end
    if type(low) == "number" and type(high) == "number" then
        return low == high and tostring(low) or (low .. "-" .. high)
    end
    return kind == "raid" and "Raid" or ""
end

-- The pins of a map, in the table's order: { x =, y = (0-1 across and down
-- the map), kind = "dungeon" | "raid", rows = { { name, levels } ... } }.
-- Doors on one spot share a pin (Blackrock Mountain's three), green only when
-- every one is a raid. A malformed row is left out; a map with no doors, or
-- no map, gives an empty list. entrances: a table in ENTRANCES' place (tests).
function MapPins.For(mapID, entrances)
    local pins, bySpot = {}, {}
    entrances = entrances or MapPins.ENTRANCES
    if type(mapID) ~= "number" or type(entrances) ~= "table" then
        return pins
    end
    for i = 1, #entrances do
        local row = entrances[i]
        if type(row) == "table" and row[1] == mapID and percent(row[2]) and percent(row[3])
            and (row[4] == "dungeon" or row[4] == "raid") and type(row[5]) == "string" then
            local spot = row[2] .. " " .. row[3]
            local pin = bySpot[spot]
            if not pin then
                pin = { x = row[2] / 100, y = row[3] / 100, kind = row[4], rows = {} }
                bySpot[spot] = pin
                pins[#pins + 1] = pin
            elseif row[4] == "dungeon" then
                pin.kind = "dungeon"
            end
            pin.rows[#pin.rows + 1] = { row[5], levels(row[4], row[6], row[7]) }
        end
    end
    return pins
end

return MapPins
