local _, ns = ...

-- The settings (spec 2026-10-13-goblin-things-design.md): the SavedVariable's
-- shape, and a stub page in Blizzard's options (Esc > Options > AddOns >
-- Goblin Things) that opens our own window. Init is pure; Register uses
-- Blizzard's Settings UI only when called, so test/run.lua loads this file.
local Options = {}
ns.Options = Options

Options.NAME = "Goblin Things"
Options.DEFAULT_ANGLE = 195  -- degrees round the minimap: clear of Goblin Flyout's 225

local function list(t)
    return type(t) == "table" and t or {}
end

-- The SavedVariable with every field valid (see the spec's SavedVariable).
-- Keeps the given table, so writes to it are saved.
function Options.Init(db)
    if type(db) ~= "table" then
        db = {}
    end
    local saved = list(db.features)
    local features = {}
    for _, feature in ipairs(ns.Features.LIST) do
        if feature.default ~= nil then
            local value = saved[feature.key]
            if ns.Features.Valid(feature, value) then
                features[feature.key] = value
            else
                features[feature.key] = feature.default
            end
        end
    end
    db.features = features
    local seen = list(db.seen)
    db.seen = { movies = list(seen.movies), cinematics = list(seen.cinematics) }
    local minimap = list(db.minimap)
    db.minimap = {
        angle = type(minimap.angle) == "number" and minimap.angle or Options.DEFAULT_ANGLE,
        hide = minimap.hide == true,  -- shown unless hidden on purpose
    }
    local window = db.window
    if not (type(window) == "table" and type(window.point) == "string" and type(window.relativePoint) == "string"
        and type(window.x) == "number" and type(window.y) == "number") then
        db.window = nil
    end
    return db
end

local category

-- Adds the page; false when this client's Settings UI lacks a piece.
-- openWindow() shows Goblin Things' own window.
function Options.Register(openWindow)
    if category then
        return true
    end
    if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then
        return false
    end
    local panel = CreateFrame("Frame")
    local open = ns.Look.Button(panel, "Open " .. Options.NAME, 200, 28, function()
        if SettingsPanel and HideUIPanel then
            HideUIPanel(SettingsPanel)
        end
        openWindow()
    end, "gold")
    open:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)
    category = Settings.RegisterCanvasLayoutCategory(panel, Options.NAME)
    Settings.RegisterAddOnCategory(category)
    return true
end

return Options
