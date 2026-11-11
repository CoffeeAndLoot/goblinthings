local _, ns = ...

-- The kills-to-level number (spec 2026-11-11-kills-to-level-design.md): one
-- ghosted FontString in a screen corner, drawing what Core hands it and
-- deciding nothing. On UIParent, so it hides with the UI; strata BACKGROUND,
-- so every window covers it; mouse off, so clicks pass through. No outline:
-- that would defeat the ghosting. Built on first use.
local KillsReadout = {}
ns.KillsReadout = KillsReadout

local frame, label

local function build()
    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetFrameStrata("BACKGROUND")
    frame:EnableMouse(false)
    frame:SetSize(1, 1)
    label = ns.Look.Text(frame, ns.Look.WORDS, 18, "ghost")
    -- Look.Text's font object carries a black drop shadow (SystemFont_Shadow_Small);
    -- like an outline, it would defeat the ghosting.
    label:SetShadowOffset(0, 0)
end

-- text in the look s = { corner, x, y, alpha, size, font } (the kills*
-- settings); nil hides it.
function KillsReadout.Draw(text, s)
    if not text then
        if frame then
            frame:Hide()
        end
        return
    end
    if not frame then
        build()
    end
    local Kills = ns.Kills
    -- SetFont answers false for a face it cannot load; should this build raise
    -- instead, the pcall still lands on Friz.
    local ok, set = pcall(label.SetFont, label, Kills.Font(s.font), s.size, "")
    if not (ok and set) then
        label:SetFont(ns.Look.WORDS, s.size, "")  -- a face that will not load costs looks, never the number
    end
    local point, dx, dy = Kills.Anchor(s.corner, s.x, s.y)
    frame:ClearAllPoints()
    frame:SetPoint(point, UIParent, point, dx, dy)
    label:ClearAllPoints()
    label:SetPoint(point, frame, point, 0, 0)
    label:SetJustifyH(point:find("RIGHT") and "RIGHT" or "LEFT")
    label:SetText(text)
    frame:SetAlpha(s.alpha / 100)
    frame:Show()
end

-- Whether the readout was built, for /gt probe.
function KillsReadout.Built()
    return frame ~= nil
end

return KillsReadout
