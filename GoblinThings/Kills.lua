local _, ns = ...

-- Kills left to level (spec 2026-11-11-kills-to-level-design.md): the last
-- ten kills' XP, how many more like them fill the level, and where the number
-- sits. Pure: test/run.lua loads this file.
local Kills = {}
ns.Kills = Kills

Kills.MAX = 10     -- kills averaged
Kills.SAMPLE = 37  -- shown while tuning the look, before there is an estimate
Kills.LOG = 12     -- XP lines kept for /gt probe

-- Blizzard's own faces, by the Font row's choices (the files this build's
-- source names: Fonts.xml, and GlueFonts.xml for Arial Narrow).
Kills.FONTS = {
    friz = "Fonts\\FRIZQT__.TTF",
    arial = "Fonts\\ARIALN.TTF",
    morpheus = "Fonts\\MORPHEUS.ttf",
}

-- list with item at its end and no more than max entries, oldest dropped.
function Kills.Keep(list, item, max)
    list[#list + 1] = item
    while #list > max do
        table.remove(list, 1)
    end
    return list
end

-- A kill's XP joins the samples; anything that is not XP is ignored.
function Kills.Add(samples, xp)
    if type(xp) == "number" and xp > 0 then  -- NaN fails the comparison
        Kills.Keep(samples, xp, Kills.MAX)
    end
    return samples
end

-- Kills like the sampled ones still needed, or nil when there is nothing to say.
function Kills.Left(xp, xpMax, samples)
    if type(xp) ~= "number" or type(xpMax) ~= "number" or #samples == 0 then
        return nil
    end
    if not (xpMax > 0 and xp >= 0 and xp < xpMax) then
        return nil
    end
    local total = 0
    for _, sample in ipairs(samples) do
        total = total + sample
    end
    return math.ceil((xpMax - xp) / (total / #samples))
end

local CORNERS = {
    topLeft = { "TOPLEFT", 1, -1 },
    topRight = { "TOPRIGHT", -1, -1 },
    bottomLeft = { "BOTTOMLEFT", 1, 1 },
    bottomRight = { "BOTTOMRIGHT", -1, 1 },
}

-- The anchor point and offsets that push x, y in from a corner.
function Kills.Anchor(corner, x, y)
    local c = CORNERS[corner] or CORNERS.topLeft
    return c[1], c[2] * x, c[3] * y
end

function Kills.Font(key)
    return Kills.FONTS[key] or Kills.FONTS.friz
end

-- What the readout says: the count, the sample while tuning, or nil (hidden).
function Kills.Text(left, preview)
    if type(left) == "number" then
        return tostring(left)
    end
    return preview and tostring(Kills.SAMPLE) or nil
end

return Kills
