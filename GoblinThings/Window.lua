local _, ns = ...

-- The settings window (spec 2026-10-13-tracker-sort-and-tabs-design.md, Tabs)
-- in the Goblin look (Look.lua): a dark window with a gold top edge, a header
-- to drag it by, a strip of tabs (one per Features section), and under it one
-- inset page per tab: that section's rows, a gold sub-header over each group
-- and the section's dim note. Every page is as tall as the tallest, so
-- switching tabs never resizes the window. Rows read and write through
-- core.Get / core.Set. Plain frames, no Blizzard templates. PageHeight and
-- Height are pure; the rest makes frames only when called.
local Window = {}
ns.Window = Window

Window.NAME = "GoblinThingsWindow"  -- UISpecialFrames closes frames by name on Escape
Window.WIDTH = 520  -- six tabs at 82px each, so every tab name fits
Window.HOME = { "CENTER", "CENTER", 0, 40 }  -- where it opens until dragged
-- The plaque banner (tools/make_art.py, docs/art-spec.md): the art's own
-- pixels in the top-left of a power-of-two canvas, so the TexCoords crop the
-- rest. Its backdrop is the window colour, so it is drawn from the window's
-- left edge, HEADER tall, and simply is the header.
Window.BANNER = { file = "Interface\\AddOns\\GoblinThings\\Media\\header", w = 2000, h = 508, cw = 2048, ch = 512 }
Window.LAYOUT = {
    TOP_EDGE = 2, HEADER = 126, PAD = 16, CLOSE = 28, TAB_H = 26, WELL_PAD = 4, GROUP = 26, ROW = 40,
    NOTE = 22, INDENT = 26, CHECK = 18, SLIDER_W = 160, SLIDER_H = 16, VALUE_W = 34, CHOICE_H = 24,
    CHOICE_PAD = 20, FOOT = 62,
}
local L = Window.LAYOUT

function Window.PageHeight(section)
    local height, last = 2 * L.WELL_PAD + #section.features * L.ROW, nil
    for _, feature in ipairs(section.features) do
        if feature.group and feature.group ~= last then
            height = height + L.GROUP
        end
        last = feature.group
    end
    if section.note then
        height = height + L.NOTE
    end
    return height
end

local function tallest(sections)
    local most = 0
    for _, section in ipairs(sections) do
        most = math.max(most, Window.PageHeight(section))
    end
    return most
end

function Window.Height(sections)
    return L.TOP_EDGE + L.HEADER + L.PAD + L.TAB_H + L.PAD + tallest(sections) + L.FOOT
end

local frame
local controls = {}  -- feature key -> { feature, check } | { feature, slider, value } | { feature, buttons }
local tabs = {}      -- section name -> its tab button
local pages = {}     -- section name -> its page
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
    -- The banner carries the name and tagline; the window's text fallback
    -- stands in if the client cannot load the file.
    local B = Window.BANNER
    local banner = head:CreateTexture(nil, "ARTWORK")
    banner:SetSize(L.HEADER * B.w / B.h, L.HEADER)
    banner:SetPoint("LEFT", head, "LEFT", 0, 0)
    if banner:SetTexture(B.file) then
        banner:SetTexCoord(0, B.w / B.cw, 0, B.h / B.ch)
    else
        banner:Hide()
        local name = Look.Text(head, Look.WORDS, 17, "gold")
        name:SetPoint("TOPLEFT", head, "TOPLEFT", L.PAD, -12)
        name:SetPoint("RIGHT", close, "LEFT", -12, 0)
        name:SetText(ns.Options.NAME)
        local tagline = Look.Text(head, Look.WORDS, 10, "dim")
        tagline:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4)
        tagline:SetText("Time is money, friend.")
    end
end

