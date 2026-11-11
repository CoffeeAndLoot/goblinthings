local _, ns = ...

-- Glue (spec 2026-10-13-goblin-things-design.md): the SavedVariable, the
-- events that drive each rule, /gt and the chat lines. Every handler runs
-- behind guard(), so an error is one chat line, said once per label, never a
-- raise. Core.Get / Core.Set are the one door to every setting; the camera's
-- store is the game's own CVar.
local API, Accept, Camera, Cinematics, Decline, Features, Hands, Loot, MapReadout, MinimapButton, Options, Trainer,
    TrackerSort, Vendor, Window = ns.API, ns.Accept, ns.Camera, ns.Cinematics, ns.Decline, ns.Features, ns.Hands,
    ns.Loot, ns.MapReadout, ns.MinimapButton, ns.Options, ns.Trainer, ns.TrackerSort, ns.Vendor, ns.Window
local Kills, KillsReadout = ns.Kills, ns.KillsReadout
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
Core.Guard = guard  -- for MapReadout's OnUpdate

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
        features[TrackerSort.ZONE_ONLY] == true, TrackerSort.Cap(features, API.PlayerLevel()))) do
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

-- ---- kills to level (spec 2026-11-11-kills-to-level-design.md) ----

local samples = {}  -- the last kills' XP, this session only (Kills.Add)

-- The count while there is one, a sample while the XP tab is open to tune
-- the look, else nothing. Off, at max level or with no answer: nothing.
local function drawKills()
    local features = db().features
    local left, preview
    if features.killsLeft == true then
        if API.CanEarnXP() then
            local xp, xpMax = API.PlayerXP()
            left = Kills.Left(xp, xpMax, samples)
        end
        preview = Window.Shown() and db().tab == "XP"
    end
    KillsReadout.Draw(Kills.Text(left, preview), {
        corner = features.killsCorner, x = features.killsX, y = features.killsY,
        alpha = features.killsAlpha, size = features.killsSize, font = features.killsFont,
    })
end

local function redrawKills()
    guard("Kills", drawKills)
end

function Core.WindowHidden()
    redrawKills()
end

function Core.Get(key)
    if key == Camera.KEY then
        return Camera.Clamp(API.GetCVar(Camera.CVAR))
    end
    local feature = Features.ByKey(key)
    if feature and feature.cvar then  -- a check the game's own CVar stores
        return Features.CVarOn(API.GetCVar(feature.cvar))
    end
    return db().features[key]
end

