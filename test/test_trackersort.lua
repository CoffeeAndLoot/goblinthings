return function(h, loaded)
    local TrackerSort = loaded.ns.TrackerSort

    local function q(index, level, finished, onMap)
        return { index = index, level = level, finished = finished, onMap = onMap }
    end

    local function order(entries, tiers)
        local out = {}
        for i, e in ipairs(TrackerSort.Order(entries, tiers)) do
            out[i] = e.index
        end
        return table.concat(out, " ")
    end

    h.describe("TrackerSort.Tiers", function()
        h.it("all None is no tiers: the sort is off", function()
            h.eq(#TrackerSort.Tiers({ sortFirst = "none", sortSecond = "none", sortThird = "none" }), 0)
            h.eq(#TrackerSort.Tiers({}), 0)
        end)
        h.it("keeps the set tiers in slot order and skips None and junk", function()
            local tiers = TrackerSort.Tiers({ sortFirst = "zone", sortSecond = "none", sortThird = "level" })
            h.eq(table.concat(tiers, " "), "zone level")
            h.eq(#TrackerSort.Tiers({ sortFirst = "sideways" }), 0)
        end)
        h.it("knows its three slots", function()
            h.truthy(TrackerSort.IsSlot("sortSecond"))
            h.falsy(TrackerSort.IsSlot("autoAccept"))
        end)
    end)

    h.describe("TrackerSort.Assign", function()
        h.it("taking a key another slot holds clears that slot to None", function()
            local c = TrackerSort.Assign({ sortFirst = "level", sortSecond = "none", sortThird = "zone" },
                "sortSecond", "level")
            h.eq(c.sortSecond, "level")
            h.eq(c.sortFirst, "none")
            h.eq(c.sortThird, nil)
        end)
        h.it("None never clears another slot", function()
            local c = TrackerSort.Assign({ sortFirst = "none", sortSecond = "level" }, "sortThird", "none")
            h.eq(c.sortThird, "none")
            h.eq(c.sortFirst, nil)
            h.eq(c.sortSecond, nil)
        end)
        h.it("re-picking a slot's own key changes nothing else", function()
            local c = TrackerSort.Assign({ sortFirst = "level" }, "sortFirst", "level")
            h.eq(c.sortFirst, "level")
            h.eq(c.sortSecond, nil)
        end)
    end)

    h.describe("TrackerSort.Less", function()
        h.it("level: lower first", function()
            h.truthy(TrackerSort.Less(q(2, 10), q(1, 12), { "level" }))
            h.falsy(TrackerSort.Less(q(1, 12), q(2, 10), { "level" }))
        end)
        h.it("level: an unknown level sorts after every known one", function()
            h.truthy(TrackerSort.Less(q(2, 60), q(1, nil), { "level" }))
            h.falsy(TrackerSort.Less(q(1, nil), q(2, 60), { "level" }))
            h.truthy(TrackerSort.Less(q(1, nil), q(2, nil), { "level" }))
        end)
        h.it("finished first; unknown counts as not finished", function()
            h.truthy(TrackerSort.Less(q(2, 10, true), q(1, 10, false), { "finished" }))
            h.truthy(TrackerSort.Less(q(2, 10, true), q(1, 10, nil), { "finished" }))
        end)
        h.it("this zone first; unknown counts as elsewhere", function()
            h.truthy(TrackerSort.Less(q(2, 10, false, true), q(1, 10, false, nil), { "zone" }))
        end)
        h.it("every tier tied: Blizzard's order", function()
            h.truthy(TrackerSort.Less(q(1, 10, true, true), q(2, 10, true, true), { "level", "finished", "zone" }))
            h.falsy(TrackerSort.Less(q(2, 10), q(1, 10), {}))
        end)
    end)

    h.describe("TrackerSort.Order", function()
        h.it("steps down the tiers: this zone, then finished, then level", function()
            local entries = {
                q(1, 10, false, true), q(2, 12, true, true), q(3, 5, true, false),
                q(4, 3, false, false), q(5, 8, false, true),
            }
            h.eq(order(entries, { "zone", "finished", "level" }), "2 5 1 3 4")
        end)
        h.it("no tiers keeps Blizzard's order", function()
            h.eq(order({ q(1, 30), q(2, 10), q(3, 20) }, {}), "1 2 3")
        end)
        h.it("returns a new list and leaves Blizzard's untouched", function()
            local entries = { q(1, 30), q(2, 10) }
            local sorted = TrackerSort.Order(entries, { "level" })
            h.eq(sorted[1].index, 2)
            h.eq(entries[1].index, 1)
        end)
    end)
end
