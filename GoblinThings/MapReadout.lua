local _, ns = ...

-- The world map's corner readout (specs 2026-11-10-map-zone-readout-design.md
-- and 2026-11-14-map-gathering-lists-design.md): up to six right-justified
-- lines on a small card at the bottom right of the map (the game's own look:
-- brown in a bronze edge, as the list that opens above it; letters straight on
-- the parchment washed out), drawing what MapInfo picks and deciding nothing.
-- The card is as big as the lines showing and goes when there are none. Built on the map's canvas container
-- at strata HIGH, as Blizzard's area label is, with the mouse off so the
-- canvas keeps its hover. A line with a list (fish, herbs, ore, skins) ends in a
-- small icon on a zone's own map; only those icons take the mouse, and
-- hovering one opens the list. Its OnUpdate only runs while the map is shown.
local MapReadout = {}
ns.MapReadout = MapReadout

MapReadout.LAYOUT = {
    -- Where the words' bottom right corner sits; the card reaches CARD_PAD past
    -- it, clear of the quest-log toggle (32 px at -2, 1) and the frame's ornament.
    RIGHT = -50,
    BOTTOM = 28,
    CARD_PAD = 8,  -- between the card's edge and the words
    WIDTH = 300,
    GAP = 2,       -- between lines
    SIZES = { 16, 13, 13, 13, 13, 13 },  -- the name, then each line under it
    ICON = 14,     -- a list's icon at the end of its line
    ICON_GAP = 4,  -- between a line's words and its icon
    LIST_GAP = 4,  -- between the card's top and the list above it
    LIST_PAD = 10,
    LIST_ROW = 15,
    LIST_COLUMN_GAP = 18,  -- between a row's name and its number
}
local L = MapReadout.LAYOUT

MapReadout.LETTER = { fish = "F", herbs = "H", ore = "O", skins = "S" }
local SWITCH = { herbs = "mapHerbs", ore = "mapOre", fish = "mapFish", skins = "mapSkins" }

local frame, card, lines, icons, list, shownKey, shownID
local textures = {}  -- kind -> the game's icon, once it has given one

local function paint(strips, colour)
    for _, strip in ipairs(strips) do
        strip:SetColorTexture(ns.Look.RGB(colour))
    end
end

local function hideList()
    if list then
        list:Hide()
    end
    for _, icon in ipairs(icons) do
        paint(icon.edge, "line")
    end
end

-- A row's two FontStrings, made the first time a list is that long.
local function listRow(i)
    local Look = ns.Look
    local row = list.rows[i]
    if not row then
        row = { left = Look.Text(list, Look.WORDS, 12, "text"), right = Look.Text(list, Look.WORDS, 12, "dim") }
        row.right:SetJustifyH("RIGHT")
        list.rows[i] = row
    end
    return row
end

-- Fills the list with what MapInfo says of this kind here and shows it above
-- the corner; nothing to say shows nothing.
local function showList(icon)
    local Look = ns.Look
    local data = shownID and ns.MapInfo.List(icon.kind, shownID)
    if not data then
        return
    end
    if not list then
        list = CreateFrame("Frame", nil, frame)
        list:SetFrameStrata("TOOLTIP")
        list:EnableMouse(false)
        Look.Frame(list)
        list.title = Look.Text(list, Look.WORDS, 13, "gold")
        list.title:SetPoint("TOPLEFT", list, "TOPLEFT", L.LIST_PAD, -L.LIST_PAD)
        list.note = Look.Text(list, Look.WORDS, 11, "dim")
        list.rows = {}
    end
    list.title:SetText(data.title)
    local width = list.title:GetStringWidth()
    local y = -L.LIST_PAD - L.LIST_ROW - 2
    for i, pair in ipairs(data.rows) do
        local row = listRow(i)
        row.left:SetText(pair[1])
        row.right:SetText(pair[2])
        row.left:ClearAllPoints()
        row.right:ClearAllPoints()
        row.left:SetPoint("TOPLEFT", list, "TOPLEFT", L.LIST_PAD, y)
        row.right:SetPoint("TOPRIGHT", list, "TOPRIGHT", -L.LIST_PAD, y)
        row.left:Show()
        row.right:Show()
        width = math.max(width, row.left:GetStringWidth() + L.LIST_COLUMN_GAP + row.right:GetStringWidth())
        y = y - L.LIST_ROW
    end
    for i = #data.rows + 1, #list.rows do
        list.rows[i].left:Hide()
        list.rows[i].right:Hide()
    end
    if data.note then
        list.note:SetText(data.note)
        list.note:ClearAllPoints()
        list.note:SetPoint("TOPLEFT", list, "TOPLEFT", L.LIST_PAD, y - 3)
        list.note:Show()
        width = math.max(width, list.note:GetStringWidth())
        y = y - L.LIST_ROW - 3
    else
        list.note:Hide()
    end
    list:SetSize(width + 2 * L.LIST_PAD, -y + L.LIST_PAD)
    list:ClearAllPoints()
    list:SetPoint("BOTTOMRIGHT", card, "TOPRIGHT", 0, L.LIST_GAP)
    paint(icon.edge, "gold")
    list:Show()
end

