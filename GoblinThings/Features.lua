local _, ns = ...

-- The switches as data (spec 2026-10-13-goblin-things-design.md, Scope). The
-- window builds its rows from LIST and Options.Init stores every feature with
-- a default; the camera has none, because the game's own CVar is its store.
-- Pure: test/run.lua loads this file.
local Features = {}
ns.Features = Features

Features.LIST = {
    { key = "autoAccept", label = "Auto accept quests", section = "Quests", control = "check", default = true },
    { key = "autoTurnIn", label = "Auto turn-in quests", section = "Quests", control = "check", default = true },
    { key = "autoSellJunk", label = "Auto sell junk", section = "Vendors", control = "check", default = true },
    { key = "autoRepair", label = "Auto repair", section = "Vendors", control = "check", default = true },
    { key = "declineDuels", label = "Decline duels", section = "Social", control = "check", default = false },
    { key = "declineGuild", label = "Decline guild invites", section = "Social", control = "check",
        default = false },
    { key = "cameraDistance", label = "Camera distance", section = "Camera", control = "slider",
        min = 1.0, max = 4.0, step = 0.1 },
    { key = "cinematics", label = "Skip cinematics", section = "Cinematics", control = "choice",
        default = "repeats", choices = { "off", "repeats", "all" },
        labels = { off = "Off", repeats = "Repeats only", all = "All" } },
}

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

-- { { name, features } ... }: LIST grouped by section, in LIST order.
function Features.Sections()
    local out, byName = {}, {}
    for _, feature in ipairs(Features.LIST) do
        local section = byName[feature.section]
        if not section then
            section = { name = feature.section, features = {} }
            byName[feature.section] = section
            out[#out + 1] = section
        end
        section.features[#section.features + 1] = feature
    end
    return out
end

return Features
