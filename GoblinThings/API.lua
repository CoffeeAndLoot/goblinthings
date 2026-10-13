local _, ns = ...

-- The ONLY file that calls Blizzard game APIs (spec 2026-10-13-goblin-things-
-- design.md). Everything is defensive: a missing API or an odd return means
-- "no answer", never an error. Every Blizzard call goes through attempt(),
-- which pcalls it and remembers the message under the call's name so
-- /gt probe can say why a call went quiet.
local API = {}
ns.API = API

local errors = {}

local function finish(name, ok, ...)
    if ok then
        return ...
    end
    errors[name] = tostring((...))
    return nil
end

local function attempt(name, fn, ...)
    return finish(name, pcall(fn, ...))
end

-- attempt() for a function that may not exist on this client.
local function call(name, fn, ...)
    if type(fn) ~= "function" then
        return nil
    end
    return attempt(name, fn, ...)
end

-- name -> message for every call that has thrown since login.
function API.Errors()
    local copy = {}
    for name, message in pairs(errors) do
        copy[name] = message
    end
    return copy
end

function API.ShiftDown()
    return call("IsShiftKeyDown", IsShiftKeyDown) and true or false
end

-- ---- NPC quest windows (from GoblinQuest's API.lua) ----

local function count(n)
    return (type(n) == "number" and n > 0) and math.floor(n) or 0
end

local function str(t)
    return (type(t) == "string") and t or nil
end

local function gossipList(fn, name, keep)
    local out = {}
    local list = call(name, fn)
    if type(list) == "table" then
        for _, q in ipairs(list) do
            if type(q) == "table" and type(q.questID) == "number" then
                out[#out + 1] = keep(q)
            end
        end
    end
    return out
end

-- The window the client just opened, as the plain table Hands.Decide reads.
-- A number the client will not give stays nil, and the Hands wait on nil.
-- An unknown isTrivial counts as trivial: never taken.
function API.NpcView(kind)
    local view = { kind = kind }
    if kind == "gossip" then
        local g = C_GossipInfo or {}
        view.active = gossipList(g.GetActiveQuests, "GetActiveQuests",
            function(q) return { arg = q.questID, questID = q.questID, complete = q.isComplete and true or false } end)
        view.available = gossipList(g.GetAvailableQuests, "GetAvailableQuests",
            function(q)
                return {
                    arg = q.questID,
                    questID = q.questID,
                    trivial = (q.isTrivial ~= false),
                    repeatable = q.repeatable and true or false,
                    ignored = q.isIgnored and true or false,
                    tag = (type(q.questInfoID) == "number") and q.questInfoID or nil,
                    title = str(q.title),
                }
            end)
    elseif kind == "greeting" then
        view.active, view.available = {}, {}
        for i = 1, count(call("GetNumActiveQuests", GetNumActiveQuests)) do
            local _, complete = call("GetActiveTitle", GetActiveTitle, i)
            local activeQuestID = call("GetActiveQuestID", GetActiveQuestID, i)
            view.active[#view.active + 1] = {
                arg = i,
                questID = (type(activeQuestID) == "number") and activeQuestID or nil,
                complete = complete and true or false,
            }
        end
        for i = 1, count(call("GetNumAvailableQuests", GetNumAvailableQuests)) do
            local trivial, _, repeatable, _, questID, _, _, questInfoID =
                call("GetAvailableQuestInfo", GetAvailableQuestInfo, i)
            local title = call("GetAvailableTitle", GetAvailableTitle, i)
            view.available[#view.available + 1] = {
                arg = i,
                questID = (type(questID) == "number") and questID or nil,
                trivial = (trivial ~= false),
                repeatable = repeatable and true or false,
                tag = (type(questInfoID) == "number") and questInfoID or nil,
                title = str(title),
            }
        end
    elseif kind == "detail" or kind == "progress" or kind == "complete" then
        local questID = call("GetQuestID", GetQuestID)
        if kind == "detail" then
            view.pvp = call("QuestFlagsPVP", QuestFlagsPVP) and true or false
            view.auto = call("QuestGetAutoAccept", QuestGetAutoAccept) and true or false
            view.group = call("GetSuggestedGroupSize", GetSuggestedGroupSize)
            if type(view.group) ~= "number" then view.group = nil end
            view.title = str(call("GetTitleText", GetTitleText))
            local tagInfo
            if type(questID) == "number" and C_QuestLog and C_QuestLog.GetQuestTagInfo then
                tagInfo = call("GetQuestTagInfo", C_QuestLog.GetQuestTagInfo, questID)
            end
            view.tag = (type(tagInfo) == "table" and type(tagInfo.tagID) == "number") and tagInfo.tagID or nil
        elseif kind == "progress" then
            view.completable = call("IsQuestCompletable", IsQuestCompletable) and true or false
            local money = call("GetQuestMoneyToGet", GetQuestMoneyToGet)
            view.money = (type(money) == "number") and money or nil
        elseif kind == "complete" then
            local choices = call("GetNumQuestChoices", GetNumQuestChoices)
            view.choices = (type(choices) == "number") and choices or nil
            local money = call("GetQuestMoneyToGet", GetQuestMoneyToGet)
            view.money = (type(money) == "number") and money or nil
        end
        view.questID = questID
    end
    return view
end

-- What each Hands op calls. Gossip selects by questID, the greeting pane by
-- index, as Blizzard's own buttons do.
local ACT = {
    selectActive = function(kind, arg)
        if kind == "gossip" then return C_GossipInfo.SelectActiveQuest(arg) end
        return SelectActiveQuest(arg)
    end,
    selectAvailable = function(kind, arg)
        if kind == "gossip" then return C_GossipInfo.SelectAvailableQuest(arg) end
        return SelectAvailableQuest(arg)
    end,
    accept = function() return AcceptQuest() end,
    acknowledge = function() return AcknowledgeAutoAcceptQuest() end,
    complete = function() return CompleteQuest() end,
    reward = function(_, arg) return GetQuestReward(arg) end,
}

function API.NpcAct(kind, op, arg)
    local fn = ACT[op]
    if fn then
        attempt("NpcAct " .. op, fn, kind, arg)
    end
end

-- ---- vendor (from GoblinQuest's API.lua) ----

-- Sell price (copper) of an item: the 11th return of GetItemInfo.
local function sellPrice(itemID)
    if type(itemID) ~= "number" then
        return nil
    end
    local _, _, _, _, _, _, _, _, _, _, price = call("GetItemInfo", C_Item and C_Item.GetItemInfo, itemID)
    return (type(price) == "number") and price or nil
end

-- The bags and the window as the plain table Vendor.Plan reads. Money is
-- read here, so call this before any selling.
function API.MerchantView()
    local view = { slots = {}, shift = API.ShiftDown() }
    local c = C_Container or {}
    for bag = 0, 4 do
        local n = call("GetContainerNumSlots", c.GetContainerNumSlots, bag)
        for slot = 1, (type(n) == "number") and n or 0 do
            local info = call("GetContainerItemInfo", c.GetContainerItemInfo, bag, slot)
            if type(info) == "table" then
                view.slots[#view.slots + 1] = {
                    bag = bag,
                    slot = slot,
                    quality = info.quality,
                    hasNoValue = info.hasNoValue == true,
                    locked = info.isLocked == true,
                    count = info.stackCount or 1,
                    price = sellPrice(info.itemID),
                }
            end
        end
    end
    view.canRepair = call("CanMerchantRepair", CanMerchantRepair) and true or false
    local cost = call("GetRepairAllCost", GetRepairAllCost)
    view.repairCost = (type(cost) == "number") and cost or nil
    local money = call("GetMoney", GetMoney)
    view.money = (type(money) == "number") and money or nil
    return view
end

function API.SellSlot(bag, slot)
    call("UseContainerItem", C_Container and C_Container.UseContainerItem, bag, slot)
end

function API.RepairAll()
    call("RepairAllItems", RepairAllItems)  -- no argument: own gold
end

-- ---- camera (CVarDocumentation.lua: C_CVar.GetCVar / SetCVar) ----

function API.GetCVar(name)
    return call("GetCVar", C_CVar and C_CVar.GetCVar, name)
end

function API.SetCVar(name, value)
    call("SetCVar", C_CVar and C_CVar.SetCVar, name, value)
end

-- ---- declines: what Blizzard's own popups call ----

-- Blizzard_StaticPopup_Game/GameDialogDefs.lua, DUEL_REQUESTED's decline.
function API.CancelDuel()
    call("CancelDuel", CancelDuel)
end

-- Blizzard_FrameXML/GuildInviteFrame.xml, the Decline button.
function API.DeclineGuild()
    call("DeclineGuild", DeclineGuild)
end

-- ---- cinematics ----

-- CinematicFrame_CancelCinematic's call for a real (cancellable) cinematic.
function API.StopCinematic()
    call("StopCinematic", StopCinematic)
end

-- MovieFrameMixin:FinishMovie (Blizzard_FrameXML/MovieFrame.lua), what its
-- own confirm-skip button calls; only while the movie frame is up.
function API.FinishMovie()
    if MovieFrame and call("MovieFrame:IsShown", MovieFrame.IsShown, MovieFrame) then
        call("MovieFrame:FinishMovie", MovieFrame.FinishMovie, MovieFrame)
    end
end

function API.CinematicSummary()
    return str(call("GetCurrentCinematicSummary", GetCurrentCinematicSummary))
end

-- The English race file name (UnitRace's second return), or nil.
function API.Race()
    local _, race = call("UnitRace", UnitRace, "player")
    return str(race)
end

-- The map the client places the player on, or nil.
function API.PlayerMap()
    local map = call("GetBestMapForUnit", C_Map and C_Map.GetBestMapForUnit, "player")
    return (type(map) == "number" and map ~= 0) and map or nil
end

-- fn on the next frame, after Blizzard's own handler for the same event has
-- shown its frame; at once if the client has no timer.
function API.Later(fn)
    if C_Timer and C_Timer.After then
        call("C_Timer.After", C_Timer.After, 0, fn)
    else
        fn()
    end
end

-- ---- quest tracker (spec 2026-10-13-tracker-sort-and-tabs-design.md) ----

-- What a tracked quest is sorted by. Only the ID is read from the tracker's
-- quest object; the rest is asked of the game, nil when it gives no answer.
function API.TrackerFacts(quest)
    if type(quest) ~= "table" or type(quest.GetID) ~= "function" then
        return {}
    end
    local id = attempt("quest:GetID", quest.GetID, quest)
    if type(id) ~= "number" or not C_QuestLog then
        return {}
    end
    local logIndex = call("GetLogIndexForQuestID", C_QuestLog.GetLogIndexForQuestID, id)
    local info = type(logIndex) == "number" and call("GetInfo", C_QuestLog.GetInfo, logIndex) or nil
    local onMap = call("IsOnMap", C_QuestLog.IsOnMap, id)
    if type(onMap) ~= "boolean" then
        onMap = nil  -- no answer, so Only this zone keeps it
    end
    return {
        level = (type(info) == "table" and type(info.level) == "number") and info.level or nil,
        finished = call("IsComplete", C_QuestLog.IsComplete, id) == true,
        onMap = onMap,
    }
end

local trackerSorter

-- Whether every entry of shown is one of infos, none twice: a filter may
-- drop quests, but never invent or repeat one.
local function drawnFrom(shown, infos)
    if type(shown) ~= "table" then
        return false
    end
    local left = {}
    for _, info in ipairs(infos) do
        left[info] = true
    end
    for _, info in ipairs(shown) do
        if not left[info] then
            return false
        end
        left[info] = nil
    end
    return true
end

-- Stands in for QuestObjectiveTrackerMixin:BuildQuestWatchInfos: Blizzard's
-- list, filtered and reordered. A sorter that errors, or shows a quest
-- Blizzard did not give or one twice, gives Blizzard's list.
local function sortedWatchInfos(self)
    local infos = QuestObjectiveTrackerMixin.BuildQuestWatchInfos(self)
    if not trackerSorter then
        return infos
    end
    local ok, sorted = pcall(trackerSorter, infos)
    if ok and drawnFrom(sorted, infos) then
        return sorted
    end
    errors["Tracker sort"] = ok and "the sort showed a quest Blizzard did not give" or tostring(sorted)
    return infos
end

function API.RedrawTracker()
    if QuestObjectiveTracker and QuestObjectiveTracker.MarkDirty then
        attempt("QuestObjectiveTracker:MarkDirty", QuestObjectiveTracker.MarkDirty, QuestObjectiveTracker)
    end
end

-- sorter(infos) -> a reordered copy, or nil for Blizzard's order. XML
-- mixin= copies the mixin's methods onto the frame (no __index back to it),
-- so the wrapper, once in, stays in: setting the field to nil would delete
-- the tracker's own method. With no sorter it passes Blizzard's list through.
-- False when this client has no such tracker.
function API.SetTrackerSort(sorter)
    if not (QuestObjectiveTracker and QuestObjectiveTrackerMixin
        and type(QuestObjectiveTrackerMixin.BuildQuestWatchInfos) == "function") then
        errors["Tracker"] = "QuestObjectiveTracker or its BuildQuestWatchInfos is missing"
        return false
    end
    trackerSorter = sorter
    if sorter then
        QuestObjectiveTracker.BuildQuestWatchInfos = sortedWatchInfos
    end
    API.RedrawTracker()
    return true
end

-- ---- screen (from Goblin Flyout's API.lua) ----

-- Physical pixels per UI unit at scale 1 (the UI is 768 units tall), so a
-- glyph picks a copy that is sharp from 1080p to 4K; nil when unknown.
function API.ScreenPixelsPerUnit()
    local _, height = call("GetPhysicalScreenSize", GetPhysicalScreenSize)
    if type(height) ~= "number" or height <= 0 then
        return nil
    end
    return height / 768
end

-- The cursor's x, y in screen units at scale 1, or nil.
function API.CursorPosition()
    return call("GetCursorPosition", GetCursorPosition)
end

-- ---- events (from Goblin Flyout's API.lua) ----

local eventFrame
local handlers = {}

-- fn(event, ...) for each name. An unknown name is a hard error in the
-- client, so each registration is pcalled and a failure is kept for the probe.
function API.OnEvents(names, fn)
    if not eventFrame then
        eventFrame = CreateFrame("Frame")
        eventFrame:SetScript("OnEvent", function(_, event, ...)
            for _, handler in ipairs(handlers[event] or {}) do
                handler(event, ...)
            end
        end)
    end
    for _, name in ipairs(names) do
        local ok, err = pcall(eventFrame.RegisterEvent, eventFrame, name)
        if ok then
            handlers[name] = handlers[name] or {}
            table.insert(handlers[name], fn)
        else
            errors["RegisterEvent " .. name] = tostring(err)
        end
    end
end

return API
