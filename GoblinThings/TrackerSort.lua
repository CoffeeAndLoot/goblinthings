local _, ns = ...

-- The quest tracker's order (spec 2026-10-13-tracker-sort-and-tabs-design.md,
-- The rule): up to three tiers, each a step down from the last. Level is lowest
-- first, Finished puts finished quests first, This zone puts quests on the
-- current map first; whatever still ties keeps Blizzard's own order (index).
-- Only this zone (zoneOnly) drops quests on other maps before sorting.
-- A value the game did not give sorts as the weakest. Pure.
local TrackerSort = {}
ns.TrackerSort = TrackerSort

TrackerSort.SLOTS = { "sortFirst", "sortSecond", "sortThird" }
TrackerSort.KEYS = { level = true, finished = true, zone = true }
TrackerSort.ZONE_ONLY = "zoneOnly"  -- the Only this zone feature
TrackerSort.AUTO_TRACK = "autoTrack"  -- the Auto-track new quests feature
TrackerSort.AUTO_TRACK_CVAR = "autoQuestWatch"  -- Blizzard_ObjectiveTracker.lua:35 tracks new quests by it

-- What to write to Blizzard's auto-track setting, or nil to leave it: on, it
-- must read "1"; switched off just now, "0". Off and untouched never writes,
-- so a player who never ticks the box never has the setting changed.
function TrackerSort.AutoTrackWrite(on, current, switched)
    local want = on and "1" or (switched and "0" or nil)
    if want ~= nil and current ~= want then
        return want
    end
    return nil
end

function TrackerSort.IsSlot(key)
    for _, slot in ipairs(TrackerSort.SLOTS) do
        if slot == key then
            return true
        end
    end
    return false
end

-- The active tiers in slot order; none and anything unknown left out.
function TrackerSort.Tiers(features)
    local tiers = {}
    for _, slot in ipairs(TrackerSort.SLOTS) do
        local key = features[slot]
        if TrackerSort.KEYS[key] then
            tiers[#tiers + 1] = key
        end
    end
    return tiers
end

-- The settings to write when slot takes value: no key in two slots, so the
-- slot that held it goes back to none. none may repeat.
function TrackerSort.Assign(features, slot, value)
    local changes = { [slot] = value }
    if value ~= "none" then
        for _, other in ipairs(TrackerSort.SLOTS) do
            if other ~= slot and features[other] == value then
                changes[other] = "none"
            end
        end
    end
    return changes
end

local function level(entry)
    return type(entry.level) == "number" and entry.level or nil
end

function TrackerSort.Less(a, b, tiers)
    for _, tier in ipairs(tiers) do
        if tier == "level" then
            local x, y = level(a), level(b)
            if x ~= y then
                if x == nil then
                    return false
                elseif y == nil then
                    return true
                end
                return x < y
            end
        elseif tier == "finished" then
            local x, y = a.finished == true, b.finished == true
            if x ~= y then
                return x
            end
        elseif tier == "zone" then
            local x, y = a.onMap == true, b.onMap == true
            if x ~= y then
                return x
            end
        end
    end
    return a.index < b.index
end

-- The quests whose marker belongs to mapID itself, as { [questID] = true },
-- from C_QuestLog.GetQuestsOnMap(mapID); nil when either is unknown. The game
-- also lists a neighbouring zone's quests on a map, with that zone's mapID
-- (Stonetalon's 1442 on the Barrens' 1413), and IsOnMap says yes to those:
-- they are not here.
function TrackerSort.HereSet(pois, mapID)
    if type(pois) ~= "table" or type(mapID) ~= "number" then
        return nil
    end
    local here = {}
    for _, poi in ipairs(pois) do
        if type(poi) == "table" and poi.mapID == mapID and type(poi.questID) == "number" then
            here[poi.questID] = true
        end
    end
    return here
end

-- Whether the tracker needs us at all: a tier set, or Only this zone on.
function TrackerSort.Active(features)
    return #TrackerSort.Tiers(features) > 0 or features[TrackerSort.ZONE_ONLY] == true
end

-- A sorted copy of entries ({ level, finished, onMap, index, ... }). With
-- zoneOnly, a quest the game says is elsewhere (onMap false) is left out; one
-- it gave no answer for (nil) stays.
function TrackerSort.Order(entries, tiers, zoneOnly)
    local out = {}
    for _, entry in ipairs(entries) do
        if not (zoneOnly and entry.onMap == false) then
            out[#out + 1] = entry
        end
    end
    table.sort(out, function(a, b)
        return TrackerSort.Less(a, b, tiers)
    end)
    return out
end

return TrackerSort
