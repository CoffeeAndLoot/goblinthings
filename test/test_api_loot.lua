-- luacheck: globals GetNumLootItems GetLootSlotInfo
-- API.LootView against stand-in game calls: an unlocked slot must stay false,
-- not turn into nil ("no answer").
return function(h)
    local function view(n, lockedBySlot, texture)
        GetNumLootItems = function() return n end
        GetLootSlotInfo = function(slot)
            return texture, "Item " .. slot, 1, nil, 1, lockedBySlot[slot]
        end
        local ns = {}
        assert(loadfile("GoblinThings/API.lua"))("GoblinThings", ns)
        local out = ns.API.LootView()
        _G.GetNumLootItems, _G.GetLootSlotInfo = nil, nil  -- must not leak into the next suite
        return out
    end

    h.describe("API.LootView", function()
        h.it("lists each slot with its lock; unlocked stays false", function()
            local out = view(2, { [1] = false, [2] = true }, "icon")
            h.eq(#out, 2)
            h.eq(out[1].slot, 1)
            h.eq(out[1].locked, false)
            h.eq(out[2].locked, true)
        end)
        h.it("the lock reads truthy as LootFrame does: nil is unlocked", function()
            h.eq(view(1, {}, "icon")[1].locked, false)
        end)
        h.it("a slot the game will not describe is no answer", function()
            h.eq(view(1, { [1] = false }, nil)[1].locked, nil)
        end)
        h.it("no count from the game is an empty window", function()
            h.eq(#view(nil, {}, "icon"), 0)
        end)
    end)
end
