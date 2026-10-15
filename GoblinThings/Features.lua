local _, ns = ...

-- The switches as data (spec 2026-10-13-goblin-things-design.md, Scope). The
-- window builds its rows from LIST and Options.Init stores every feature with
-- a default; the camera has none, because the game's own CVar is its store.
-- Pure: test/run.lua loads this file.
local Features = {}
ns.Features = Features

-- The tracker sort's three tiers share their choices (spec
-- 2026-10-13-tracker-sort-and-tabs-design.md, Settings).
local SORT_CHOICES = { "none", "level", "finished", "zone" }
local SORT_LABELS = { none = "None", level = "Level", finished = "Finished", zone = "This zone" }

local function sortSlot(key, label)
    return { key = key, label = label, section = "Quests", group = "Quest tracker", control = "choice",
        default = "none", choices = SORT_CHOICES, labels = SORT_LABELS }
end

Features.LIST = {
    { key = "autoAccept", label = "Auto accept quests", section = "Quests", control = "check", default = true },
    { key = "autoTurnIn", label = "Auto turn-in quests", section = "Quests", control = "check", default = true },
    { key = "autoTrack", label = "Auto-track new quests", section = "Quests", control = "check",
        default = false },
    { key = "zoneOnly", label = "Only this zone", section = "Quests", group = "Quest tracker", control = "check",
        default = false },
    { key = "hideAbove", label = "Hide quests above me", section = "Quests", group = "Quest tracker",
        control = "slider", min = 0, max = 20, step = 1, default = 0, off = 0, format = "+%d" },
    sortSlot("sortFirst", "1st"),
    sortSlot("sortSecond", "2nd"),
    sortSlot("sortThird", "3rd"),
    { key = "autoSellJunk", label = "Auto sell junk", section = "Vendors", control = "check", default = true },
    { key = "autoRepair", label = "Auto repair", section = "Vendors", control = "check", default = true },
    { key = "fastLoot", label = "Fast loot", section = "Loot", control = "check", default = true },
    { key = "declineDuels", label = "Decline duels", section = "Social", control = "check", default = false },
    { key = "declineGuild", label = "Decline guild invites", section = "Social", control = "check",
        default = false },
    { key = "acceptGuild", label = "Accept invites from guild", section = "Social", control = "check",
        default = false },
    { key = "acceptFriends", label = "Accept invites from friends", section = "Social", control = "check",
        default = false },
    { key = "acceptSummons", label = "Accept summons", section = "Social", control = "check", default = false },
    { key = "cameraDistance", label = "Camera distance", section = "Camera", control = "slider",
        min = 1.0, max = 4.0, step = 0.1, format = "%.1f" },
    { key = "cinematics", label = "Skip cinematics", section = "Cinematics", control = "choice",
        default = "repeats", choices = { "off", "repeats", "all" },
        labels = { off = "Off", repeats = "Repeats only", all = "All" } },
}

-- A dim line at the foot of a section's tab.
Features.NOTES = { Quests = "Off and all None = Blizzard's tracker (fully after /reload)" }

function Features.ByKey(key)
    for _, feature in ipairs(Features.LIST) do
        if feature.key == key then
            return feature
        end
    end
    return nil
end

-- Whether value is one this feature can hold.
function Features.Valid(feature, value)
    if type(feature) ~= "table" then
        return false
    end
    if feature.control == "check" then
        return type(value) == "boolean"
    elseif feature.control == "choice" then
        return type(value) == "string" and feature.labels[value] ~= nil
    elseif feature.control == "slider" then
        return type(value) == "number" and value == value and value >= feature.min and value <= feature.max
    end
    return false
end

-- The number beside a slider: "Off" at its off value, else its format
-- (whole steps floored, so 3.0001 reads +3); "?" when the game gave none.
function Features.SliderText(feature, value)
    if type(value) ~= "number" then
        return "?"
    end
    if feature.step >= 1 then
        value = math.floor(value)
    end
    if value == feature.off then
        return "Off"
    end
    return string.format(feature.format, value)
end

-- { { name, features, note } ... }: LIST grouped by section, in LIST order.
function Features.Sections()
    local out, byName = {}, {}
    for _, feature in ipairs(Features.LIST) do
        local section = byName[feature.section]
        if not section then
            section = { name = feature.section, features = {}, note = Features.NOTES[feature.section] }
            byName[feature.section] = section
            out[#out + 1] = section
        end
        section.features[#section.features + 1] = feature
    end
    return out
end

return Features
