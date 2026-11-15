local _, ns = ...

-- The look: the game's own windows, drawn plain ("back to roots", 2026-11-14).
-- The palette is sampled from WoW Forever's Statistics and Professions windows:
-- warm brown panels, bronze edges, bright gold titles, white words. One colour
-- per job; the game's own font; plain frames and colour textures only. No
-- Blizzard templates or art files, so a template renamed by a patch can't
-- break them and no texture name is guessed. Used by the window, the options
-- page, the minimap button and the map readout's lists. RGB and File are
-- pure; the rest makes textures and frames only when called.
local Look = {}
ns.Look = Look

local function hex(r, g, b) return { r / 255, g / 255, b / 255 } end

Look.COLOUR = {
    inset = hex(0x17, 0x0F, 0x06),     -- a page of rows, a quiet tab
    window = hex(0x1E, 0x14, 0x0C),    -- every window
    raised = hex(0x27, 0x1F, 0x19),    -- buttons, the open tab
    title = hex(0x21, 0x15, 0x0B),     -- the window's title bar
    header = hex(0x20, 0x12, 0x07),    -- a group's header bar
    well = hex(0x0C, 0x07, 0x04),      -- inside a check box
    rim = hex(0x08, 0x03, 0x05),       -- the dark line outside a bronze edge
    line = hex(0x58, 0x45, 0x3B),      -- panel and control borders
    edge = hex(0x6F, 0x53, 0x38),      -- the window's bronze edge
    dim = hex(0xC2, 0xB7, 0xA4),       -- labels, notes, a quiet tab's name
    text = hex(0xFF, 0xFF, 0xFF),      -- everything you read
    gold = hex(0xF0, 0xD1, 0x40),      -- titles, headers, what is chosen
    glow = hex(0xF5, 0xE6, 0x99),      -- the lit top edge of the open tab
    red = hex(0x6E, 0x0C, 0x04),       -- the close button
    -- The world map's own lettering, for the readout drawn on it (MapReadout.lua):
    -- AREA_NAME_FONT_COLOR (1.0, 0.9294, 0.7607) and AREA_DESCRIPTION_FONT_COLOR (white).
    areaName = hex(0xFF, 0xED, 0xC2),
    areaText = hex(0xFF, 0xFF, 0xFF),
    ghost = hex(0xFF, 0xFF, 0xFF),     -- the kills-to-level number; its faintness is alpha (KillsReadout.lua)
}

Look.WORDS = "Fonts\\FRIZQT__.TTF"
Look.BORDER = 1
Look.ICONS = "Interface\\AddOns\\GoblinThings\\Media\\icons\\"
Look.COPIES = { 32, 64, 128 }  -- every glyph, in pixels
Look.FALLBACK = 64             -- no screen size from the client

function Look.RGB(name)
    local c = Look.COLOUR[name] or Look.COLOUR.dim
    return c[1], c[2], c[3]
end

