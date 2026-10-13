return function(h, loaded)
    local Vendor = loaded.ns.Vendor
    local ON = { autoSellJunk = true, autoRepair = true }

    -- slot() and view() cannot express nil overrides (pairs skips nil); clear the field afterwards.
    local function slot(bag, s, quality, over)
        local t = { bag = bag, slot = s, quality = quality, hasNoValue = false, locked = false, count = 1, price = 10 }
        for k, v in pairs(over or {}) do t[k] = v end
        return t
    end

    local function view(over)
        local v = { shift = false, slots = {}, canRepair = false, repairCost = 0, money = 0 }
        for k, x in pairs(over or {}) do v[k] = x end
        return v
    end

    h.describe("Vendor.Money", function()
        h.it("formats copper, silver and gold, leaving out zero parts", function()
            h.eq(Vendor.Money(5), "5c")
            h.eq(Vendor.Money(205), "2s 5c")
            h.eq(Vendor.Money(10005), "1g 5c")
            h.eq(Vendor.Money(10200), "1g 2s")
            h.eq(Vendor.Money(0), "0c")
        end)
    end)

    h.describe("Vendor.Plan", function()
        h.it("sells only gray, valued, unlocked slots", function()
            local p = Vendor.Plan(view({ slots = {
                slot(0, 1, 0), slot(0, 2, 1), slot(1, 3, 0, { hasNoValue = true }),
                slot(2, 4, 0, { locked = true }), slot(3, 5, 0, { count = 4, price = 25 }),
            } }), ON)
            h.eq(#p.sell, 2)
            h.eq(p.sell[1].bag, 0); h.eq(p.sell[1].slot, 1)
            h.eq(p.sell[2].bag, 3); h.eq(p.sell[2].slot, 5)
            h.eq(p.line, "Sold 2 junk for 1s 10c.")
        end)
        h.it("skips a slot with no quality (no answer)", function()
            local p = Vendor.Plan(view({ slots = { slot(0, 1, nil) } }), ON)
            h.eq(#p.sell, 0)
            h.eq(p.line, nil)
        end)
        h.it("says no value when a price is unknown", function()
            local p = Vendor.Plan(view({ slots = { slot(0, 1, 0), slot(0, 2, 0, { price = false }) } }), ON)
            h.eq(p.line, "Sold 2 junk.")
        end)
        h.it("does nothing with Shift held", function()
            local p = Vendor.Plan(view({ shift = true, slots = { slot(0, 1, 0) }, canRepair = true,
                repairCost = 300, money = 1000 }), ON)
            h.eq(#p.sell, 0); h.falsy(p.repair); h.eq(p.line, nil)
        end)
        h.it("honours each switch on its own", function()
            local v = view({ slots = { slot(0, 1, 0) }, canRepair = true, repairCost = 300, money = 1000 })
            local a = Vendor.Plan(v, { autoSellJunk = false, autoRepair = true })
            h.eq(#a.sell, 0); h.truthy(a.repair); h.eq(a.line, "Repaired for 3s.")
            local b = Vendor.Plan(v, { autoSellJunk = true, autoRepair = false })
            h.eq(#b.sell, 1); h.falsy(b.repair); h.eq(b.line, "Sold 1 junk for 10c.")
        end)
        h.it("repairs only at a repairing vendor, for a cost, with the gold", function()
            h.falsy(Vendor.Plan(view({ canRepair = false, repairCost = 300, money = 1000 }), ON).repair)
            h.falsy(Vendor.Plan(view({ canRepair = true, repairCost = 0, money = 1000 }), ON).repair)
            h.eq(Vendor.Plan(view({ canRepair = true, repairCost = 0, money = 1000 }), ON).line, nil)
            h.truthy(Vendor.Plan(view({ canRepair = true, repairCost = 300, money = 300 }), ON).repair)
            local short = Vendor.Plan(view({ canRepair = true, repairCost = 300, money = 299 }), ON)
            h.falsy(short.repair)
            h.eq(short.line, "Not enough gold to repair (costs 3s).")
        end)
        h.it("puts a sale and a repair on one line", function()
            local p = Vendor.Plan(view({ slots = { slot(0, 1, 0) }, canRepair = true, repairCost = 300,
                money = 1000 }), ON)
            h.eq(p.line, "Sold 1 junk for 10c. Repaired for 3s.")
        end)
        h.it("treats a nil cost or nil money as no repair", function()
            local v = view({ canRepair = true, money = 1000 })
            v.repairCost = nil -- view() cannot express a nil override, so clear it after
            local a = Vendor.Plan(v, ON)
            h.falsy(a.repair); h.eq(a.line, nil)
            local w = view({ canRepair = true, repairCost = 300 })
            w.money = nil
            local b = Vendor.Plan(w, ON)
            h.falsy(b.repair); h.eq(b.line, nil)
        end)
    end)
end
