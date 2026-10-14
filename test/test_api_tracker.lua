-- luacheck: globals QuestObjectiveTrackerMixin C_QuestLog
-- API.SetTrackerSort against a stand-in tracker. The frame gets copies of the
-- mixin's methods, as XML mixin= does (no __index back to the mixin), so a
-- method set to nil on the frame is gone.
return function(h)
    local function tracker()
        local mixin = { BuildQuestWatchInfos = function(_self) return { "a", "b" } end }
        local frame = { BuildQuestWatchInfos = mixin.BuildQuestWatchInfos, MarkDirty = function() end }
        QuestObjectiveTrackerMixin, QuestObjectiveTracker = mixin, frame
        local ns = {}
        assert(loadfile("GoblinThings/API.lua"))("GoblinThings", ns)
        return ns.API, frame
    end

    -- The frame's list as the tracker would ask for it; the globals cleared either way.
    local function list(frame)
        local ok, infos = pcall(frame.BuildQuestWatchInfos, frame)
        QuestObjectiveTrackerMixin, QuestObjectiveTracker = nil, nil
        return ok and table.concat(infos, " ") or ("error: " .. tostring(infos))
    end

    local function reverse(infos)
        return { infos[2], infos[1] }
    end

    h.describe("API.TrackerFacts", function()
        -- IsOnMap says yes to everything, as it did for Stonetalon quests in the
        -- Crossroads; "here" (TrackerSort.HereSet) must decide instead.
        local function facts(id, here)
            C_QuestLog = {
                GetLogIndexForQuestID = function() return nil end,
                IsComplete = function() return false end,
                IsOnMap = function() return true end,
            }
            local ns = {}
            assert(loadfile("GoblinThings/API.lua"))("GoblinThings", ns)
            local result = ns.API.TrackerFacts({ GetID = function() return id end }, here)
            C_QuestLog = nil
            return result
        end
        h.it("a quest in the here set is on the map; one outside it is not", function()
            h.eq(facts(878, { [878] = true }).onMap, true)
            h.eq(facts(1060, { [878] = true }).onMap, false)
        end)
        h.it("no here set (the game gave no answer) is nil, so Only this zone keeps it", function()
            h.eq(facts(878, nil).onMap, nil)
        end)
    end)

    h.describe("API.SetTrackerSort", function()
        h.it("a sorter reorders Blizzard's list", function()
            local API, frame = tracker()
            API.SetTrackerSort(reverse)
            h.eq(list(frame), "b a")
        end)
        h.it("turning the sort off leaves the tracker drawing Blizzard's list, method intact", function()
            local API, frame = tracker()
            API.SetTrackerSort(reverse)
            API.SetTrackerSort(nil)
            h.eq(list(frame), "a b")
        end)
        h.it("a sorter that errors gives Blizzard's list", function()
            local API, frame = tracker()
            API.SetTrackerSort(function() error("boom") end)
            h.eq(list(frame), "a b")
        end)
        h.it("a filter may show fewer quests, or none", function()
            local API, frame = tracker()
            API.SetTrackerSort(function(infos) return { infos[2] } end)
            h.eq(list(frame), "b")
            API, frame = tracker()
            API.SetTrackerSort(function() return {} end)
            h.eq(list(frame), "")
        end)
        h.it("a quest Blizzard did not give, or one shown twice, gives Blizzard's list", function()
            local API, frame = tracker()
            API.SetTrackerSort(function() return { "a", "z" } end)
            h.eq(list(frame), "a b")
            API, frame = tracker()
            API.SetTrackerSort(function() return { "a", "a" } end)
            h.eq(list(frame), "a b")
        end)
    end)
end
