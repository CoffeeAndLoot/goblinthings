local _, ns = ...

-- Refusing duels and guild invites (spec 2026-10-13-goblin-things-design.md,
-- Social). Each answer is the chat line to say after declining, or nil to
-- leave Blizzard's popup to the player. Pure: Core calls API.CancelDuel or
-- API.DeclineGuild when a line comes back.
local Decline = {}
ns.Decline = Decline

function Decline.Who(name)
    return (type(name) == "string" and name ~= "") and name or "someone"
end

function Decline.Duel(on, name)
    if on ~= true then
        return nil
    end
    return ("Declined a duel from %s."):format(Decline.Who(name))
end

function Decline.Guild(on, inviter, guild)
    if on ~= true then
        return nil
    end
    if type(guild) == "string" and guild ~= "" then
        return ("Declined a guild invite from %s (%s)."):format(Decline.Who(inviter), guild)
    end
    return ("Declined a guild invite from %s."):format(Decline.Who(inviter))
end

return Decline
