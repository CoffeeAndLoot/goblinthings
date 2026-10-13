local _, ns = ...

-- The quest tracker's order (spec 2026-10-13-tracker-sort-and-tabs-design.md,
-- The rule): up to three tiers, each a step down from the last. Level is lowest
-- first, Finished puts finished quests first, This zone puts quests on the
-- current map first; whatever still ties keeps Blizzard's own order (index).
-- A value the game did not give sorts as the weakest. Pure.
local TrackerSort = {}
ns.TrackerSort = TrackerSort

TrackerSort.SLOTS = { "sortFirst", "sortSecond", "sortThird" }
TrackerSort.KEYS = { level = true, finished = true, zone = true }

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

-- A sorted copy of entries ({ level, finished, onMap, index, ... }).
function TrackerSort.Order(entries, tiers)
    local out = {}
    for i, entry in ipairs(entries) do
        out[i] = entry
    end
    table.sort(out, function(a, b)
        return TrackerSort.Less(a, b, tiers)
    end)
    return out
end

return TrackerSort
