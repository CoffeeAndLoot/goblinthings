local _, ns = ...

-- Kills left to level (spec 2026-11-11-kills-to-level-design.md): the last
-- ten kills' XP, how many more like them fill the level, and where the number
-- sits. Pure: test/run.lua loads this file.
local Kills = {}
ns.Kills = Kills

Kills.MAX = 10     -- kills averaged
Kills.SAMPLE = 37  -- shown while tuning the look, before there is an estimate
Kills.LOG = 12     -- XP lines kept for /gt probe
-- The global string the game formats a kill's XP line with (seen in game
-- 2026-11-11: "%s dies, you gain %d experience.").
Kills.FORMAT = "COMBATLOG_XPGAIN_FIRSTPERSON"

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
    if not (xpMax > 0 and xpMax < math.huge and xp >= 0 and xp < xpMax) then
        return nil
    end
    local total = 0
    for _, sample in ipairs(samples) do
        total = total + sample
    end
    return math.ceil((xpMax - xp) / (total / #samples))
end

-- A Lua pattern for the game's kill-line format (COMBATLOG_XPGAIN_FIRSTPERSON,
-- "%s dies, you gain %d experience." in English), and which capture is the
-- XP. Anchored at the start only: the rested and group lines are this one
-- with a bonus after it. Any language's word order (%2$d) is followed. nil
-- for no format or one with no number.
function Kills.Pattern(format)
    if type(format) ~= "string" then
        return nil
    end
    local out, captures, index, i = { "^" }, 0, nil, 1
    while i <= #format do
        local kind, after = format:match("^%%%d*%$?([sd])()", i)
        if format:sub(i, i + 1) == "%%" then  -- the format's own escape: one percent sign
            out[#out + 1] = "%%"
            i = i + 2
        elseif kind then
            captures = captures + 1
            if kind == "d" then
                index = index or captures
                out[#out + 1] = "(%d+)"
            else
                out[#out + 1] = "(.-)"
            end
            i = after
        else
            out[#out + 1] = format:sub(i, i):gsub("%p", "%%%0")
            i = i + 1
        end
    end
    if not index then
        return nil
    end
    return table.concat(out), index
end

-- The XP of a kill line, or nil for any other line.
function Kills.Sample(text, pattern, index)
    if type(text) ~= "string" or type(pattern) ~= "string" then
        return nil
    end
    local captures = { text:match(pattern) }
    return tonumber(captures[index])
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
