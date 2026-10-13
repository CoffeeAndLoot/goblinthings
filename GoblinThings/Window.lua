local _, ns = ...

-- The settings window (spec 2026-10-13-goblin-things-design.md, Window) in the
-- Goblin look (Look.lua): a dark window with a gold top edge, a header to drag
-- it by, and one inset well holding every row of Features.LIST under gold
-- section headers. Each row reads and writes through core.Get / core.Set.
-- Plain frames, no Blizzard templates. WellHeight is pure; the rest makes
-- frames only when called, so test/run.lua loads this file.
local Window = {}
ns.Window = Window

Window.NAME = "GoblinThingsWindow"  -- UISpecialFrames closes frames by name on Escape
Window.WIDTH = 420
Window.HOME = { "CENTER", "CENTER", 0, 40 }  -- where it opens until dragged
Window.LAYOUT = {
    TOP_EDGE = 2, HEADER = 56, PAD = 16, CLOSE = 28, WELL_PAD = 4, SECTION = 28, ROW = 36, INDENT = 26,
    CHECK = 18, SLIDER_W = 160, SLIDER_H = 16, VALUE_W = 34, CHOICE_H = 24, CHOICE_PAD = 20, FOOT = 62,
}
local L = Window.LAYOUT

function Window.WellHeight(sections)
    local height = 2 * L.WELL_PAD
    for _, section in ipairs(sections) do
        height = height + L.SECTION + #section.features * L.ROW
    end
    return height
end

local frame
local controls = {}  -- feature key -> { feature, check } | { feature, slider, value } | { feature, buttons }
local minimapCheck
local refreshing = false  -- a slider moved by Refresh is not the player moving it

local function buildHeader(core)
    local Look = ns.Look
    local head = CreateFrame("Frame", nil, frame)
    head:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -L.TOP_EDGE)
    head:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -L.TOP_EDGE)
    head:SetHeight(L.HEADER)
    head:EnableMouse(true)
    head:RegisterForDrag("LeftButton")
    head:SetScript("OnDragStart", function() frame:StartMoving() end)
    head:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        -- Re-anchor TOPLEFT by where the window sits, and keep both points.
        local x, y = frame:GetLeft(), frame:GetTop()
        if x and y then
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
            core.SaveWindow("TOPLEFT", "BOTTOMLEFT", x, y)
        end
    end)
    local rule = Look.Texture(head, "BORDER", Look.COLOUR.divider)
    rule:SetHeight(1)
    rule:SetPoint("BOTTOMLEFT", head, "BOTTOMLEFT")
    rule:SetPoint("BOTTOMRIGHT", head, "BOTTOMRIGHT")

    local close = Look.IconButton(head, "close", L.CLOSE, function() frame:Hide() end, "X")
    close:SetPoint("RIGHT", head, "RIGHT", -12, 0)
    local name = Look.Text(head, Look.WORDS, 17, "gold")
    name:SetPoint("TOPLEFT", head, "TOPLEFT", L.PAD, -12)
    name:SetPoint("RIGHT", close, "LEFT", -12, 0)
    name:SetText(ns.Options.NAME)
    local tagline = Look.Text(head, Look.WORDS, 10, "dim")
    tagline:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4)
    tagline:SetPoint("RIGHT", close, "LEFT", -12, 0)
    tagline:SetText("Time is money, friend.")
end

local function checkControl(core, r, feature)
    local check = ns.Look.Check(r, L.CHECK, function()
        core.Set(feature.key, not core.Get(feature.key))
    end)
    check:SetPoint("RIGHT", r, "RIGHT", -10, 0)
    return { check = check }
end

local function sliderControl(core, r, feature)
    local Look = ns.Look
    local value = Look.Text(r, Look.WORDS, 12, "text")
    value:SetWidth(L.VALUE_W)
    value:SetJustifyH("RIGHT")
    value:SetPoint("RIGHT", r, "RIGHT", -10, 0)
    local slider = Look.Slider(r, L.SLIDER_W, L.SLIDER_H, feature.min, feature.max, feature.step, function(v)
        if not refreshing then
            core.Set(feature.key, v)
        end
    end)
    slider:SetPoint("RIGHT", value, "LEFT", -10, 0)
    return { slider = slider, value = value }
end

-- One button per choice, right to left, their borders overlapping into one
-- switch, each as wide as its words.
local function choiceControl(core, r, feature)
    local Look = ns.Look
    local buttons, right = {}, nil
    for i = #feature.choices, 1, -1 do
        local choice = feature.choices[i]
        local b = Look.Button(r, feature.labels[choice], 10, L.CHOICE_H, function()
            core.Set(feature.key, choice)
        end)
        b:SetWidth(math.ceil(b.label:GetStringWidth()) + L.CHOICE_PAD)
        if right then
            b:SetPoint("RIGHT", right, "LEFT", 1, 0)
        else
            b:SetPoint("RIGHT", r, "RIGHT", -10, 0)
        end
        buttons[choice] = b
        right = b
    end
    return { buttons = buttons }
end

local MAKERS = { check = checkControl, slider = sliderControl, choice = choiceControl }

