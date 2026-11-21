local _, ns = ...

-- The number above a quest mob's nameplate (spec 2026-11-21-quest-marks-on-
-- nameplates-design.md): how many of this mob are still to go, the smallest
-- across its objectives. Takes the unit's tooltip lines as API.UnitQuestLines
-- views them and decides; draws nothing. Pure: test/run.lua loads this file.
local QuestPlates = {}
ns.QuestPlates = QuestPlates

QuestPlates.KEY = "questPlates"            -- the switch
QuestPlates.SIZE_KEY = "questPlatesSize"   -- the number's font size; the "!" is a third larger

-- What one objective line still asks for: b - a from its "a/b"; 1 for an
-- unfinished line with no figures (a named one to slay, or a text the addon
-- may not read); nil when it is done.
local function left(line)
    if type(line) ~= "table" or line.kind ~= "objective" then
        return nil
    end
    local have, want = string.match(type(line.text) == "string" and line.text or "", "(%d+)%s*/%s*(%d+)")
    if not have then
        return line.completed ~= true and 1 or nil
    end
    local n = tonumber(want) - tonumber(have)
    return n > 0 and n or nil
end

-- lines = { { kind = "title" | "objective" | "other", text, completed } ... }
-- -> the smallest number still to go, or nil when nothing on this unit counts.
function QuestPlates.Remaining(lines)
    if type(lines) ~= "table" then
        return nil
    end
    local least
    for _, line in ipairs(lines) do
        local n = left(line)
        if n and (not least or n < least) then
            least = n
        end
    end
    return least
end

return QuestPlates
