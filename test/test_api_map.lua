-- luacheck: globals C_Map C_Spell C_Texture
-- API.MapUnderCursor against a stand-in map and C_Map: it only asks the game
-- with the cursor on the canvas, and counts the asks and the answers so the
-- probe can say when the game never answers.
return function(h)
    local function fresh(answer)
        C_Map = {
            GetMapInfoAtPosition = function(mapID, x, y)
                return answer and answer(mapID, x, y)
            end,
            GetMapInfo = function(mapID)
                return mapID == 1413 and { mapID = 1413, name = "The Barrens" } or nil
            end,
        }
        local ns = {}
        assert(loadfile("GoblinThings/API.lua"))("GoblinThings", ns)
        return ns.API
    end

    local function map(shown, focus)
        return {
            GetMapID = function() return shown end,
            IsCanvasMouseFocusOrPinFocus = function() return focus end,
            GetNormalizedCursorPosition = function() return 0.4, 0.6 end,
        }
    end

    h.describe("API.MapUnderCursor", function()
        h.it("gives the shown map and the one the game names under the cursor", function()
            local API = fresh(function(mapID, x, y)
                h.eq(mapID, 1414)
                h.eq(x .. " " .. y, "0.4 0.6")
                return { mapID = 1413, name = "The Barrens" }
            end)
            local shown, hovered = API.MapUnderCursor(map(1414, true))
            h.eq(shown, 1414)
            h.eq(hovered, 1413)
            h.eq(select(2, API.MapHoverCounts()), 1)
        end)
        h.it("off the canvas it does not ask", function()
            local API = fresh(function() error("asked") end)
            local shown, hovered = API.MapUnderCursor(map(1414, false))
            h.eq(shown, 1414)
            h.eq(hovered, nil)
            h.eq(API.MapHoverCounts(), 0)
        end)
        h.it("counts an ask that got no map back, so the probe can say none answered", function()
            local API = fresh(nil)
            API.MapUnderCursor(map(1414, true))
            API.MapUnderCursor(map(1414, true))
            local asked, answered = API.MapHoverCounts()
            h.eq(asked .. " " .. answered, "2 0")
        end)
        h.it("a map with no ID gives nothing", function()
            local API = fresh(nil)
            h.eq(API.MapUnderCursor(map(nil, true)), nil)
        end)
    end)

    h.describe("API.MapName", function()
        h.it("is the game's name for the map, nil when it has none", function()
            local API = fresh(nil)
            h.eq(API.MapName(1413), "The Barrens")
            h.eq(API.MapName(9999), nil)
        end)
    end)

    h.describe("API.ProfessionIcon", function()
        h.it("is the game's texture for the profession's spell", function()
            C_Spell = { GetSpellTexture = function(spell) return spell == 2366 and 136065 or nil end }
            local API = fresh(nil)
            h.eq(API.ProfessionIcon("herbs"), 136065)
            h.eq(API.ProfessionIcon("ore"), nil)
            C_Spell = { GetSpellTexture = function(spell) return spell == 8613 and "skin" or nil end }
            h.eq(API.ProfessionIcon("skins"), "skin")
        end)
        h.it("is nil for a kind it has no spell for, and when the game cannot say", function()
            C_Spell = { GetSpellTexture = function() error("no") end }
            local API = fresh(nil)
            h.eq(API.ProfessionIcon("tailoring"), nil)
            h.eq(API.ProfessionIcon("fish"), nil)
            C_Spell = { GetSpellTexture = function() return true end }
            h.eq(API.ProfessionIcon("fish"), nil)
            C_Spell = nil
            h.eq(API.ProfessionIcon("fish"), nil)
        end)
    end)

    h.describe("API.EntranceIcon", function()
        h.it("is the atlas name once the game answers for it", function()
            C_Texture = { GetAtlasInfo = function(atlas) return atlas == "Dungeon" and { width = 32 } or nil end }
            local API = fresh(nil)
            h.eq(API.EntranceIcon("dungeon"), "Dungeon")
            h.eq(API.EntranceIcon("raid"), nil)
        end)
        h.it("is nil for another kind, and when the game cannot say", function()
            C_Texture = { GetAtlasInfo = function() error("no") end }
            local API = fresh(nil)
            h.eq(API.EntranceIcon("delve"), nil)
            h.eq(API.EntranceIcon("raid"), nil)
            C_Texture = nil
            h.eq(API.EntranceIcon("raid"), nil)
        end)
    end)

    h.describe("API.MapCanvas", function()
        h.it("gives the canvas and its scale, 1 when the game gives no scale", function()
            local API = fresh(nil)
            local canvas = {}
            local got, scale = API.MapCanvas({ GetCanvas = function() return canvas end,
                GetCanvasScale = function() return 0.5 end })
            h.eq(got, canvas)
            h.eq(scale, 0.5)
            h.eq(select(2, API.MapCanvas({ GetCanvas = function() return canvas end })), 1)
            h.eq(select(2, API.MapCanvas({ GetCanvas = function() return canvas end,
                GetCanvasScale = function() return 0 end })), 1)
            h.eq(API.MapCanvas({}), nil)
        end)
    end)

    h.describe("API.PlayerPosition", function()
        h.it("is the player's map and spot in percent", function()
            local API = fresh(nil)
            C_Map.GetBestMapForUnit = function() return 1413 end
            C_Map.GetPlayerMapPosition = function(mapID, unit)
                h.eq(mapID .. " " .. unit, "1413 player")
                return { GetXY = function() return 0.25, 0.5 end }
            end
            local mapID, x, y = API.PlayerPosition()
            h.eq(mapID, 1413)
            h.eq(x, 25)
            h.eq(y, 50)
        end)
        h.it("is nil where the game gives no map or no position", function()
            local API = fresh(nil)
            h.eq(API.PlayerPosition(), nil)
            C_Map.GetBestMapForUnit = function() return 1413 end
            C_Map.GetPlayerMapPosition = function() return nil end
            h.eq(API.PlayerPosition(), nil)
        end)
    end)

    C_Map = nil  -- must not leak into the next suite
    C_Texture = nil
    C_Spell = nil
end
