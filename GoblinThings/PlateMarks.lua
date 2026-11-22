local _, ns = ...

-- The mark above a quest mob's nameplate (spec 2026-11-21-quest-marks-on-
-- nameplates-design.md): a gold "!" and the number Core hands it,
-- one mouse-off frame per plate frame, kept for the plate's next tenant (the
-- game recycles its plates). Draws and decides nothing. The plate's own
-- scale and fade carry the mark with them.
local PlateMarks = {}
ns.PlateMarks = PlateMarks

PlateMarks.LAYOUT = {
    BANG = 4 / 3,  -- the "!"'s font size over the number's (a square read as a box, the owner 2026-11-21)
    GAP = 1,       -- between the name (or the plate's top) and the mark
    PAD = 3,       -- between the "!" and the number
}
local L = PlateMarks.LAYOUT

local marks = setmetatable({}, { __mode = "k" })  -- plate frame -> its mark

local function build(plate)
    local Look = ns.Look
    local mark = CreateFrame("Frame", nil, plate)
    mark:EnableMouse(false)
    mark:SetFrameLevel(plate:GetFrameLevel() + 5)
    mark.size = 0  -- the number's font size last set; the fonts are set on change only
    mark.bang = Look.Text(mark, Look.WORDS, 12, "gold", "OUTLINE")
    mark.bang:SetShadowOffset(0, 0)  -- the outline carries it over any ground
    mark.bang:SetText("!")
    mark.bang:SetPoint("LEFT", mark, "LEFT", 0, 0)
    mark.text = Look.Text(mark, Look.WORDS, 12, "text", "OUTLINE")
    mark.text:SetShadowOffset(0, 0)
    mark.text:SetPoint("LEFT", mark.bang, "RIGHT", L.PAD, 0)
    marks[plate] = mark
    return mark
end

-- The number n above this plate (a bare "!" when it is 1: the owner,
-- 2026-11-22): just over `name` (its name text, when the
-- game gives it; it may differ from last time's, so the anchor is set at every
-- show) or over the plate itself (it is taller than its bar, so the mark then
-- floats; the owner 2026-11-21). `size` is the number's font size (the
-- questPlatesSize slider); the "!" is a third larger.
function PlateMarks.Show(plate, n, name, size)
    local mark = marks[plate] or build(plate)
    if size ~= mark.size then
        mark.size = size
        local bang = math.floor(size * L.BANG + 0.5)
        -- SetFont answers false for a face it cannot load; the words then keep their fallback font.
        mark.bang:SetFont(ns.Look.WORDS, bang, "OUTLINE")
        mark.text:SetFont(ns.Look.WORDS, size, "OUTLINE")
        mark:SetHeight(bang)
    end
    mark:ClearAllPoints()
    mark:SetPoint("BOTTOM", name or plate, "TOP", 0, L.GAP)
    if n > 1 then
        mark.text:SetText(tostring(n))
        mark:SetWidth(mark.bang:GetStringWidth() + L.PAD + mark.text:GetStringWidth())
    else
        mark.text:SetText("")
        mark:SetWidth(mark.bang:GetStringWidth())
    end
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
