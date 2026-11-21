local _, ns = ...

-- The mark above a quest mob's nameplate (spec 2026-11-21-quest-marks-on-
-- nameplates-design.md): a small gold square and the number Core hands it,
-- one mouse-off frame per plate frame, kept for the plate's next tenant (the
-- game recycles its plates). Draws and decides nothing. The plate's own
-- scale and fade carry the mark with them.
local PlateMarks = {}
ns.PlateMarks = PlateMarks

PlateMarks.LAYOUT = {
    SQUARE = 10,  -- the gold square's side
    GAP = 2,      -- between the plate's top and the mark
    PAD = 3,      -- between the square and the number
    SIZE = 12,    -- the number's font size
    HEIGHT = 14,
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
    local square = CreateFrame("Frame", nil, mark)
    square:SetSize(L.SQUARE, L.SQUARE)
    square:SetPoint("LEFT", mark, "LEFT", 0, 0)
    Look.Texture(square, "ARTWORK", Look.COLOUR.gold):SetAllPoints(square)
    Look.Outline(square, Look.COLOUR.rim, "OVERLAY")
    mark.text = Look.Text(mark, Look.WORDS, L.SIZE, "text", "OUTLINE")
    mark.text:SetShadowOffset(0, 0)  -- the outline carries it over any ground
    mark.text:SetPoint("LEFT", square, "RIGHT", L.PAD, 0)
    marks[plate] = mark
    return mark
end

-- The number n above this plate.
function PlateMarks.Show(plate, n)
    local mark = marks[plate] or build(plate)
    mark.text:SetText(tostring(n))
    mark:SetWidth(L.SQUARE + L.PAD + mark.text:GetStringWidth())
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
