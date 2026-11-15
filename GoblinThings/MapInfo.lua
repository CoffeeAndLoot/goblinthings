local _, ns = ...

-- What the world map's corner says about a zone (spec 2026-11-10-map-zone-
-- readout-design.md): its level range and the fishing skill it needs, both
-- hand-written, keyed by UiMap ID, and what is gathered there, from the
-- generated MapData. Pure: test/run.lua loads this file.
local MapInfo = {}
ns.MapInfo = MapInfo

-- { low, high } per zone, copied from GoblinPS's Data/Zones.lua (Classic
-- ranges, plus Forever's Mount Hyjal; Riverglades and Zephras Isle are
-- Wowhead's Forever figures, 2026-11-14). C_Map.GetMapLevels is
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
    [2521] = { 1, 12 },   -- Zephras Isle
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
    [2548] = { 36, 44 },  -- Riverglades
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

-- What is gathered in a zone (spec 2026-11-14-map-gathering-lists-design.md):
-- MapData's generated lists, read here and never at file load.
local TABLE = { herbs = "HERBS", ore = "ORE", fish = "FISH", skins = "SKINS" }
local TITLE = { herbs = "Herbalism", ore = "Mining", fish = "Fishing", skins = "Skinning" }
-- The leather grades the Skins line names, lowest first, when one is a tenth
-- or more of the zone's skins.
local GRADES = { { "Ruined Leather Scraps", "Ruined" }, { "Light Leather", "Light" },
    { "Medium Leather", "Medium" }, { "Heavy Leather", "Heavy" }, { "Thick Leather", "Thick" },
    { "Rugged Leather", "Rugged" } }
local GRADE_SHARE = 10
local SPAN = { herbs = "Herbs", ore = "Ore" }
-- Under a list that came from Classic Era's pages, Forever's having none yet.
MapInfo.CLASSIC_NOTE = "Classic figures, not checked on Forever"
local CLASSIC = { herbs = "CLASSIC_NODES", ore = "CLASSIC_NODES", fish = "CLASSIC_FISH" }

-- The zone's { name, number } rows of a kind, or nil unless there are some
-- and every one is well formed: a broken list shows nothing, never an error.
local function rows(kind, mapID)
    local data = ns.MapData
    local lists = type(data) == "table" and TABLE[kind] and data[TABLE[kind]]
    local list = type(lists) == "table" and mapID ~= nil and lists[mapID]
    if type(list) ~= "table" or #list == 0 then
        return nil
    end
    for i = 1, #list do
        local row = list[i]
        if type(row) ~= "table" or type(row[1]) ~= "string" or type(row[2]) ~= "number" then
            return nil
        end
    end
    return list
end

local KINDS = { "fish", "herbs", "ore", "skins" }