-- The copy of a glyph drawn `pixels` wide: the smallest at least that big, so
-- the game only ever shrinks one (by less than 2x), or the largest there is.
function Look.File(name, pixels)
    local pick = Look.FALLBACK
    if type(pixels) == "number" and pixels == pixels and pixels > 0 then
        pick = Look.COPIES[#Look.COPIES]
        for _, size in ipairs(Look.COPIES) do
            if size >= pixels then
                pick = size
                break
            end
        end
    end
    return Look.ICONS .. name .. "-" .. pick
end

-- How many physical pixels `units` UI units take in this frame; nil when the
-- client gives no screen size.
function Look.Pixels(frame, units)
    local perUnit = ns.API.ScreenPixelsPerUnit()
    if not perUnit then
        return nil
    end
    return units * frame:GetEffectiveScale() * perUnit
end

function Look.Texture(parent, layer, colour, a)
    local t = parent:CreateTexture(nil, layer)
    t:SetColorTexture(colour[1], colour[2], colour[3], a or 1)
    return t
end

-- A one-line, left-justified FontString in a face, size and palette colour.
-- A face that will not load falls back to the client's small font: a missing
-- file costs looks, never words. The flags are required by the client: ""
-- unless given ("OUTLINE" for words drawn on the map's art).
function Look.Text(parent, face, size, colour, flags)
    local s = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    s:SetJustifyH("LEFT")
    s:SetWordWrap(false)
    if not s:SetFont(face, size, flags or "") then
        s:SetFontObject("GameFontHighlightSmall")
    end
    s:SetTextColor(Look.RGB(colour))
    return s
end

-- An outline drawn as four strips inside the frame: one pixel at its edge,
-- or `thickness` wide and `inset` in from it.
function Look.Outline(frame, colour, layer, inset, thickness)
    inset, thickness = inset or 0, thickness or Look.BORDER
    local sides = { { "TOPLEFT", "TOPRIGHT" }, { "BOTTOMLEFT", "BOTTOMRIGHT" },
        { "TOPLEFT", "BOTTOMLEFT" }, { "TOPRIGHT", "BOTTOMRIGHT" } }
    local strips = {}
    for i, side in ipairs(sides) do
        local t = Look.Texture(frame, layer or "BORDER", colour)
        -- Each strip runs the whole side, pushed in by the inset on both axes.
        local x1 = side[1]:find("LEFT") and inset or -inset
        local y1 = side[1]:find("TOP") and -inset or inset
        local x2 = side[2]:find("LEFT") and inset or -inset
        local y2 = side[2]:find("TOP") and -inset or inset
        t:SetPoint(side[1], frame, side[1], x1, y1)
        t:SetPoint(side[2], frame, side[2], x2, y2)
        if i <= 2 then
            t:SetHeight(thickness)
        else
            t:SetWidth(thickness)
        end
        strips[i] = t
    end
    return strips
end

Look.EDGE = 3  -- how far a window's edge reaches in: a dark rim, then two of bronze

-- A window's fill and edge, as the game's own: the brown panel inside a
-- bronze line with a dark rim outside it.
function Look.Frame(frame)
    Look.Texture(frame, "BACKGROUND", Look.COLOUR.window):SetAllPoints(frame)
    Look.Outline(frame, Look.COLOUR.rim)
    Look.Outline(frame, Look.COLOUR.edge, "BORDER", 1, Look.EDGE - 1)
end

-- Button styles: fill, border and words. "gold" is the chosen one (the open
-- tab, the picked choice): gold words on a raised fill under a lit top edge.
Look.BUTTON = {
    raised = { fill = "raised", edge = "line", text = "text" },
    quiet = { fill = "inset", edge = "line", text = "dim" },
    gold = { fill = "raised", edge = "edge", text = "gold", glow = true },
}

function Look.Style(b, style)
    local s = Look.BUTTON[style] or Look.BUTTON.raised
    b.fill:SetColorTexture(Look.RGB(s.fill))
    for _, t in ipairs(b.edges) do
        t:SetColorTexture(Look.RGB(s.edge))
    end
    b.label:SetTextColor(Look.RGB(s.text))
    b.glow:SetShown(s.glow == true)
end

-- A flat button: a fill, an outline and one centred label.
function Look.Button(parent, text, width, height, onClick, style)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width, height)
    b.fill = Look.Texture(b, "BACKGROUND", Look.COLOUR.raised)
    b.fill:SetAllPoints(b)
    b.edges = Look.Outline(b, Look.COLOUR.line)
    b.glow = Look.Texture(b, "ARTWORK", Look.COLOUR.glow)
    b.glow:SetPoint("TOPLEFT", b, "TOPLEFT", Look.BORDER, -Look.BORDER)
    b.glow:SetPoint("TOPRIGHT", b, "TOPRIGHT", -Look.BORDER, -Look.BORDER)
    b.glow:SetHeight(2)
    b.label = Look.Text(b, Look.WORDS, 11, "text")
    b.label:SetJustifyH("CENTER")
    b.label:SetPoint("LEFT", b, "LEFT", 4, 0)
    b.label:SetPoint("RIGHT", b, "RIGHT", -4, 0)
    b.label:SetText(text)
    Look.Style(b, style)
    b:SetScript("OnClick", onClick)
    return b
end

-- A square outlined check box: a dark well, gold inside when on.
-- b.SetOn(on) draws it; onClick decides what a click means.
function Look.Check(parent, size, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(size, size)
    Look.Texture(b, "BACKGROUND", Look.COLOUR.well):SetAllPoints(b)
    Look.Outline(b, Look.COLOUR.edge)
    local mark = Look.Texture(b, "ARTWORK", Look.COLOUR.gold)
    mark:SetPoint("TOPLEFT", b, "TOPLEFT", 4, -4)
    mark:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -4, 4)
    function b.SetOn(on)
        mark:SetShown(on and true or false)
    end
    b:SetScript("OnClick", onClick)
    return b
end

-- The close button, as the game's: a red square in a bronze outline holding a
-- white glyph tinted gold, or fallbackText when the file will not load (a new
-- file before a full client restart).
function Look.IconButton(parent, name, size, onClick, fallbackText)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(size, size)
    Look.Texture(b, "BACKGROUND", Look.COLOUR.red):SetAllPoints(b)
    Look.Outline(b, Look.COLOUR.edge)
    local glyph = math.floor(size / 2)
    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetSize(glyph, glyph)
    icon:SetPoint("CENTER", b, "CENTER")
    if icon:SetTexture(Look.File(name, Look.Pixels(b, glyph))) then
        icon:SetVertexColor(Look.RGB("gold"))
    else
        icon:Hide()
        local t = Look.Text(b, Look.WORDS, 11, "gold")
        t:SetJustifyH("CENTER")
        t:SetPoint("LEFT", b, "LEFT")
        t:SetPoint("RIGHT", b, "RIGHT")
        t:SetText(fallbackText or "")
    end
    b:SetScript("OnClick", onClick)
    return b
end

-- A flat horizontal slider: a thin track and a gold thumb. SetThumbTexture
-- takes a file (SimpleSliderAPIDocumentation: TextureAsset), so it is given a
-- file this addon ships and the colour then replaces it. onChange(value) runs
-- on every change, a SetValue from code included: the caller tells them apart.
function Look.Slider(parent, width, height, min, max, step, onChange)
    local s = CreateFrame("Slider", nil, parent)
    s:SetSize(width, height)
    s:SetOrientation("HORIZONTAL")
    s:SetMinMaxValues(min, max)
    s:SetValueStep(step)
    s:SetObeyStepOnDrag(true)
    s:EnableMouse(true)
    local track = Look.Texture(s, "BACKGROUND", Look.COLOUR.line)
    track:SetHeight(2)
    track:SetPoint("LEFT", s, "LEFT")
    track:SetPoint("RIGHT", s, "RIGHT")
    s:SetThumbTexture(Look.ICONS .. "close-32")
    local thumb = s:GetThumbTexture()
    if thumb then
        thumb:SetColorTexture(Look.RGB("gold"))
        thumb:SetSize(10, height)
    end
    s:SetScript("OnValueChanged", function(_, value)
        onChange(value)
    end)
    return s
end

return Look
