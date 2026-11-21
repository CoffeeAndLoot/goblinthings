local _, ns = ...

-- The mark above a quest mob's nameplate (spec 2026-11-21-quest-marks-on-
-- nameplates-design.md): a gold "!" and the number Core hands it,
-- one mouse-off frame per plate frame, kept for the plate's next tenant (the
-- game recycles its plates). Draws and decides nothing. The plate's own
-- scale and fade carry the mark with them.
local PlateMarks = {}
ns.PlateMarks = PlateMarks

PlateMarks.LAYOUT = {
    BANG = 16,    -- the "!"'s font size (a square read as a box, the owner 2026-11-21)
    GAP = 2,      -- between the plate's top and the mark
    PAD = 3,      -- between the "!" and the number
    SIZE = 12,    -- the number's font size
    HEIGHT = 16,
}
local L = PlateMarks.LAYOUT

local marks = setmetatable({}, { __mode = "k" })  -- plate frame -> its mark

local function build(plate)
    local Look = ns.Look
    local mark = CreateFrame("Frame", nil, plate)
    mark:EnableMouse(false)
    mark:SetFrameLevel(plate:GetFrameLevel() + 5)
    mark:SetHeight(L.HEIGHT)
    mark:SetPoint("BOTTOM", plate, "TOP", 0, L.GAP)
    mark.bang = Look.Text(mark, Look.WORDS, L.BANG, "gold", "OUTLINE")
    mark.bang:SetShadowOffset(0, 0)  -- the outline carries it over any ground
    mark.bang:SetText("!")
    mark.bang:SetPoint("LEFT", mark, "LEFT", 0, 0)
    mark.text = Look.Text(mark, Look.WORDS, L.SIZE, "text", "OUTLINE")
    mark.text:SetShadowOffset(0, 0)
    mark.text:SetPoint("LEFT", mark.bang, "RIGHT", L.PAD, 0)
    marks[plate] = mark
    return mark
end

-- The number n above this plate.
function PlateMarks.Show(plate, n)
    local mark = marks[plate] or build(plate)
    mark.text:SetText(tostring(n))
    mark:SetWidth(mark.bang:GetStringWidth() + L.PAD + mark.text:GetStringWidth())
    mark:Show()
end

function PlateMarks.Hide(plate)
    local mark = marks[plate]
    if mark then
        mark:Hide()
    end
end

function PlateMarks.HideAll()
    for _, mark in pairs(marks) do
        mark:Hide()
    end
end

-- How many marks are showing, for /gt probe.
function PlateMarks.Count()
    local n = 0
    for _, mark in pairs(marks) do
        if mark:IsShown() then
            n = n + 1
        end
    end
    return n
end

return PlateMarks
