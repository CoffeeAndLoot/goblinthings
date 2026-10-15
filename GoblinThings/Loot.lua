local _, ns = ...

-- Fast loot (Loot): when the game is auto-looting, take every slot at once
-- instead of at the loot window's pace. autoloot is LOOT_READY's own flag, so
-- Blizzard's Auto Loot setting and its Shift toggle decide; a locked slot (a
-- group roll) stays for the player. Pure: Core has API take each slot.
local Loot = {}
ns.Loot = Loot

-- view: API.LootView's { { slot, locked } ... }. Slot numbers to take.
function Loot.Slots(on, autoloot, view)
    local out = {}
    if on ~= true or autoloot ~= true then
        return out
    end
    for _, entry in ipairs(view) do
        if entry.locked == false then
            out[#out + 1] = entry.slot
        end
    end
    return out
end

return Loot