-- Called from the window's clicks and drags, so it carries its own guard.
function Core.Set(key, value)
    guard("Settings", function()
        local feature = Features.ByKey(key)
        if not Features.Valid(feature, value) then
            return
        end
        if key == Camera.KEY then
            API.SetCVar(Camera.CVAR, Camera.Text(Camera.Clamp(value)))
        elseif feature.cvar then
            API.SetCVar(feature.cvar, Features.CVarText(value))
        elseif TrackerSort.IsSlot(key) then
            for slot, slotValue in pairs(TrackerSort.Assign(db().features, key, value)) do
                db().features[slot] = slotValue
            end
            applyTrackerSort()
        else
            db().features[key] = value
            if key == TrackerSort.ZONE_ONLY or key == TrackerSort.HIDE_ABOVE then
                applyTrackerSort()
            elseif key == TrackerSort.AUTO_TRACK then
                applyAutoTrack(true)
            elseif feature.section == "XP" then
                redrawKills()  -- its own guard: a draw error must not skip the Refresh below
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
            redrawKills()
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
    redrawKills()
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
    elseif kind == "gossip" and not visit.held and not visit.tried.trainer then
        local option = Trainer.GossipPick(view, db().features.autoTrain)
        if option then
            visit.tried.trainer = true
            API.SelectGossipOption(option)
        end
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

-- ---- trainers ----

-- One purchase now, the next when TRAINER_UPDATE shows the list changed; a
-- purchase the game refuses brings no update, so the run stops there.
local lesson = Trainer.NewVisit()

local function atTrainer(event)
    if event == "TRAINER_CLOSED" then
        local line = Trainer.Line(lesson)
        if line then
            say(line)
        end
        lesson = Trainer.NewVisit()
        return
    end
    if event == "TRAINER_SHOW" then
        lesson = Trainer.NewVisit()
    end
    if not db().features.autoTrain then
        return  -- a trainer is never read unless the switch is on
    end
    local view = API.TrainerView()
    Trainer.Confirm(view, lesson)
    local buy = Trainer.Next(view, db().features.autoTrain, lesson)
    if buy then
        lesson.tried[buy.key] = buy.cost
        API.BuyTrainerService(buy.index)
    end
end

API.OnEvents({ "TRAINER_SHOW", "TRAINER_UPDATE", "TRAINER_CLOSED" }, function(event)
    guard("Trainer", atTrainer, event)
end)

-- ---- loot ----

local lootDone = false  -- LOOT_READY can come more than once a window

API.OnEvents({ "LOOT_READY", "LOOT_CLOSED" }, function(event, autoloot)
    guard("Loot", function()
        if event == "LOOT_CLOSED" then
            lootDone = false
            return
        end
        if lootDone or db().features.fastLoot ~= true then
            return
        end
        lootDone = true
        for _, slot in ipairs(Loot.Slots(true, autoloot, API.LootView())) do
            API.TakeLoot(slot)
        end
    end)
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

-- ---- accepts ----

-- PartyInfoDocumentation.lua's payload. Nothing is asked of the game unless a check is on.
API.OnEvents({ "PARTY_INVITE_REQUEST" }, function(_, name, isTank, isHealer, isDamage, _, _, inviterGUID,
    questSessionActive)
    guard("Accept", function()
        local features = db().features
        if not (features.acceptGuild or features.acceptFriends) then
            return
        end
        local who = API.InviterView(name, isTank or isHealer or isDamage, questSessionActive, inviterGUID)
        local line = Accept.Invite(features, who)
        if line then
            API.AcceptInvite()
            API.Later(API.HideInvitePopup)  -- after Blizzard's handler has shown it
            say(line)
        end
    end)
end)

API.OnEvents({ "CONFIRM_SUMMON" }, function(_, summonReason, skippingStartExperience)
    guard("Accept", function()
        if not db().features.acceptSummons then
            return
        end
        local line = Accept.Summon(true, API.SummonView(summonReason, skippingStartExperience))
        if line then
            API.Later(API.ConfirmSummon)  -- after Blizzard's handler has shown its popup
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

-- "This zone" changes with the map, and Hide quests above me with the
-- player's level: redraw after Blizzard's own handlers.
API.OnEvents({ "ZONE_CHANGED", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED_INDOORS", "PLAYER_LEVEL_UP" }, function()
    if trackerInstalled then
        API.Later(API.RedrawTracker)
    end
end)

-- For /gt probe, to settle what a kill looks like on this build (the spec's
-- open fact): the XP lines the game sends and each change in XP, in the order
-- they came, kept only while the switch is on.
local xpLog, lastXP = {}, nil
local killPattern, killIndex  -- from the game's format string, built at the first XP line

local function logXP(event, text)
    if db().features.killsLeft ~= true then
        return
    end
    if event == "CHAT_MSG_COMBAT_XP_GAIN" then
        local readable = API.Readable(text)
        Kills.Keep(xpLog, readable and ('msg "' .. readable .. '"') or "msg SECRET", Kills.LOG)
        -- A line in the game's own kill format is a kill, and its figure the sample.
        if not killPattern then
            killPattern, killIndex = Kills.Pattern(API.GlobalText(Kills.FORMAT))
        end
        Kills.Add(samples, Kills.Sample(readable, killPattern, killIndex))
        return
    end
    local xp, xpMax = API.PlayerXP()
    if not xp then
        return
    end
    if event == "PLAYER_XP_UPDATE" then
        if lastXP and xp >= lastXP then
            Kills.Keep(xpLog, ("xp +%d (%d to %d of %d)"):format(xp - lastXP, lastXP, xp, xpMax), Kills.LOG)
        else
            Kills.Keep(xpLog, ("xp %d of %d"):format(xp, xpMax), Kills.LOG)
        end
    end
    lastXP = xp
end

-- The events Blizzard's own XP bar redraws on (ExpBar.lua), and a loading screen.
API.OnEvents({ "PLAYER_XP_UPDATE", "PLAYER_LEVEL_UP", "PLAYER_ENTERING_WORLD" }, function(event)
    guard("Kills", logXP, event)
    redrawKills()
end)

-- ChatInfoDocumentation.lua's ChatMsgCombatXpGain; its first payload is the text.
API.OnEvents({ "CHAT_MSG_COMBAT_XP_GAIN" }, function(event, text)
    guard("Kills", logXP, event, text)
    redrawKills()
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
    local blocks, cached, dirty = API.TrackerBlocks()
    if blocks then
        local parts = {}
        for _, b in ipairs(blocks) do
            parts[#parts + 1] = ("%s top %s h %s a %s%s%s%s"):format(tostring(b.id),
                b.top and ("%.0f"):format(b.top) or "?", tostring(b.height),
                b.alpha and ("%.2f"):format(b.alpha) or "?",
                b.shown and "" or " hidden", b.cached and " cached" or "", b.inChain and "" or " unchained")
        end
        say(("Probe: tracker blocks (%s cached%s): %s."):format(tostring(cached),
            dirty and ", stuck dirty" or "", #parts > 0 and table.concat(parts, "; ") or "none"))
    end
    local asked, answered = API.MapHoverCounts()
    local hover
    if asked == 0 then
        hover = "not asked yet this session (open the world map and hover a zone)"
    elseif answered == 0 then
        hover = ("asked %d times and NO answers: C_Map.GetMapInfoAtPosition is silent on this build"):format(asked)
    else
        hover = ("asked %d times, %d answered with a map"):format(asked, answered)
    end
    say("Probe: map readout " .. (MapReadout.Built() and "built" or "NOT built (no world map)")
        .. "; map hover " .. hover .. ".")
    say("Probe: kills readout " .. (KillsReadout.Built() and "built" or "not built yet") .. "; "
        .. #samples .. " kill sample(s).")
    if #xpLog == 0 then
        say("Probe: no XP lines yet (tick Kills to level, then kill something).")
    end
    for i, line in ipairs(xpLog) do
        say(("Probe: XP line %d: %s"):format(i, line))
    end
    -- Candidates being checked, not facts: the names Classic gave these formats.
    for _, name in ipairs({ "COMBATLOG_XPGAIN_FIRSTPERSON", "COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED",
        "COMBATLOG_XPGAIN_EXHAUSTION1" }) do
        local value = API.GlobalText(name)
        say("Probe: " .. name .. " = " .. (value and ('"' .. value .. '"') or "missing"))
    end
    local missing = API.MissingAcceptCalls()
    say("Probe: accept calls missing: " .. (#missing > 0 and table.concat(missing, ", ") or "none") .. ".")
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
        MapReadout.Create(Core)
        applyTrackerSort()
    end)
end)

-- The world map loads at startup on this build; should it ever come later,
-- the readout is built when it does.
API.OnEvents({ "ADDON_LOADED" }, function(_, name)
    if name == "Blizzard_WorldMap" then
        guard("Map", MapReadout.Create, Core)
    end
end)

SLASH_GOBLINTHINGS1 = "/gt"
SLASH_GOBLINTHINGS2 = "/goblinthings"
SlashCmdList.GOBLINTHINGS = function(msg) guard("Slash", slash, msg) end

return Core
