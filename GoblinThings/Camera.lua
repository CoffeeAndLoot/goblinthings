local _, ns = ...

-- The camera distance (spec 2026-10-13-goblin-things-design.md, Camera): the
-- game's cameraDistanceMaxZoomFactor CVar is the only store, read every time
-- the window shows and written only when the player moves our slider. The
-- range is the feature's (Features.LIST), read at call time. Pure.
local Camera = {}
ns.Camera = Camera

Camera.KEY = "cameraDistance"
Camera.CVAR = "cameraDistanceMaxZoomFactor"

-- A number or a numeric string, kept in range and rounded to the step; nil
-- for anything else (the client gave no answer).
function Camera.Clamp(value)
    local n = tonumber(value)
    if type(value) == "table" or not n or n ~= n then
        return nil
    end
    local feature = ns.Features.ByKey(Camera.KEY)
    n = math.max(feature.min, math.min(feature.max, n))
    local per = math.floor(1 / feature.step + 0.5)
    return math.floor(n * per + 0.5) / per
end

function Camera.Text(value)
    return string.format("%.1f", value)
end

return Camera
