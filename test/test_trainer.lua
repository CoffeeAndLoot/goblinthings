return function(h, loaded)
    local Trainer = loaded.ns.Trainer
    local CLASS = 0 -- Enum.TrainerType.General

    local function service(index, name, over)
        local s = { index = index, name = name, rank = "Rank 2", type = "available", cost = 100,
            isProfession = false }
        for k, v in pairs(over or {}) do s[k] = v end
        return s
    end

    local function view(services, over)
        local v = { shift = false, trainerType = CLASS, money = 1000, services = services }
        for k, x in pairs(over or {}) do v[k] = x end
        return v
    end

    h.describe("Trainer.Next", function()
        h.it("picks the first available service the gold covers", function()
            local buy = Trainer.Next(view({
                service(1, "Moonfire", { type = "used" }),
                service(2, "Rejuvenation", { type = "unavailable" }),
                service(3, "Wrath", { cost = 5000 }),
                service(4, "Thorns"),
            }), true, Trainer.NewVisit())
            h.eq(buy.index, 4)
            h.eq(buy.key, "Thorns|Rank 2")
            h.eq(buy.cost, 100)
        end)
        h.it("skips what this visit already tried, so a stale list cannot buy twice", function()
            local visit = Trainer.NewVisit()
            visit.tried["Thorns|Rank 2"] = 100
            local buy = Trainer.Next(view({ service(1, "Thorns"), service(2, "Wrath") }), true, visit)
            h.eq(buy.index, 2)
        end)
        h.it("never takes up a new profession", function()
            h.eq(Trainer.Next(view({ service(1, "Apprentice Mining", { isProfession = true }) }), true,
                Trainer.NewVisit()), nil)
        end)
        h.it("leaves pet trainers alone", function()
            h.eq(Trainer.Next(view({ service(1, "Growl") }, { trainerType = Trainer.PET }), true,
                Trainer.NewVisit()), nil)
        end)
        h.it("does nothing when off", function()
            h.eq(Trainer.Next(view({ service(1, "Thorns") }), false, Trainer.NewVisit()), nil)
        end)
        h.it("Shift holds the rest of the visit, even once let go", function()
            local visit = Trainer.NewVisit()
            h.eq(Trainer.Next(view({ service(1, "Thorns") }, { shift = true }), true, visit), nil)
            h.eq(Trainer.Next(view({ service(1, "Thorns") }), true, visit), nil)
        end)
        h.it("an unknown trainer type, gold or cost is no answer", function()
            local s = { service(1, "Thorns") }
            local function none(over) return Trainer.Next(view(s, over), true, Trainer.NewVisit()) end
            local v = view(s); v.trainerType = nil
            h.eq(Trainer.Next(v, true, Trainer.NewVisit()), nil)
            v = view(s); v.money = nil
            h.eq(Trainer.Next(v, true, Trainer.NewVisit()), nil)
            h.eq(none({ services = { service(1, "Thorns", { cost = false }) } }), nil)
            h.eq(none({ services = { service(1, false) } }), nil)
        end)
        h.it("a free service is bought", function()
            h.eq(Trainer.Next(view({ service(1, "Thorns", { cost = 0 }) }, { money = 0 }), true,
                Trainer.NewVisit()).index, 1)
        end)
    end)

    h.describe("Trainer.Confirm and Trainer.Line", function()
        h.it("counts only tried services the list now shows as learned", function()
            local visit = Trainer.NewVisit()
            visit.tried["Thorns|Rank 2"] = 10000
            visit.tried["Wrath|Rank 2"] = 2000
            Trainer.Confirm(view({
                service(1, "Thorns", { type = "used" }),
                service(2, "Wrath"),  -- refused or not yet landed
                service(3, "Moonfire", { type = "used" }),  -- learned before this visit
            }), visit)
            h.eq(Trainer.Line(visit), "Trained 1 for 1g.")
        end)
        h.it("says nothing when nothing was learned", function()
            h.eq(Trainer.Line(Trainer.NewVisit()), nil)
        end)
    end)
end
