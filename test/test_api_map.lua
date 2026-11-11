-- luacheck: globals C_Map
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

    C_Map = nil  -- must not leak into the next suite
end