-- Whether the corner has a line for this map: a level range, a fishing skill,
-- or a list whose switch is on (Shen'dralas has only lists).
local function known(mapID, show)
    if MapInfo.LEVELS[mapID] ~= nil or MapInfo.FISHING[mapID] ~= nil then
        return true
    end
    if type(show) == "table" then
        for _, kind in ipairs(KINDS) do
            if show[kind] == true and rows(kind, mapID) then
                return true
            end
        end
    end
    return false
end

-- The map the corner describes: the one under the cursor when it is not the
-- shown map and has data (a zone on a continent, a city on its zone's map),
-- else the shown map when it has data, else nil. show: as for Lines.
-- A map the corner can describe also draws the edges of the zones round it,
-- and the game names them under the cursor (seen in game: Winterspring at the
-- edge of Mount Hyjal's map took the card over, so Hyjal's icons could not be
-- reached, 2026-11-14; Durotar at the edge of Orgrimmar's, 2026-11-15). A
-- zone is a map with a level range: one never takes over a map that has its
-- own card, whether that is another zone's or a city's. A city still takes
-- over its zone's map, and a continent follows the cursor.
function MapInfo.Pick(shown, hovered, show)
    local neighbour = MapInfo.LEVELS[hovered] ~= nil and known(shown, show)
    if hovered ~= shown and not neighbour and known(hovered, show) then
        return hovered
    end
    if known(shown, show) then
        return shown
    end
    return nil
end

-- "Skins: Light, Medium": the grades worth naming, or a bare "Skins" when the
-- zone gives only oddities (Silithus' chitin).
local function skinsText(list)
    local share = {}
    for i = 1, #list do
        share[list[i][1]] = list[i][2]
    end
    local names = {}
    for _, grade in ipairs(GRADES) do
        if (share[grade[1]] or 0) >= GRADE_SHARE then
            names[#names + 1] = grade[2]
        end
    end
    return #names > 0 and ("Skins: " .. table.concat(names, ", ")) or "Skins"
end

local function span(low, high)
    return low == high and tostring(low) or (low .. "-" .. high)
end

-- The corner's lines, top first, each { text = , kind = }: the name (when the
-- game gave one), the levels, the fishing, the herbs, the ore and the skins,
-- each left out when unknown; nil for a map with no data. show = { herbs =,
-- ore =, fish =, skins = } are the four switches (nil: all off). kind ("fish",
-- "herbs", "ore", "skins") marks a line with a list to open; the fishing line has one only
-- with show.fish on and a fish list for the zone. A zone with a fish list
-- and no known skill (Riverglades, Zephras Isle) gets a bare "Fishing" line.
function MapInfo.Lines(mapID, name, show)
    if not known(mapID, show) then
        return nil
    end
    show = type(show) == "table" and show or {}
    local lines = {}
    if type(name) == "string" and name ~= "" then
        lines[#lines + 1] = { text = name }
    end
    local levels = MapInfo.LEVELS[mapID]
    if levels then
        lines[#lines + 1] = { text = (levels[1] == levels[2] and "Level " or "Levels ")
            .. span(levels[1], levels[2]) }
    end
    local fishing = MapInfo.FISHING[mapID]
    local fish = (show.fish == true and rows("fish", mapID)) and "fish" or nil
    if fishing then
        lines[#lines + 1] = { text = ("Fishing %d (no getaways at %d)"):format(fishing[1], fishing[2]), kind = fish }
    elseif fish then
        lines[#lines + 1] = { text = "Fishing", kind = fish }
    end
    for _, kind in ipairs({ "herbs", "ore" }) do
        local list = show[kind] == true and rows(kind, mapID)
        if list then
            local low, high = list[1][2], list[1][2]
            for i = 2, #list do
                low, high = math.min(low, list[i][2]), math.max(high, list[i][2])
            end
            lines[#lines + 1] = { text = SPAN[kind] .. " " .. span(low, high), kind = kind }
        end
    end
    local skins = show.skins == true and rows("skins", mapID)
    if skins then
        lines[#lines + 1] = { text = skinsText(skins), kind = "skins" }
    end
    return lines
end

-- What a line's list prints: { title =, rows = { { left, right } ... }, note = },
-- or nil when the zone has no such list. Herbs and ore read name and skill,
-- fish and skins name and share of the zone's catch or skins ("<1%" for a
-- rare one); the note marks a list from Classic's data.
function MapInfo.List(kind, mapID)
    local list = rows(kind, mapID)
    if not list then
        return nil
    end
    local classic = ns.MapData[CLASSIC[kind]]
    local out = { title = TITLE[kind], rows = {},
        note = (type(classic) == "table" and classic[mapID] == true) and MapInfo.CLASSIC_NOTE or nil }
    for i = 1, #list do
        local n = list[i][2]
        local right = tostring(n)
        if kind == "fish" or kind == "skins" then
            right = n < 1 and "<1%" or (n .. "%")
        end
        out.rows[i] = { list[i][1], right }
    end
    return out
end

return MapInfo
