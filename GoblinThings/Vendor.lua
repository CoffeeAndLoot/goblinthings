local _, ns = ...

-- What to do at a vendor window (spec 2026-10-13-goblin-things-design.md,
-- Vendors; from GoblinQuest's Vendor.lua): sell the gray items and repair.
-- Pure: API.lua reads the bags and the vendor into a plain view and carries
-- out the plan; Core says the line.
--
-- view = { shift, slots = { { bag, slot, quality, hasNoValue, locked, count,
--   price } ... }, canRepair, repairCost, money }   (price per item, nil when
--   unknown; quality nil when the game gave no answer)
-- prefs = { autoSellJunk, autoRepair }
local Vendor = {}
ns.Vendor = Vendor

Vendor.POOR = 0 -- Enum.ItemQuality.Poor (gray)

-- "1g 2s 5c", zero parts left out; "0c" for nothing.
function Vendor.Money(copper)
    copper = math.max(0, math.floor(tonumber(copper) or 0))
    local g, s, c = math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100
    local parts = {}
    if g > 0 then parts[#parts + 1] = g .. "g" end
    if s > 0 then parts[#parts + 1] = s .. "s" end
    if c > 0 or #parts == 0 then parts[#parts + 1] = c .. "c" end
    return table.concat(parts, " ")
end

local function junk(s)
    return s.quality == Vendor.POOR and s.hasNoValue == false and s.locked == false
end

function Vendor.Plan(view, prefs)
    local plan = { sell = {}, repair = false }
    if view.shift then
        return plan
    end
    local said = {}
    if prefs.autoSellJunk then
        local value, known = 0, true
        for _, s in ipairs(view.slots or {}) do
            if junk(s) then
                plan.sell[#plan.sell + 1] = { bag = s.bag, slot = s.slot }
                if type(s.price) == "number" then
                    value = value + s.price * (s.count or 1)
                else
                    known = false
                end
            end
        end
        if #plan.sell > 0 then
            said[#said + 1] = known and ("Sold %d junk for %s."):format(#plan.sell, Vendor.Money(value))
                or ("Sold %d junk."):format(#plan.sell)
        end
    end
    local cost, money = view.repairCost, view.money
    if prefs.autoRepair and view.canRepair and type(cost) == "number" and cost > 0 and type(money) == "number" then
        if money >= cost then
            plan.repair = true
            said[#said + 1] = ("Repaired for %s."):format(Vendor.Money(cost))
        else
            said[#said + 1] = ("Not enough gold to repair (costs %s)."):format(Vendor.Money(cost))
        end
    end
    plan.line = #said > 0 and table.concat(said, " ") or nil
    return plan
end

return Vendor