-- One button per section, equal widths, borders overlapping into one strip.
local function buildTabs(core, sections, top)
    local n = #sections
    local width = math.floor((Window.WIDTH - 2 * L.PAD + (n - 1)) / n)
    for i, section in ipairs(sections) do
        local name = section.name
        local b = ns.Look.Button(frame, name, width, L.TAB_H, function()
            core.SetTab(name)
        end)
        b:SetPoint("TOPLEFT", frame, "TOPLEFT", L.PAD + (i - 1) * (width - 1), top)
        tabs[name] = b
    end
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
-- switch, each as wide as its words. Unbounded: the label is anchored inside
-- a 10 px button, so GetStringWidth would measure the clipped text.
local function choiceControl(core, r, feature)
    local Look = ns.Look
    local buttons, right = {}, nil
    for i = #feature.choices, 1, -1 do
        local choice = feature.choices[i]
        local b = Look.Button(r, feature.labels[choice], 10, L.CHOICE_H, function()
            core.Set(feature.key, choice)
        end)
        b:SetWidth(math.ceil(b.label:GetUnboundedStringWidth()) + L.CHOICE_PAD)
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

local function row(core, page, feature, y)
    local r = CreateFrame("Frame", nil, page)
    r:SetHeight(L.ROW)
    r:SetPoint("TOPLEFT", page, "TOPLEFT", L.WELL_PAD, y)
    r:SetPoint("TOPRIGHT", page, "TOPRIGHT", -L.WELL_PAD, y)
    local control = MAKERS[feature.control](core, r, feature)
    control.feature = feature
    controls[feature.key] = control
    local name = ns.Look.Text(r, ns.Look.WORDS, 13, "text")
    name:SetPoint("LEFT", r, "LEFT", L.INDENT, 0)
    name:SetText(feature.label)
end

local function groupHeader(page, name, y)
    local text = ns.Look.Text(page, ns.Look.WORDS, 12, "gold")
    text:SetPoint("TOPLEFT", page, "TOPLEFT", L.WELL_PAD + 10, y - 8)
    text:SetText(name)
end

local function note(page, words, y)
    local text = ns.Look.Text(page, ns.Look.WORDS, 10, "dim")
    text:SetPoint("TOPLEFT", page, "TOPLEFT", L.WELL_PAD + L.INDENT, y - 4)
    text:SetPoint("RIGHT", page, "RIGHT", -10, 0)
    text:SetText(words)
end

local function buildPage(core, section, top, height)
    local Look = ns.Look
    local page = CreateFrame("Frame", nil, frame)
    page:SetPoint("TOPLEFT", frame, "TOPLEFT", L.PAD, top)
    page:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -L.PAD, top)
    page:SetHeight(height)
    Look.Texture(page, "BACKGROUND", Look.COLOUR.inset):SetAllPoints(page)
    Look.Outline(page, Look.COLOUR.line)
    local y, last = -L.WELL_PAD, nil
    for _, feature in ipairs(section.features) do
        if feature.group and feature.group ~= last then
            groupHeader(page, feature.group, y)
            y = y - L.GROUP
        end
        last = feature.group
        row(core, page, feature, y)
        y = y - L.ROW
    end
    if section.note then
        note(page, section.note, y)
    end
    return page
end

local function make(core)
    local Look = ns.Look
    local sections = ns.Features.Sections()
    frame = CreateFrame("Frame", Window.NAME, UIParent)
    frame:SetSize(Window.WIDTH, Window.Height(sections))
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

    local tabTop = -(L.TOP_EDGE + L.HEADER + L.PAD)
    buildTabs(core, sections, tabTop)
    local pageTop, height = tabTop - L.TAB_H - L.PAD, tallest(sections)
    for _, section in ipairs(sections) do
        pages[section.name] = buildPage(core, section, pageTop, height)
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

-- Shows the open tab's page with its tab gold, and draws every control from
-- core.Get: checks on or off, each slider and its number (Features.SliderText;
-- the camera's CVar is read fresh, "?" when the game gives no answer), the chosen choice gold, and
-- the minimap check.
function Window.Refresh(core)
    if not frame then
        return
    end
    local open = core.Tab()
    for name, b in pairs(tabs) do
        ns.Look.Style(b, name == open and "gold" or "quiet")
    end
    for name, page in pairs(pages) do
        page:SetShown(name == open)
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
            c.value:SetText(ns.Features.SliderText(c.feature, value))
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
