local _, ns = ...

-- Glue (spec 2026-10-13-goblin-things-design.md): the SavedVariable, the
-- events that drive each rule, /gt and the chat lines. Every handler runs
-- behind guard(), so an error is one chat line, said once per label, never a
-- raise. Core.Get / Core.Set are the one door to every setting; the camera's
-- store is the game's own CVar.
local API, Camera, Cinematics, Decline, Features, Hands, MinimapButton, Options, TrackerSort, Vendor, Window =
    ns.API, ns.Camera, ns.Cinematics, ns.Decline, ns.Features, ns.Hands, ns.MinimapButton, ns.Options,
    ns.TrackerSort, ns.Vendor, ns.Window
local Core = {}
ns.Core = Core

local function say(text)
    print("|cffffd100Goblin Things|r " .. text)
end

local said = {}
local function guard(label, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok and not said[label] then
        said[label] = true
        say(label .. " error: " .. tostring(err) .. " (said once; tell Claude).")
    end
    return ok
end

-- Looked up lazily: SavedVariables load after this file runs, before any
-- handler or command can ask. Checked and repaired once, then read as is.
local checked = false
local function db()
    if not checked then
        GoblinThingsDB = Options.Init(GoblinThingsDB)
        checked = true
    end
    return GoblinThingsDB
end

-- ---- quest tracker sort ----

local trackerInstalled = false  -- the wrapper is in place; until it is, the tracker is never touched

-- Blizzard's { { quest, index } ... } in our order.
local function sortTracker(infos)
    local map = API.PlayerMap()
    local here = TrackerSort.HereSet(API.QuestsOnMap(map), map)
    local entries = {}
    for i, info in ipairs(infos) do
        local facts = API.TrackerFacts(info.quest, here)
        entries[i] = { level = facts.level, finished = facts.finished, onMap = facts.onMap, index = i, info = info }
    end
    local out = {}
    local features = db().features
    for i, entry in ipairs(TrackerSort.Order(entries, TrackerSort.Tiers(features),
        features[TrackerSort.ZONE_ONLY] == true)) do
        out[i] = entry.info
    end
    return out
end

-- On when any tier is set or Only this zone is on. Off makes an installed wrapper pass Blizzard's
-- list through; it stays in until /reload (see API.SetTrackerSort). A player
-- who never sorts never has the tracker touched.
local function applyTrackerSort()
    local on = TrackerSort.Active(db().features)
    if on then
        trackerInstalled = API.SetTrackerSort(sortTracker) or trackerInstalled
    elseif trackerInstalled then
        API.SetTrackerSort(nil)
    end
end

-- Blizzard's own auto-track setting, kept on while the switch is ticked;
-- switched says the player just clicked it, so off may write "0".
local function applyAutoTrack(switched)
    local cvar = TrackerSort.AUTO_TRACK_CVAR
    local write = TrackerSort.AutoTrackWrite(db().features[TrackerSort.AUTO_TRACK] == true, API.GetCVar(cvar), switched)
    if write then
        API.SetCVar(cvar, write)
    end
end

function Core.Get(key)
    if key == Camera.KEY then
        return Camera.Clamp(API.GetCVar(Camera.CVAR))
    end
    return db().features[key]
end

-- Called from the window's clicks and drags, so it carries its own guard.
function Core.Set(key, value)
    guard("Settings", function()
        if not Features.Valid(Features.ByKey(key), value) then
            return
        end
        if key == Camera.KEY then
            API.SetCVar(Camera.CVAR, Camera.Text(Camera.Clamp(value)))
        elseif TrackerSort.IsSlot(key) then
            for slot, slotValue in pairs(TrackerSort.Assign(db().features, key, value)) do
                db().features[slot] = slotValue
            end
            applyTrackerSort()
        else
            db().features[key] = value
            if key == TrackerSort.ZONE_ONLY then
                applyTrackerSort()
            elseif key == TrackerSort.AUTO_TRACK then
                applyAutoTrack(true)
            end
        end
        Window.Refresh(Core)
    end)
end

function Core.Tab()
    return db().tab
end

function Core.SetTab(name)
    guard("Window", function()
        if Options.IsTab(name) then
            db().tab = name
            Window.Refresh(Core)
        end
    end)
end

function Core.Angle()
    return db().minimap.angle
end

function Core.SetAngle(angle)
    if type(angle) == "number" then
        db().minimap.angle = angle
    end
end

function Core.MinimapShown()
    return not db().minimap.hide
end

function Core.SetMinimapShown(shown)
    db().minimap.hide = not shown
    MinimapButton.SetShown(shown)
    Window.Refresh(Core)
end

function Core.Window()
    return db().window
end

function Core.SaveWindow(point, relativePoint, x, y)
    if type(point) == "string" and type(relativePoint) == "string" and type(x) == "number" and type(y) == "number" then
        db().window = { point = point, relativePoint = relativePoint, x = x, y = y }
    end
end

function Core.ToggleWindow()
    guard("Window", Window.Toggle, Core)
end

-- ---- quests ----

-- The NPC windows the Hands answer, and the events that end a visit.
Core.NPC_WINDOWS = {
    GOSSIP_SHOW = "gossip", QUEST_GREETING = "greeting", QUEST_DETAIL = "detail",
    QUEST_PROGRESS = "progress", QUEST_COMPLETE = "complete",
}
Core.NPC_END = { GOSSIP_CLOSED = true, QUEST_FINISHED = true }

local visit = Hands.NewVisit()
local refused = {}  -- questIDs whose offer the Hands refused this session (Hands.Refused)

local function atNpc(event, continuing)
    local kind = Core.NPC_WINDOWS[event]
    if not kind then
        if event == "GOSSIP_CLOSED" and continuing then
            return  -- gossip is handing off to the quest frame; the visit goes on
        end
        visit = Hands.NewVisit()  -- GOSSIP_CLOSED or QUEST_FINISHED: the visit is over
        return
    end
    if API.ShiftDown() then
        visit.held = true  -- Shift at any window keeps the whole visit manual
    end
    local view = API.NpcView(kind)
    if Hands.Refused(view) then
        refused[view.questID] = true
    end
    local action = Hands.Decide(view, db().features, visit, refused)
    if action then
        visit.tried[action.key] = true
        API.NpcAct(kind, action.op, action.arg)
    end
end

local npcEvents = {}
for name in pairs(Core.NPC_WINDOWS) do npcEvents[#npcEvents + 1] = name end
for name in pairs(Core.NPC_END) do npcEvents[#npcEvents + 1] = name end
API.OnEvents(npcEvents, function(event, ...)
    guard("Quests", atNpc, event, ...)
end)

-- ---- vendors ----

local vendorDone = false

local function atVendor(event)
    if event == "MERCHANT_CLOSED" then
        vendorDone = false
        return
    end
    if vendorDone then
        return
    end
    vendorDone = true
    local plan = Vendor.Plan(API.MerchantView(), db().features)
    for _, e in ipairs(plan.sell) do
        API.SellSlot(e.bag, e.slot)
    end
    if plan.repair then
        API.RepairAll()
    end
    if plan.line then
        say(plan.line)
    end
end

API.OnEvents({ "MERCHANT_SHOW", "MERCHANT_CLOSED" }, function(event)
    guard("Vendor", atVendor, event)
end)

-- ---- declines ----

API.OnEvents({ "DUEL_REQUESTED" }, function(_, name)
    guard("Decline", function()
        local line = Decline.Duel(db().features.declineDuels, name)
        if line then
            API.CancelDuel()
            say(line)
        end
    end)
end)

API.OnEvents({ "GUILD_INVITE_REQUEST" }, function(_, inviter, guild)
    guard("Decline", function()
        local line = Decline.Guild(db().features.declineGuild, inviter, guild)
        if line then
            API.DeclineGuild()
            say(line)
        end
    end)
end)

-- ---- cinematics ----

local lastSummary  -- GetCurrentCinematicSummary at the last cinematic, for the probe

local function cinematic(kind, key, canCancel, stop)
    local seen = db().seen
    local action = Cinematics.Decide(db().features.cinematics, seen, kind, key, canCancel)
    if action == "mark" then
        Cinematics.Mark(seen, kind, key)
    elseif action == "stop" then
        API.Later(stop)
    end
end

API.OnEvents({ "PLAY_MOVIE" }, function(_, movieID)
    guard("Cinematics", cinematic, "movie", movieID, true, API.FinishMovie)
end)

API.OnEvents({ "CINEMATIC_START" }, function(_, canBeCancelled)
    guard("Cinematics", function()
        lastSummary = API.CinematicSummary()
        cinematic("cinematic", Cinematics.Key(API.Race(), API.PlayerMap()), canBeCancelled, API.StopCinematic)
    end)
end)

-- Every loading screen: an addon that turns auto-track off at login is
-- undone after it, while the switch is ticked.
API.OnEvents({ "PLAYER_ENTERING_WORLD" }, function()
    guard("Auto-track", applyAutoTrack, false)
end)

-- "This zone" changes with the map: redraw after Blizzard's own zone handler.
API.OnEvents({ "ZONE_CHANGED", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED_INDOORS" }, function()
    if trackerInstalled then
        API.Later(API.RedrawTracker)
    end
end)

-- ---- /gt ----

local commands = {}
local HELP = "Commands: /gt, /gt minimap, /gt probe."

commands[""] = function()
    Core.ToggleWindow()
end
commands.options = commands[""]

function commands.minimap()
    Core.SetMinimapShown(not Core.MinimapShown())
    if Core.MinimapShown() then
        say("Minimap button shown.")
    else
        say("Minimap button hidden; /gt opens the window.")
    end
end

local function size(t)
    local n = 0
    for _ in pairs(t) do
        n = n + 1
    end
    return n
end

-- What the addon sees, to settle in-game unknowns (the spec's Open facts).
function commands.probe()
    for _, feature in ipairs(Features.LIST) do
        say("Probe: " .. feature.key .. " = " .. tostring(Core.Get(feature.key)))
    end
    say("Probe: " .. Camera.CVAR .. " reads " .. tostring(API.GetCVar(Camera.CVAR)) .. ".")
    local seen = db().seen
    say(("Probe: seen %d movie(s) and %d cinematic(s); this spot's cinematic key is %s."):format(
        size(seen.movies), size(seen.cinematics), tostring(Cinematics.Key(API.Race(), API.PlayerMap()))))
    say("Probe: last cinematic summary: "
        .. (lastSummary and ('"' .. lastSummary .. '"') or "none this session") .. ".")
    local cvar = TrackerSort.AUTO_TRACK_CVAR
    say("Probe: " .. cvar .. " reads " .. tostring(API.GetCVar(cvar)) .. ".")
    local tiers = TrackerSort.Tiers(db().features)
    local active = TrackerSort.Active(db().features)
    local how = not trackerInstalled and " (not installed)."
        or (active and " (installed)." or " (pass-through until /reload).")
    say("Probe: tracker sort " .. (#tiers > 0 and table.concat(tiers, ", ") or "off")
        .. (db().features[TrackerSort.ZONE_ONLY] and ", only this zone" or "") .. how)
    for name, message in pairs(API.Errors()) do
        say("Probe: " .. name .. " threw: " .. message)
    end
end

local function slash(msg)
    local word = string.match(msg or "", "^%s*(%S*)")
    local command = commands[string.lower(word or "")]
    if command then
        command()
    else
        say(HELP)
    end
end

API.OnEvents({ "PLAYER_LOGIN" }, function()
    guard("Setup", function()
        if not Options.Register(Core.ToggleWindow) then
            say("Couldn't add the options page; /gt still opens the window.")
        end
        MinimapButton.Create(Core)
        applyTrackerSort()
    end)
end)

SLASH_GOBLINTHINGS1 = "/gt"
SLASH_GOBLINTHINGS2 = "/goblinthings"
SlashCmdList.GOBLINTHINGS = function(msg) guard("Slash", slash, msg) end

return Core
