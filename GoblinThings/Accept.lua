local _, ns = ...

-- Accepting group invites from the guild or friends, and summons (Social).
-- Each answer is the chat line to say after accepting, or nil to leave
-- Blizzard's popup to the player. Anything the game will not answer leaves
-- the popup. Pure: Core has API accept when a line comes back.
local Decline = ns.Decline
local Accept = {}
ns.Accept = Accept

-- who: API.InviterView's { name, guild, friend, plain, dropsQueue }. plain is
-- an invite offering no roles and no party sync, the one Blizzard answers
-- with its plain PARTY_INVITE popup.
function Accept.Invite(features, who)
    if who.plain ~= true or who.dropsQueue ~= false then
        return nil
    end
    local why
    if features.acceptGuild == true and who.guild == true then
        why = "guild"
    elseif features.acceptFriends == true and who.friend == true then
        why = "friend"
    else
        return nil
    end
    return ("Accepted a group invite from %s (%s)."):format(Decline.Who(who.name), why)
end

-- view: API.SummonView's { summoner, area, plain, inCombat, canTeleport }.
-- Blizzard's CONFIRM_SUMMON greys its Accept in combat or when the player
-- cannot teleport; plain is that popup, not the scenario or starting-area one.
function Accept.Summon(on, view)
    if on ~= true or view.plain ~= true or view.inCombat ~= false or view.canTeleport ~= true then
        return nil
    end
    local line = "Accepted a summon from " .. Decline.Who(view.summoner)
    if type(view.area) == "string" and view.area ~= "" then
        line = line .. " to " .. view.area
    end
    return line .. "."
end

return Accept
