local _, ns = ...

-- The swirls at dungeon and raid doors on the world map (spec 2026-11-19-map-
-- entrance-pins-design.md): one small plain frame per pin MapPins gives the
-- shown map, on the map's canvas, wearing the game's own Dungeon or Raid
-- swirl (a coloured square when the game gives none). Draws and decides
-- nothing. A pin takes the mouse's hover only, so a click over one still
-- reaches the map; hovering opens a small card naming what is behind the
-- door. The OnUpdate only runs while the map is shown.
local MapEntrances = {}
ns.MapEntrances = MapEntrances

MapEntrances.LAYOUT = {
    PIN = 32,        -- a swirl, in the map's own units whatever its zoom (22 read small, the owner 2026-11-19)
    SQUARE = 16,     -- the coloured square drawn without a swirl
    CARD_GAP = 2,    -- between a pin and its card
    CARD_PAD = 8,
    CARD_ROW = 15,
    CARD_COLUMN_GAP = 14,  -- between a door's name and its levels
    FLIP_X = 0.6,    -- a pin further right than this opens its card leftwards
    FLIP_Y = 0.2,    -- a pin higher than this opens its card downwards
}
local L = MapEntrances.LAYOUT

local driver, canvas, card, shownKey
local pins = {}
local atlases = {}  -- kind -> the game's swirl, once it has given one

local function hideCard()
    if card then
        card:Hide()
    end
end

-- A row's two FontStrings, made the first time a card is that long.
local function cardRow(i)
    local Look = ns.Look
    local row = card.rows[i]
    if not row then
        row = { left = Look.Text(card, Look.WORDS, 12, "text"), right = Look.Text(card, Look.WORDS, 12, "dim") }
        row.right:SetJustifyH("RIGHT")
        card.rows[i] = row
    end
    return row
end

-- The card of a pin: each door's name and levels, beside the pin and turned
-- inwards near the map's right and top edges.
local function showCard(pin)
    local Look = ns.Look
    local data = pin.data
    if not data then
        return
    end
    if not card then
        card = CreateFrame("Frame", nil, driver)
        card:SetFrameStrata("TOOLTIP")
        card:EnableMouse(false)
        Look.Frame(card)
        card.rows = {}
    end
    local width = 0
    for i, pair in ipairs(data.rows) do
        local row = cardRow(i)
        local y = -L.CARD_PAD - (i - 1) * L.CARD_ROW
        row.left:SetText(pair[1])
        row.left:SetTextColor(Look.RGB(i == 1 and "gold" or "text"))
        row.right:SetText(pair[2])
        row.left:ClearAllPoints()
        row.right:ClearAllPoints()
        row.left:SetPoint("TOPLEFT", card, "TOPLEFT", L.CARD_PAD, y)
        row.right:SetPoint("TOPRIGHT", card, "TOPRIGHT", -L.CARD_PAD, y)
        row.left:Show()
        row.right:Show()
        width = math.max(width, row.left:GetStringWidth() + L.CARD_COLUMN_GAP + row.right:GetStringWidth())
    end
    for i = #data.rows + 1, #card.rows do
        card.rows[i].left:Hide()
        card.rows[i].right:Hide()
    end
    card:SetSize(math.ceil(width) + 2 * L.CARD_PAD, #data.rows * L.CARD_ROW + 2 * L.CARD_PAD)
    local left, down = data.x > L.FLIP_X, data.y < L.FLIP_Y
    card:ClearAllPoints()
    card:SetPoint((down and "TOP" or "BOTTOM") .. (left and "RIGHT" or "LEFT"), pin,
        (down and "BOTTOM" or "TOP") .. (left and "LEFT" or "RIGHT"),
        left and -L.CARD_GAP or L.CARD_GAP, down and -L.CARD_GAP or L.CARD_GAP)
    card:Show()
end

local function makePin(core)
    local Look = ns.Look
    local pin = CreateFrame("Frame", nil, canvas)
    pin:SetFrameStrata("HIGH")
    pin:SetSize(L.PIN, L.PIN)
    pin:EnableMouse(true)
    -- Hover only: a click over a pin is the map's (right-click zooms out).
    if pin.SetMouseClickEnabled then
        pin:SetMouseClickEnabled(false)
    end
    pin.art = pin:CreateTexture(nil, "ARTWORK")
    pin.art:SetAllPoints(pin)
    pin.square = CreateFrame("Frame", nil, pin)
    pin.square:SetSize(L.SQUARE, L.SQUARE)
    pin.square:SetPoint("CENTER", pin, "CENTER", 0, 0)
    pin.square:EnableMouse(false)
    pin.square.fill = pin.square:CreateTexture(nil, "ARTWORK")
    pin.square.fill:SetAllPoints(pin.square)
    Look.Outline(pin.square, Look.COLOUR.rim, "OVERLAY")
    pin:SetScript("OnEnter", function(self)
        core.Guard("Map", showCard, self)
    end)
    pin:SetScript("OnLeave", function()
        core.Guard("Map", hideCard)
    end)
    pin:Hide()
    return pin
end

-- The game's swirl for the pin's kind, else a square in the kind's colour.
local function dress(pin, kind)
    atlases[kind] = atlases[kind] or ns.API.EntranceIcon(kind)
    if atlases[kind] and pin.art.SetAtlas then
        pin.art:SetAtlas(atlases[kind])
        pin.art:Show()
        pin.square:Hide()
    else
        pin.art:Hide()
        pin.square.fill:SetColorTexture(ns.Look.RGB(kind))
        pin.square:Show()
    end
end

-- Puts a pin on each of `list`'s spots, as Blizzard's own pins are placed
-- (MapCanvasMixin:ApplyPinPosition): the canvas grows as the map zooms, so a
-- pin is scaled back by as much and its offset divided by that scale.
local function draw(core, list, scale, width, height)
    hideCard()
    for i, data in ipairs(list) do
        local pin = pins[i]
        if not pin then
            pin = makePin(core)
            pins[i] = pin
        end
        pin.data = data
        dress(pin, data.kind)
        pin:SetScale(1 / scale)
        pin:ClearAllPoints()
        pin:SetPoint("CENTER", canvas, "TOPLEFT", width * data.x * scale, -height * data.y * scale)
        pin:Show()
    end
    for i = #list + 1, #pins do
        pins[i].data = nil
        pins[i]:Hide()
    end
end

local function update(core, map)
    local id = core.Get("mapEntrances") == true and ns.API.MapID(map) or nil
    local _, scale = ns.API.MapCanvas(map)
    local width, height = canvas:GetWidth(), canvas:GetHeight()
    local key = id and table.concat({ id, scale or 1, width, height }, " ") or nil
    if key == shownKey then
        return
    end
    shownKey = key
    draw(core, id and ns.MapPins.For(id) or {}, scale or 1, width, height)
end

-- Builds the pins' driver once the world map exists; false while it does not.
function MapEntrances.Create(core)
    if driver then
        return true
    end
    local map, container = ns.API.WorldMap()
    if not map then
        return false
    end
    canvas = ns.API.MapCanvas(map)
    if not canvas then
        return false
    end
    driver = CreateFrame("Frame", nil, container)
    driver:SetAllPoints(container)
    driver:EnableMouse(false)
    driver:SetScript("OnUpdate", function()
        core.Guard("Map", update, core, map)
    end)
    driver:SetScript("OnHide", function()
        shownKey = nil
        hideCard()
    end)
    return true
end

-- Whether the pins' driver was built, for /gt probe.
function MapEntrances.Built()
    return driver ~= nil
end

return MapEntrances
