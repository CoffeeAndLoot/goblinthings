-- luacheck: globals QuestObjectiveTrackerMixin
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
        h.it("a sorter that errors or loses quests gives Blizzard's list", function()
            local API, frame = tracker()
            API.SetTrackerSort(function() error("boom") end)
            h.eq(list(frame), "a b")
            API, frame = tracker()
            API.SetTrackerSort(function() return { "a" } end)
            h.eq(list(frame), "a b")
        end)
    end)
end
