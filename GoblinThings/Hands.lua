local _, ns = ...

-- What to do at an NPC's quest window: one action or nothing (spec
-- 2026-10-13-goblin-things-design.md, Quests; from GoblinQuest's Hands.lua).
-- Pure: API.lua reads the window into a plain view and carries out the action.
-- The rules copy Blizzard's own buttons (Mainline/QuestFrame.lua in the forever
-- source) and keep off: Shift, grays, repeatables, ignored quests, dungeon,
-- raid and full-group quests, PvP, gold costs, real reward choices, and one try
-- per action per visit. An unknown answer is a reason to wait, never to act.
--
-- prefs = { autoAccept, autoTurnIn } (the SavedVariable's features table)
local Hands = {}
ns.Hands = Hands

-- Enum.QuestTag Dungeon and Raid (QuestLogDocumentation.lua ~1509-1510):
-- an offered quest tagged with either is left for the player to take by hand.
Hands.DUNGEON_TAGS = { [81] = true, [62] = true }
Hands.GROUP_SIZE = 5

function Hands.NewVisit()
    return { held = false, tried = {} }
end

-- Only a positive signal skips: a nil or zero tag, or a group below
-- Hands.GROUP_SIZE, is an ordinary quest.
local function isDungeon(tag)
    return tag ~= nil and tag ~= 0 and Hands.DUNGEON_TAGS[tag] == true
end

local function isFullGroup(group)
    return type(group) == "number" and group >= Hands.GROUP_SIZE
end

local function atQuestList(view, prefs)
    if prefs.autoTurnIn then
        for _, q in ipairs(view.active or {}) do
            if q.complete then
                return { op = "selectActive", arg = q.arg }
            end
        end
    end
    if prefs.autoAccept then
        for _, q in ipairs(view.available or {}) do
            if not (q.trivial or q.repeatable or q.ignored or isDungeon(q.tag)) then
                return { op = "selectAvailable", arg = q.arg }
            end
        end
    end
    return nil
end

local function choose(view, prefs)
    local kind = view.kind
    if kind == "gossip" or kind == "greeting" then
        return atQuestList(view, prefs)
    elseif kind == "detail" then
        if prefs.autoAccept and not view.pvp and not isDungeon(view.tag) and not isFullGroup(view.group) then
            return { op = view.auto and "acknowledge" or "accept" }
        end
    elseif kind == "progress" then
        if prefs.autoTurnIn and view.completable and view.money == 0 then
            return { op = "complete" }
        end
    elseif kind == "complete" then
        if prefs.autoTurnIn and view.money == 0 and type(view.choices) == "number" and view.choices <= 1 then
            return { op = "reward", arg = (view.choices == 1) and 1 or 0 }
        end
    end
    return nil
end

function Hands.Decide(view, prefs, visit)
    if type(view) ~= "table" or visit.held then
        return nil
    end
    local action = choose(view, prefs)
    if not action then
        return nil
    end
    action.key = view.kind .. ":" .. action.op .. ":" .. tostring(action.arg or view.questID or "")
    if visit.tried[action.key] then
        return nil
    end
    return action
end

return Hands
