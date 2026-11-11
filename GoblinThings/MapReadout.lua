local _, ns = ...

-- The world map's corner readout (spec 2026-11-10-map-zone-readout-design.md):
-- up to three right-justified lines in the map's own lettering at the bottom
-- right of the map, drawing what MapInfo picks and decides nothing. Built on
-- the map's canvas container at strata HIGH, as Blizzard's area label is,
-- with the mouse off so the canvas keeps its hover. Its OnUpdate only runs
-- while the map is shown.
local MapReadout = {}
ns.MapReadout = MapReadout

MapReadout.LAYOUT = {
    RIGHT = -40,   -- clear of the quest-log toggle in the corner (32 px at -2, 1)
    BOTTOM = 10,
    WIDTH = 300,
    GAP = 2,       -- between lines
    SIZES = { 16, 13, 13 },  -- the name, then each line under it
}
local L = MapReadout.LAYOUT

local frame, lines, shownID

-- texts[i] on line i (the first in the name's size and, when it is the
-- name, its colour), stacked up from the bottom; nil hides every line.
local function draw(texts, named)
    local Look = ns.Look
    local below
    for i = #lines, 1, -1 do
        local s, text = lines[i], texts and texts[i]
        s:ClearAllPoints()
        if text then
            s:SetText(text)
            s:SetTextColor(Look.RGB((i == 1 and named) and "areaName" or "areaText"))
            local anchor, point = below or frame, below and "TOP" or "BOTTOM"
            local gap = below and L.GAP or 0
            s:SetPoint("BOTTOMLEFT", anchor, point .. "LEFT", 0, gap)
            s:SetPoint("BOTTOMRIGHT", anchor, point .. "RIGHT", 0, gap)
            s:Show()
            below = s
        else
            s:SetText("")
            s:Hide()
        end
    end
end

local function update(core, map)
    local id
    if core.Get("mapInfo") == true then
        id = ns.MapInfo.Pick(ns.API.MapUnderCursor(map))
    end
    if id == shownID then
        return
    end
    shownID = id
    local name = id and ns.API.MapName(id)
    draw(id and ns.MapInfo.Lines(id, name), name ~= nil)
end

-- Builds the readout once the world map exists; false while it does not.
function MapReadout.Create(core)
    if frame then
        return true
    end
    local map, canvas = ns.API.WorldMap()
    if not map then
        return false
    end
    local Look = ns.Look
    frame = CreateFrame("Frame", nil, canvas)
    frame:SetFrameStrata("HIGH")
    frame:EnableMouse(false)
    frame:SetSize(L.WIDTH, 1)
    frame:SetPoint("BOTTOMRIGHT", canvas, "BOTTOMRIGHT", L.RIGHT, L.BOTTOM)
    lines = {}
    for i, size in ipairs(L.SIZES) do
        local s = Look.Text(frame, Look.WORDS, size, "areaText", "OUTLINE")
        s:SetJustifyH("RIGHT")
        s:Hide()
        lines[i] = s
    end
    frame:SetScript("OnUpdate", function()
        core.Guard("Map", update, core, map)
    end)
    frame:SetScript("OnHide", function()
        shownID = nil
        draw(nil, false)
    end)
    return true
end

-- Whether the readout was built, for /gt probe.
function MapReadout.Built()
    return frame ~= nil
end

return MapReadout
