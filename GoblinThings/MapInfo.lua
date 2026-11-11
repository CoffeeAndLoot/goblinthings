local _, ns = ...

-- What the world map's corner says about a zone (spec 2026-11-10-map-zone-
-- readout-design.md): its level range and the fishing skill it needs, both
-- hand-written, keyed by UiMap ID. Pure: test/run.lua loads this file.
local MapInfo = {}
ns.MapInfo = MapInfo

-- { low, high } per zone, copied from GoblinPS's Data/Zones.lua (Classic
-- ranges, plus Forever's Mount Hyjal and Riverglades). C_Map.GetMapLevels is
-- present on this build and answers for no zone, so the client cannot say.
MapInfo.LEVELS = {
    -- Kalimdor
    [1411] = { 1, 10 },   -- Durotar
    [1412] = { 1, 10 },   -- Mulgore
    [1438] = { 1, 10 },   -- Teldrassil
    [1413] = { 10, 25 },  -- The Barrens
    [1439] = { 10, 20 },  -- Darkshore
    [1442] = { 15, 27 },  -- Stonetalon Mountains
    [1440] = { 18, 30 },  -- Ashenvale
    [1441] = { 25, 35 },  -- Thousand Needles
    [1443] = { 30, 40 },  -- Desolace
    [1445] = { 35, 45 },  -- Dustwallow Marsh
    [1444] = { 40, 50 },  -- Feralas
    [1446] = { 40, 50 },  -- Tanaris
    [1447] = { 45, 55 },  -- Azshara
    [1448] = { 48, 55 },  -- Felwood
    [1449] = { 48, 55 },  -- Un'Goro Crater
    [1452] = { 53, 60 },  -- Winterspring
    [1450] = { 55, 60 },  -- Moonglade
    [1451] = { 55, 60 },  -- Silithus
    [2482] = { 60, 60 },  -- Mount Hyjal
    -- Eastern Kingdoms
    [1420] = { 1, 10 },   -- Tirisfal Glades
    [1426] = { 1, 10 },   -- Dun Morogh
    [1429] = { 1, 10 },   -- Elwynn Forest
    [1421] = { 10, 20 },  -- Silverpine Forest
    [1436] = { 10, 20 },  -- Westfall
    [1432] = { 10, 20 },  -- Loch Modan
    [1433] = { 15, 25 },  -- Redridge Mountains
    [1431] = { 18, 30 },  -- Duskwood
    [1424] = { 20, 30 },  -- Hillsbrad Foothills
    [1437] = { 20, 30 },  -- Wetlands
    [1416] = { 30, 40 },  -- Alterac Mountains
    [1417] = { 30, 40 },  -- Arathi Highlands
    [1434] = { 30, 45 },  -- Stranglethorn Vale
    [1418] = { 35, 45 },  -- Badlands
    [1435] = { 35, 45 },  -- Swamp of Sorrows
    [2548] = { 35, 45 },  -- Riverglades
    [1425] = { 40, 50 },  -- The Hinterlands
    [1427] = { 43, 50 },  -- Searing Gorge
    [1419] = { 45, 55 },  -- Blasted Lands
    [1428] = { 50, 58 },  -- Burning Steppes
    [1422] = { 51, 58 },  -- Western Plaguelands
    [1423] = { 53, 60 },  -- Eastern Plaguelands
    [1430] = { 55, 60 },  -- Deadwind Pass
}

-- { the skill to fish here at all, the skill at which nothing gets away }.
-- Classic values, unverified on Forever: the client's data has no fishing
-- column (the server holds it). Blizzard Watch's Classic fishing guide
-- (2019-09-16) for the first four tiers, Warcraft Tavern's Fishing 1-300 for
-- the fifth. Subzones with their own skill (Jaguero Isle, Bay of Storms,
-- Jademir Lake) are left to their zone.
local STARTER, NEAR, MID, FAR, HIGH, TOP = { 1, 25 }, { 1, 75 }, { 55, 150 }, { 130, 225 }, { 205, 300 },
    { 330, 425 }
MapInfo.FISHING = {
    [1426] = STARTER, [1411] = STARTER, [1429] = STARTER, [1412] = STARTER, [1438] = STARTER,
    [1420] = STARTER,  -- Dun Morogh, Durotar, Elwynn Forest, Mulgore, Teldrassil, Tirisfal Glades
    [1413] = NEAR, [1439] = NEAR, [1432] = NEAR, [1421] = NEAR,
    [1436] = NEAR,  -- The Barrens, Darkshore, Loch Modan, Silverpine Forest, Westfall
    [1457] = NEAR, [1455] = NEAR, [1454] = NEAR, [1453] = NEAR, [1456] = NEAR,
    [1458] = NEAR,  -- Darnassus, Ironforge, Orgrimmar, Stormwind City, Thunder Bluff, Undercity
    [1440] = MID, [1431] = MID, [1424] = MID, [1433] = MID, [1442] = MID,
    [1437] = MID,  -- Ashenvale, Duskwood, Hillsbrad Foothills, Redridge, Stonetalon, Wetlands
    [1416] = FAR, [1417] = FAR, [1443] = FAR, [1445] = FAR, [1434] = FAR, [1435] = FAR,
    [1441] = FAR,  -- Alterac, Arathi, Desolace, Dustwallow, Stranglethorn, Swamp of Sorrows, Thousand Needles
    [1447] = HIGH, [1448] = HIGH, [1444] = HIGH, [1450] = HIGH, [1446] = HIGH, [1425] = HIGH, [1449] = HIGH,
    [1422] = HIGH,  -- Azshara, Felwood, Feralas, Moonglade, Tanaris, Hinterlands, Un'Goro, W. Plaguelands
    [1428] = TOP, [1430] = TOP, [1423] = TOP, [1451] = TOP,
    [1452] = TOP,  -- Burning Steppes, Deadwind Pass, E. Plaguelands, Silithus, Winterspring
}

local function known(mapID)
    return MapInfo.LEVELS[mapID] ~= nil or MapInfo.FISHING[mapID] ~= nil
end

-- The map the corner describes: the one under the cursor when it is not the
-- shown map and has data (a zone on a continent, a city on its zone's map),
-- else the shown map when it has data, else nil.
function MapInfo.Pick(shown, hovered)
    if hovered ~= shown and known(hovered) then
        return hovered
    end
    if known(shown) then
        return shown
    end
    return nil
end

-- The corner's lines, top first: the name (when the game gave one), the
-- levels and the fishing, each left out when unknown; nil for a map with no data.
function MapInfo.Lines(mapID, name)
    if not known(mapID) then
        return nil
    end
    local lines = {}
    if type(name) == "string" and name ~= "" then
        lines[#lines + 1] = name
    end
    local levels = MapInfo.LEVELS[mapID]
    if levels then
        lines[#lines + 1] = levels[1] == levels[2] and ("Level " .. levels[1])
            or ("Levels " .. levels[1] .. "-" .. levels[2])
    end
    local fishing = MapInfo.FISHING[mapID]
    if fishing then
        lines[#lines + 1] = ("Fishing %d (no getaways at %d)"):format(fishing[1], fishing[2])
    end
    return lines
end

return MapInfo
