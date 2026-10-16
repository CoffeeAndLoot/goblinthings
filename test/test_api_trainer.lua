-- luacheck: globals C_Trainer GetMoney GetNumTrainerServices GetTrainerServiceInfo GetTrainerServiceCost
-- API.TrainerView against stand-in game calls: the slot flag reads as a
-- plain boolean, and a row the game will not describe is no answer.
return function(h)
    local function view(rows)
        C_Trainer = { GetTrainerType = function() return 0 end }
        GetMoney = function() return 500 end
        GetNumTrainerServices = function() return #rows end
        GetTrainerServiceInfo = function(i) return rows[i].name, rows[i].type, "icon", 10, rows[i].rank end
        GetTrainerServiceCost = function(i) return rows[i].cost, rows[i].isProfession end
        local ns = {}
        assert(loadfile("GoblinThings/API.lua"))("GoblinThings", ns)
        local out = ns.API.TrainerView()
        _G.C_Trainer, _G.GetMoney, _G.GetNumTrainerServices = nil, nil, nil  -- must not leak into the next suite
        _G.GetTrainerServiceInfo, _G.GetTrainerServiceCost = nil, nil
        return out
    end

    h.describe("API.TrainerView", function()
        h.it("no count from the game is no list, not an empty one", function()
            GetNumTrainerServices = function() return nil end
            local ns = {}
            assert(loadfile("GoblinThings/API.lua"))("GoblinThings", ns)
            local out = ns.API.TrainerView()
            _G.GetNumTrainerServices = nil
            h.eq(out.services, nil)
        end)
        h.it("reads the type, gold and each row", function()
            local out = view({ { name = "Thorns", type = "available", rank = "Rank 2", cost = 100 } })
            h.eq(out.trainerType, 0)
            h.eq(out.money, 500)
            local s = out.services[1]
            h.eq(s.index, 1); h.eq(s.name, "Thorns"); h.eq(s.rank, "Rank 2")
            h.eq(s.type, "available"); h.eq(s.cost, 100); h.eq(s.isProfession, false)
        end)
        h.it("the slot flag is true for true or a count, false for nil, false or 0", function()
            local out = view({ { isProfession = true }, { isProfession = 1 }, { isProfession = 0 }, {} })
            h.eq(out.services[1].isProfession, true)
            h.eq(out.services[2].isProfession, true)
            h.eq(out.services[3].isProfession, false)
            h.eq(out.services[4].isProfession, false)
        end)
        h.it("a row with no name or cost from the game is no answer", function()
            local s = view({ { type = "available" } }).services[1]
            h.eq(s.name, nil)
            h.eq(s.cost, nil)
        end)
    end)
end