-- The icon at the end of line i: the game's own profession icon when it gives
-- one, else a letter in a square, so the list is always reachable.
local function dressIcon(icon, kind, s)
    icon.kind = kind
    textures[kind] = textures[kind] or ns.API.ProfessionIcon(kind)
    if textures[kind] and icon.art:SetTexture(textures[kind]) then
        icon.art:Show()
        icon.letter:Hide()
    else
        icon.art:Hide()
        icon.letter:SetText(MapReadout.LETTER[kind] or "?")
        icon.letter:Show()
    end
    icon:ClearAllPoints()
    icon:SetPoint("LEFT", s, "RIGHT", L.ICON_GAP, 0)
    icon:Show()
end

-- rows[i] = { text =, kind = } on line i (the first in the name's size and,
-- when it is the name, its colour), stacked up from the bottom, and the card
-- sized round them; nil hides every line and the card. withIcons: a row with
-- a kind ends in its icon.
local function draw(rows, named, withIcons)
    local Look = ns.Look
    hideList()
    local below
    local width, height = 0, 0
    for i = #lines, 1, -1 do
        local s, row, icon = lines[i], rows and rows[i], icons[i]
        s:ClearAllPoints()
        icon:Hide()
        if row then
            local kind = withIcons and row.kind or nil
            s:SetText(row.text)
            s:SetTextColor(Look.RGB((i == 1 and named) and "gold" or "text"))
            s:SetWidth(L.WIDTH - (kind and (L.ICON + L.ICON_GAP) or 0))
            s:SetPoint("BOTTOMLEFT", below or frame, below and "TOPLEFT" or "BOTTOMLEFT", 0, below and L.GAP or 0)
            s:Show()
            if kind then
                dressIcon(icon, kind, s)
            end
            -- Unbounded: the line is as wide as the frame, so its own width says nothing.
            width = math.max(width, s:GetUnboundedStringWidth() + (kind and (L.ICON + L.ICON_GAP) or 0))
            height = height + s:GetStringHeight() + (below and L.GAP or 0)
            below = s
        else
            s:SetText("")
            s:Hide()
        end
    end
    if below then
        card:SetSize(math.ceil(width) + 2 * L.CARD_PAD, math.ceil(height) + 2 * L.CARD_PAD)
        card:Show()
    else
        card:Hide()
    end
end

local function update(core, map)
    local id, shown, key
    local show = {}
    if core.Get("mapInfo") == true then
        for kind, switch in pairs(SWITCH) do
            show[kind] = core.Get(switch) == true
        end
        local hovered
        shown, hovered = ns.API.MapUnderCursor(map)
        id = ns.MapInfo.Pick(shown, hovered, show)
    end
    -- The lists are for the map that is open: on a continent the cursor would
    -- cross other zones on its way to an icon.
    local withIcons = id ~= nil and id == shown
    if id then
        key = table.concat({ id, withIcons and 1 or 0, show.herbs and 1 or 0, show.ore and 1 or 0,
            show.fish and 1 or 0, show.skins and 1 or 0 }, " ")
    end
    if key == shownKey then
        return
    end
    shownKey, shownID = key, id
    local name = id and ns.API.MapName(id)
    draw(id and ns.MapInfo.Lines(id, name, show), name ~= nil, withIcons)
end

local function makeIcon(core, parent)
    local Look = ns.Look
    local icon = CreateFrame("Frame", nil, parent)
    icon:SetSize(L.ICON, L.ICON)
    icon:EnableMouse(true)
    local fill = Look.Texture(icon, "BACKGROUND", Look.COLOUR.window)
    fill:SetAllPoints(icon)
    icon.art = icon:CreateTexture(nil, "ARTWORK")
    icon.art:SetPoint("TOPLEFT", icon, "TOPLEFT", Look.BORDER, -Look.BORDER)
    icon.art:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -Look.BORDER, Look.BORDER)
    icon.art:SetTexCoord(0.08, 0.92, 0.08, 0.92)  -- inside the icon's own bevel
    icon.letter = Look.Text(icon, Look.WORDS, 10, "gold")
    icon.letter:SetPoint("CENTER", icon, "CENTER", 0, 0)
    icon.edge = Look.Outline(icon, Look.COLOUR.line, "OVERLAY")
    icon:SetScript("OnEnter", function(self)
        core.Guard("Map", showList, self)
    end)
    icon:SetScript("OnLeave", function()
        core.Guard("Map", hideList)
    end)
    icon:Hide()
    return icon
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
    card = CreateFrame("Frame", nil, frame)
    card:EnableMouse(false)
    card:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", L.CARD_PAD, -L.CARD_PAD)
    Look.Frame(card)
    card:Hide()
    -- The words and icons live on a frame above the card: a child frame draws
    -- over its parent's own regions, so on `frame` itself the card would hide them.
    local words = CreateFrame("Frame", nil, frame)
    words:SetAllPoints(frame)
    words:EnableMouse(false)
    words:SetFrameLevel(card:GetFrameLevel() + 1)
    lines, icons = {}, {}
    for i, size in ipairs(L.SIZES) do
        local s = Look.Text(words, Look.WORDS, size, "text")
        s:SetJustifyH("RIGHT")
        s:Hide()
        lines[i] = s
        icons[i] = makeIcon(core, words)
    end
    frame:SetScript("OnUpdate", function()
        core.Guard("Map", update, core, map)
    end)
    frame:SetScript("OnHide", function()
        shownKey, shownID = nil, nil
        draw(nil, false, false)
    end)
    return true
end

-- Whether the readout was built, for /gt probe.
function MapReadout.Built()
    return frame ~= nil
end

return MapReadout