local function row(core, well, feature, y)
    local r = CreateFrame("Frame", nil, well)
    r:SetHeight(L.ROW)
    r:SetPoint("TOPLEFT", well, "TOPLEFT", L.WELL_PAD, y)
    r:SetPoint("TOPRIGHT", well, "TOPRIGHT", -L.WELL_PAD, y)
    local control = MAKERS[feature.control](core, r, feature)
    control.feature = feature
    controls[feature.key] = control
    local name = ns.Look.Text(r, ns.Look.WORDS, 13, "text")
    name:SetPoint("LEFT", r, "LEFT", L.INDENT, 0)
    name:SetText(feature.label)
end

local function sectionHeader(well, name, y, first)
    local Look = ns.Look
    if not first then
        local rule = Look.Texture(well, "BORDER", Look.COLOUR.divider)
        rule:SetHeight(1)
        rule:SetPoint("TOPLEFT", well, "TOPLEFT", L.WELL_PAD + 10, y)
        rule:SetPoint("TOPRIGHT", well, "TOPRIGHT", -(L.WELL_PAD + 10), y)
    end
    local text = Look.Text(well, Look.WORDS, 12, "gold")
    text:SetPoint("TOPLEFT", well, "TOPLEFT", L.WELL_PAD + 10, y - 10)
    text:SetText(name)
end

local function make(core)
    local Look = ns.Look
    local sections = ns.Features.Sections()
    local wellHeight = Window.WellHeight(sections)
    frame = CreateFrame("Frame", Window.NAME, UIParent)
    frame:SetSize(Window.WIDTH, L.TOP_EDGE + L.HEADER + L.PAD + wellHeight + L.FOOT)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    Look.Texture(frame, "BACKGROUND", Look.COLOUR.window):SetAllPoints(frame)
    Look.Outline(frame, Look.COLOUR.line)
    local topEdge = Look.Texture(frame, "ARTWORK", Look.COLOUR.gold)
    topEdge:SetPoint("TOPLEFT", frame, "TOPLEFT")
    topEdge:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
    topEdge:SetHeight(L.TOP_EDGE)
    buildHeader(core)

    local well = CreateFrame("Frame", nil, frame)
    well:SetPoint("TOPLEFT", frame, "TOPLEFT", L.PAD, -(L.TOP_EDGE + L.HEADER + L.PAD))
    well:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -L.PAD, -(L.TOP_EDGE + L.HEADER + L.PAD))
    well:SetHeight(wellHeight)
    Look.Texture(well, "BACKGROUND", Look.COLOUR.inset):SetAllPoints(well)
    Look.Outline(well, Look.COLOUR.line)
    local y = -L.WELL_PAD
    for i, section in ipairs(sections) do
        sectionHeader(well, section.name, y, i == 1)
        y = y - L.SECTION
        for _, feature in ipairs(section.features) do
            row(core, well, feature, y)
            y = y - L.ROW
        end
    end

    -- Hiding the minimap button leaves /gt and Esc > Options to open this window.
    minimapCheck = Look.Check(frame, L.CHECK, function()
        core.SetMinimapShown(not core.MinimapShown())
    end)
    minimapCheck:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", L.PAD, 34)
    local checkLabel = Look.Text(frame, Look.WORDS, 12, "text")
    checkLabel:SetPoint("LEFT", minimapCheck, "RIGHT", 10, 0)
    checkLabel:SetPoint("RIGHT", frame, "RIGHT", -L.PAD, 0)
    checkLabel:SetText("Show minimap button")

    local hint = Look.Text(frame, Look.WORDS, 10, "dim")
    hint:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", L.PAD, 11)
    hint:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -L.PAD, 11)
    hint:SetText("Hold Shift at an NPC or vendor to skip.")

    frame:ClearAllPoints()
    local saved = core.Window()
    if saved then
        frame:SetPoint(saved.point, UIParent, saved.relativePoint, saved.x, saved.y)
    else
        frame:SetPoint(Window.HOME[1], UIParent, Window.HOME[2], Window.HOME[3], Window.HOME[4])
    end
    frame:Hide()
    table.insert(UISpecialFrames, Window.NAME)  -- Escape closes it
end

-- Draws every control from core.Get: checks on or off, the slider and its
-- number (the camera CVar, read fresh: "?" when the game gives no answer),
-- the chosen choice gold, and the minimap check.
function Window.Refresh(core)
    if not frame then
        return
    end
    minimapCheck.SetOn(core.MinimapShown())
    for key, c in pairs(controls) do
        local value = core.Get(key)
        if c.check then
            c.check.SetOn(value)
        elseif c.slider then
            refreshing = true
            c.slider:SetValue(value or c.feature.min)
            refreshing = false
            c.value:SetText(value and ns.Camera.Text(value) or "?")
        elseif c.buttons then
            for choice, b in pairs(c.buttons) do
                ns.Look.Style(b, choice == value and "gold" or "quiet")
            end
        end
    end
end

function Window.Toggle(core)
    if not frame then
        make(core)
    end
    if frame:IsShown() then
        frame:Hide()
        return
    end
    Window.Refresh(core)
    frame:Show()
end

return Window
