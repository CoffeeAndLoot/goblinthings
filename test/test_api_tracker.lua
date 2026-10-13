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
        -- IsOnMap answers false, true or nothing for quest 5, 6 and 7.
        local function facts(id)
            local onMap = { [5] = false, [6] = true }
            C_QuestLog = {
                GetLogIndexForQuestID = function() return nil end,
                IsComplete = function() return false end,
                IsOnMap = function(questID) return onMap[questID] end,
            }
            local ns = {}
            assert(loadfile("GoblinThings/API.lua"))("GoblinThings", ns)
            local result = ns.API.TrackerFacts({ GetID = function() return id end })
            C_QuestLog = nil
            return result
        end
        h.it("keeps the game's no as false, so Only this zone hides the quest", function()
            h.eq(facts(5).onMap, false)
        end)
        h.it("keeps the game's yes, and no answer as nil", function()
            h.eq(facts(6).onMap, true)
            h.eq(facts(7).onMap, nil)
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
