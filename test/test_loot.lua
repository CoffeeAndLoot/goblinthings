return function(h, loaded)
    local Loot = loaded.ns.Loot

    local function slots(list)
        return table.concat(list, " ")
    end

    -- A loot window as API.LootView gives it.
    local view = { { slot = 1, locked = false }, { slot = 2, locked = true }, { slot = 3, locked = false } }

    h.describe("Loot.Slots", function()
        h.it("takes every unlocked slot when on and the game is auto-looting", function()
            h.eq(slots(Loot.Slots(true, true, view)), "1 3")
        end)
        h.it("takes nothing when the switch is off", function()
            h.eq(#Loot.Slots(false, true, view), 0)
            h.eq(#Loot.Slots(nil, true, view), 0)
        end)
        h.it("takes nothing when the game is not auto-looting (or will not say)", function()
            h.eq(#Loot.Slots(true, false, view), 0)
            h.eq(#Loot.Slots(true, nil, view), 0)
        end)
        h.it("a slot the game would not describe is left to the player", function()
            h.eq(slots(Loot.Slots(true, true, { { slot = 1 }, { slot = 2, locked = false } })), "2")
        end)
        h.it("an empty window takes nothing", function()
            h.eq(#Loot.Slots(true, true, {}), 0)
        end)
    end)
end
