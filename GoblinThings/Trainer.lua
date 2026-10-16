local _, ns = ...

-- What to train at a trainer window: everything available that the gold
-- covers, one purchase per TRAINER_UPDATE, in the trainer's own order. Never a
-- service that takes a profession slot (GetTrainerServiceCost's isProfession,
-- which Blizzard_TrainerUI greys out once both slots are used), never at a pet
-- trainer. Pure: API.lua reads the window into a plain view and buys; Core
-- keeps the visit and says the line.
--
-- view = { shift, trainerType, money, services = { { index, name, rank,
--   type, cost, isProfession } ... } }   (nil wherever the game gave no answer)
-- visit = Trainer.NewVisit()
local Trainer = {}
ns.Trainer = Trainer

Trainer.PET = 3 -- Enum.TrainerType.Pet

function Trainer.NewVisit()
    return { held = false, tried = {}, learned = {} }  -- tried/learned: key -> cost
end

-- One service across list refreshes: the index moves as rows change.
function Trainer.Key(s)
    return s.name .. "|" .. (s.rank or "")
end

local function buyable(s, money, visit)
    return type(s.name) == "string" and s.type == "available" and not s.isProfession
        and type(s.cost) == "number" and s.cost <= money and not visit.tried[Trainer.Key(s)]
end

-- Marks the services tried this visit that the list now shows as learned.
function Trainer.Confirm(view, visit)
    for _, s in ipairs(view.services or {}) do
        if type(s.name) == "string" and s.type == "used" then
            local key = Trainer.Key(s)
            if visit.tried[key] then
                visit.learned[key] = visit.tried[key]
            end
        end
    end
end

-- The next service to buy as { index, key, cost }, or nil.
function Trainer.Next(view, autoTrain, visit)
    visit.held = visit.held or view.shift == true  -- Shift at any point keeps the rest of the visit manual
    if not autoTrain or visit.held then
        return nil
    end
    if type(view.trainerType) ~= "number" or view.trainerType == Trainer.PET or type(view.money) ~= "number" then
        return nil
    end
    for _, s in ipairs(view.services or {}) do
        if buyable(s, view.money, visit) then
            return { index = s.index, key = Trainer.Key(s), cost = s.cost }
        end
    end
    return nil
end

-- "Trained 3 for 1g 20s." for what the list confirmed, or nil for nothing.
function Trainer.Line(visit)
    local n, cost = 0, 0
    for _, c in pairs(visit.learned) do
        n, cost = n + 1, cost + c
    end
    if n == 0 then
        return nil
    end
    return ("Trained %d for %s."):format(n, ns.Vendor.Money(cost))
end

return Trainer
