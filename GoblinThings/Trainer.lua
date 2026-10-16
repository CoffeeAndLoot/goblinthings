local _, ns = ...

-- What to train at a trainer window: everything available that the gold
-- covers, one purchase per TRAINER_UPDATE, in the trainer's own order. Never a
-- service that takes a profession slot (GetTrainerServiceCost's isProfession,
-- which Blizzard_TrainerUI greys out once both slots are used), never at a pet
-- trainer. Pure: API.lua reads the window into a plain view and buys; Core
-- keeps the visit and says the line. A gossip window holding only "Train me"
-- is answered too (Trainer.GossipPick).
--
-- view = { shift, trainerType, money, services = { { index, name, rank,
--   type, cost, isProfession } ... } }   (nil wherever the game gave no answer)
-- visit = Trainer.NewVisit()
local Trainer = {}
ns.Trainer = Trainer

Trainer.PET = 3 -- Enum.TrainerType.Pet
Trainer.ICON = 132058 -- a trainer's gossip option icon (seen in game 2026-10-16: Tarn's "Train me.")

-- The orderIndex of a gossip window's one option when it is a trainer's and
-- nothing else is on offer, as Blizzard's GossipFrame skips an option flagged
-- selectOptionWhenOnlyOption; nil otherwise. view = NpcView("gossip").
function Trainer.GossipPick(view, autoTrain)
    local options = view.options
    if not autoTrain or view.numActive ~= 0 or view.numAvailable ~= 0 or type(options) ~= "table"
        or #options ~= 1 then
        return nil
    end
    local o = options[1]
    if o.icon == Trainer.ICON and o.status == 0 and type(o.orderIndex) == "number" then
        return o.orderIndex
    end
    return nil
end

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

-- Marks as learned each service tried this visit that the list no longer
-- offers: shown as used, or gone (the trainer's Used filter hides learned
-- rows; seen in game 2026-10-16). A refused purchase stays available. A list
-- the game would not count (services nil) confirms nothing.
function Trainer.Confirm(view, visit)
    if type(view.services) ~= "table" then
        return
    end
    local offered = {}
    for _, s in ipairs(view.services) do
        if type(s.name) == "string" and s.type == "available" then
            offered[Trainer.Key(s)] = true
        end
    end
    for key, cost in pairs(visit.tried) do
        if not offered[key] then
            visit.learned[key] = cost
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
