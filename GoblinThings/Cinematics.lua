local _, ns = ...

-- Skipping cinematics (spec 2026-10-13-goblin-things-design.md, Cinematics).
-- Mode "off" does nothing, "all" stops every movie and real cinematic,
-- "repeats" plays one the first time and stops it after. A cinematic that
-- cannot be cancelled is a vehicle ride (CinematicFrame.lua: isRealCinematic
-- = canBeCancelled) and is never touched. Movies carry an ID; in-engine
-- cinematics carry none, so they are known by race and map. Pure.
local Cinematics = {}
ns.Cinematics = Cinematics

Cinematics.LISTS = { movie = "movies", cinematic = "cinematics" }

function Cinematics.Key(race, map)
    if type(race) == "string" and race ~= "" and type(map) == "number" then
        return race .. ":" .. map
    end
    return nil
end

-- "stop", "mark" (play it, then remember it) or nil.
function Cinematics.Decide(mode, seen, kind, key, canCancel)
    local list = Cinematics.LISTS[kind]
    if not list or canCancel ~= true then
        return nil
    end
    if mode == "all" then
        return "stop"
    end
    if mode ~= "repeats" or key == nil or type(seen) ~= "table" or type(seen[list]) ~= "table" then
        return nil
    end
    return seen[list][key] and "stop" or "mark"
end

function Cinematics.Mark(seen, kind, key)
    seen[Cinematics.LISTS[kind]][key] = true
end

return Cinematics
