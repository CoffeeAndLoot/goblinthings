local _, ns = ...

-- Where the dungeon and raid doors are (spec 2026-11-19-map-entrance-pins-
-- design.md): a hand-kept table by UiMap ID, and the pins a map gets from it.
-- The game has no entrance data on Forever (seen in game 2026-11-19:
-- C_EncounterJournal.GetDungeonEntrancesForMap answers with nothing), so the
-- addon keeps its own. Pure: test/run.lua loads this file.
local MapPins = {}
ns.MapPins = MapPins

-- { map, x, y, kind, name, low, high }: x and y in map percent, as Wowhead's
-- /way gives them on the door's own zone or city map. From Wowhead's Forever
-- dungeon guide (updated 2026-11-15). A door goes in only once its spot is
-- known: never a guessed one. Still to come, each read off the door by the
-- owner (/gt probe prints the spot): Ruins of Lordaeron, Excavation Site, City
-- of Dalaran, The Drowned City, Krol'dok Stronghold, Alcaz Prison, Blackmaw
-- Hold, Shaper's Terrace, and the raids Barrow Deeps, Hyjal Summit and
-- Onyxia's Lair (2026-12-09).
local D = "dungeon"
MapPins.ENTRANCES = {
    { 1454, 52.0, 49.0, D, "Ragefire Chasm", 13, 18 },            -- Orgrimmar
    { 1455, 43.0, 51.0, D, "The Hall of Thanes", 13, 18 },        -- Ironforge; a reader's comment, unchecked
    { 1413, 45.5, 35.5, D, "Wailing Caverns", 15, 25 },           -- The Barrens
    { 1436, 42.4, 70.4, D, "The Deadmines", 18, 23 },             -- Westfall
    { 1421, 42.6, 66.6, D, "Shadowfang Keep", 22, 30 },           -- Silverpine Forest
    { 1453, 41.0, 57.0, D, "The Stockade", 22, 30 },              -- Stormwind City
    { 1440, 13.4, 12.8, D, "Blackfathom Deeps", 24, 32 },         -- Ashenvale
    { 1420, 83.5, 32.0, D, "Scarlet Monastery", 28, 45 },         -- Tirisfal Glades
    { 1426, 30.5, 36.3, D, "Gnomeregan", 29, 38 },                -- Dun Morogh
    { 1413, 42.6, 88.5, D, "Razorfen Kraul", 30, 40 },            -- The Barrens
    { 1413, 50.0, 92.0, D, "Razorfen Downs", 40, 50 },            -- The Barrens
    { 1418, 42.6, 10.8, D, "Uldaman", 42, 52 },                   -- Badlands
    { 1446, 39.5, 21.3, D, "Zul'Farrak", 44, 54 },                -- Tanaris
    { 1443, 29.5, 57.8, D, "Maraudon", 45, 57 },                  -- Desolace
    { 1435, 69.6, 53.2, D, "Temple of Atal'Hakkar", 50, 60 },     -- Swamp of Sorrows
    { 1427, 35.2, 84.2, D, "Blackrock Depths", 52, 60 },          -- Searing Gorge
    { 1427, 35.2, 84.2, D, "Lower Blackrock Spire", 55, 60 },     -- Searing Gorge
    { 1427, 35.2, 84.2, D, "Upper Blackrock Spire", 58, 60 },     -- Searing Gorge
    { 1444, 58.9, 41.5, D, "Dire Maul", 58, 60 },                 -- Feralas
    { 1422, 69.8, 76.0, D, "Scholomance", 58, 60 },               -- Western Plaguelands
    { 1423, 30.9, 15.2, D, "Stratholme: Living Side", 58, 60 },   -- Eastern Plaguelands
    { 1423, 48.3, 21.8, D, "Stratholme: Undead Side", 58, 60 },   -- Eastern Plaguelands
}

local function percent(n)
    return type(n) == "number" and n >= 0 and n <= 100
end

-- What a row says after the name: "13-18", "60", "Raid" for a raid with no
-- levels, else nothing.
local function levels(kind, low, high)
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
