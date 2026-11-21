local _, ns = ...

-- The switches as data (spec 2026-10-13-goblin-things-design.md, Scope). The
-- window builds its rows from LIST and Options.Init stores every feature with
-- a default; one with a cvar or a bag has none, because the game itself is its store.
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
    -- The diamond and its distance, pointing at the tracked quest. Retail's Options has the
    -- checkbox; Forever blanks it (SettingsDefinitions_Frame/Camelot/InterfaceOverrides.lua:2)
    -- and ships the CVar at 0, so this is its only switch.
    { key = "questDiamond", label = "Quest diamond on screen", section = "Quests", control = "check",
        cvar = "showInGameNavigation" },
    -- One mark above a quest mob's nameplate, with the smallest number still to go.
    { key = "questPlates", label = "Quest marks on nameplates", section = "Quests", control = "check",
        default = true },
    { key = "questPlatesSize", label = "Mark size", section = "Quests", control = "slider",
        min = 8, max = 32, step = 1, default = 12, format = "%d" },
    { key = "zoneOnly", label = "Only this zone", section = "Quests", group = "Quest tracker", control = "check",
        default = false },
    { key = "hideAbove", label = "Hide quests above me", section = "Quests", group = "Quest tracker",
        control = "slider", min = 0, max = 20, step = 1, default = 0, off = 0, format = "+%d" },
    sortSlot("sortFirst", "1st"),
    sortSlot("sortSecond", "2nd"),
    sortSlot("sortThird", "3rd"),
    { key = "autoSellJunk", label = "Auto sell junk", section = "Vendors", control = "check", default = true },
    { key = "autoRepair", label = "Auto repair", section = "Vendors", control = "check", default = true },
    { key = "autoTrain", label = "Auto train", section = "Vendors", control = "check", default = false },
    { key = "fastLoot", label = "Fast loot", section = "Loot", control = "check", default = true },
    -- Not CVars: the game keeps each behind a C_Container get/set pair (API.BagDirection) that
    -- no Blizzard window calls, so like a cvar they have no default of ours. The game forgets
    -- them at /reload, so once one is chosen here it is saved and set again at each login.
    { key = "bagsFillLeft", label = "New items fill bags left to right", section = "Loot", control = "check",
        bag = "insert" },
    { key = "bagsSortRight", label = "Sort bags right to left", section = "Loot", control = "check",
        bag = "sort" },
    -- From here, a check with a cvar and no comment is a first pick of docs/cvar-candidates.md:
    -- a setting the client has and Forever's Options gives no row for.
    { key = "compareItems", label = "Always compare gear", section = "Loot", control = "check",
        cvar = "alwaysCompareItems" },
    { key = "declineDuels", label = "Decline duels", section = "Social", control = "check", default = false },
    { key = "declineGuild", label = "Decline guild invites", section = "Social", control = "check",
        default = false },
    { key = "acceptGuild", label = "Accept invites from guild", section = "Social", control = "check",
        default = false },
    { key = "acceptFriends", label = "Accept invites from friends", section = "Social", control = "check",
        default = false },
    { key = "acceptSummons", label = "Accept summons", section = "Social", control = "check", default = false },
    -- Blizzard's Options > Social > Guild Member Alert (SettingsDefinitions_Frame/Social.lua:95);
    -- the engine plays the ding, so its CVar is the only handle and the store.
    { key = "guildAlerts", label = "Guild login alerts", section = "Social", control = "check",
        cvar = "guildMemberNotify" },
    { key = "stopAttack", label = "Stop attacking on target change", section = "Combat", control = "check",
        cvar = "stopAutoAttackOnTargetChange" },
    { key = "assistAttack", label = "Attack after /assist", section = "Combat", control = "check",
        cvar = "assistAttack" },
    { key = "autoStand", label = "Auto stand", section = "Combat", control = "check", cvar = "autoStand" },
    { key = "autoDismount", label = "Auto dismount", section = "Combat", control = "check",
        cvar = "autoDismount" },
    { key = "autoUnshift", label = "Auto leave shapeshift form", section = "Combat", control = "check",
        cvar = "autoUnshift" },
    { key = "targetCastbar", label = "Target's cast bar", section = "Combat", control = "check",
        cvar = "showTargetCastbar" },
    { key = "spellsToBar", label = "New spells go on the action bar", section = "Combat", control = "check",
        cvar = "AutoPushSpellToActionBar" },
    { key = "cameraDistance", label = "Camera distance", section = "Camera", control = "slider",
        min = 1.0, max = 4.0, step = 0.1, format = "%.1f", cvar = "cameraDistanceMaxZoomFactor" },
    { key = "cinematics", label = "Skip cinematics", section = "Cinematics", control = "choice",
        default = "repeats", choices = { "off", "repeats", "all" },
        labels = { off = "Off", repeats = "Repeats only", all = "All" } },
    -- The world map's corner readout (spec 2026-11-10-map-zone-readout-design.md).
    { key = "mapInfo", label = "Zone levels and fishing on the map", section = "Map", control = "check",
        default = true },
    -- What is gathered in the zone, on the same readout (spec 2026-11-14-map-gathering-lists-design.md).
    { key = "mapHerbs", label = "Herbs on the map", section = "Map", control = "check", default = true },
    { key = "mapOre", label = "Ore on the map", section = "Map", control = "check", default = true },
    { key = "mapFish", label = "Fish list on the map", section = "Map", control = "check", default = true },
    { key = "mapSkins", label = "Skins on the map", section = "Map", control = "check", default = true },
    -- A swirl at each dungeon and raid door (spec 2026-11-19-map-entrance-pins-design.md).
    { key = "mapEntrances", label = "Dungeon and raid entrances on the map", section = "Map", control = "check",
        default = true },
    { key = "mapFade", label = "World map fades while moving", section = "Map", control = "check",
        cvar = "mapFade" },
    { key = "trackAll", label = "Every tracking type on the minimap", section = "Map", control = "check",
        cvar = "minimapTrackingShowAll" },
    -- Kills left to level, ghosted in a screen corner (spec 2026-11-11-kills-to-level-design.md).
    { key = "killsLeft", label = "Kills to level", section = "XP", control = "check", default = false },
    { key = "killsCorner", label = "Corner", section = "XP", control = "choice", default = "topLeft",
        choices = { "topLeft", "topRight", "bottomLeft", "bottomRight" },
        labels = { topLeft = "Top left", topRight = "Top right", bottomLeft = "Bottom left",
            bottomRight = "Bottom right" } },
    { key = "killsX", label = "Offset across", section = "XP", control = "slider",
        min = 0, max = 400, step = 5, default = 20, format = "%d" },
    { key = "killsY", label = "Offset down / up", section = "XP", control = "slider",
        min = 0, max = 400, step = 5, default = 20, format = "%d" },
    -- Stored as opacity: 30 is 30% visible.
    { key = "killsAlpha", label = "Faintness", section = "XP", control = "slider",
        min = 5, max = 100, step = 5, default = 30, format = "%d%%" },
    { key = "killsSize", label = "Size", section = "XP", control = "slider",
        min = 8, max = 48, step = 1, default = 18, format = "%d" },
    { key = "killsFont", label = "Font", section = "XP", control = "choice", default = "friz",
        choices = { "friz", "arial", "morpheus" },
        labels = { friz = "Friz", arial = "Arial", morpheus = "Morpheus" } },
}

-- A dim line at the foot of a section's tab.
Features.NOTES = {
    XP = "Kills like your last ten; hidden until your first kill",
    Quests = "Off and all None = Blizzard's tracker (fully after /reload)",
    Map = "Read a zone at the world map's bottom right; open the zone for its lists",
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

-- A check whose store is the game's own CVar: "1" is on; no answer reads as off.
function Features.CVarOn(text)
    return text == "1"
end

function Features.CVarText(on)
    return on and "1" or "0"
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
