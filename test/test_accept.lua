return function(h, loaded)
    local Accept = loaded.ns.Accept
    local NIL = {}  -- an override to nil: pairs never sees a nil value

    local function with(base, over)
        for k, v in pairs(over or {}) do
            if v == NIL then
                base[k] = nil
            else
                base[k] = v
            end
        end
        return base
    end

    -- An invite as API.InviterView gives it: a plain invite, no queue to lose.
    local function who(over)
        return with({ name = "Bob", guild = false, friend = false, plain = true, dropsQueue = false }, over)
    end

    local both = { acceptGuild = true, acceptFriends = true }

    h.describe("Accept.Invite", function()
        h.it("accepts a guild member's invite with the guild check on", function()
            h.eq(Accept.Invite({ acceptGuild = true }, who({ guild = true })),
                "Accepted a group invite from Bob (guild).")
        end)
        h.it("accepts a friend's invite with the friends check on", function()
            h.eq(Accept.Invite({ acceptFriends = true }, who({ friend = true })),
                "Accepted a group invite from Bob (friend).")
        end)
        h.it("each check covers only its own list", function()
            h.eq(Accept.Invite({ acceptGuild = true }, who({ friend = true })), nil)
            h.eq(Accept.Invite({ acceptFriends = true }, who({ guild = true })), nil)
        end)
        h.it("a guildie who is also a friend is named as guild", function()
            h.eq(Accept.Invite(both, who({ guild = true, friend = true })),
                "Accepted a group invite from Bob (guild).")
        end)
        h.it("a stranger, or an unknown answer, gets Blizzard's popup", function()
            h.eq(Accept.Invite(both, who()), nil)
            h.eq(Accept.Invite(both, who({ guild = NIL, friend = NIL })), nil)
        end)
        h.it("leaves it to the player when accepting would drop a queue, or the game will not say", function()
            h.eq(Accept.Invite(both, who({ guild = true, dropsQueue = true })), nil)
            h.eq(Accept.Invite(both, who({ guild = true, dropsQueue = NIL })), nil)
        end)
        h.it("an invite offering roles or party sync is the player's to answer", function()
            h.eq(Accept.Invite(both, who({ guild = true, plain = false })), nil)
            h.eq(Accept.Invite(both, who({ guild = true, plain = NIL })), nil)
        end)
        h.it("both checks off accepts nothing", function()
            h.eq(Accept.Invite({}, who({ guild = true, friend = true })), nil)
        end)
        h.it("no name still makes a sensible line", function()
            h.eq(Accept.Invite(both, who({ name = NIL, guild = true })),
                "Accepted a group invite from someone (guild).")
        end)
    end)

    -- A summon as API.SummonView gives it: a plain summon, out of combat.
    local function summon(over)
        return with({ summoner = "Bob", area = "Blackrock Mountain", plain = true, inCombat = false,
            canTeleport = true }, over)
    end

    h.describe("Accept.Summon", function()
        h.it("accepts and names the summoner and the place when on", function()
            h.eq(Accept.Summon(true, summon()), "Accepted a summon from Bob to Blackrock Mountain.")
        end)
        h.it("leaves it to the player when off or unset", function()
            h.eq(Accept.Summon(false, summon()), nil)
            h.eq(Accept.Summon(nil, summon()), nil)
        end)
        h.it("waits on the player in combat or when they cannot teleport, as Blizzard's button does", function()
            h.eq(Accept.Summon(true, summon({ inCombat = true })), nil)
            h.eq(Accept.Summon(true, summon({ inCombat = NIL })), nil)
            h.eq(Accept.Summon(true, summon({ canTeleport = false })), nil)
        end)
        h.it("a scenario or starting-area summon is the player's call", function()
            h.eq(Accept.Summon(true, summon({ plain = false })), nil)
        end)
        h.it("no place or summoner still makes a sensible line", function()
            h.eq(Accept.Summon(true, summon({ area = NIL })), "Accepted a summon from Bob.")
            h.eq(Accept.Summon(true, summon({ summoner = NIL, area = "" })), "Accepted a summon from someone.")
        end)
    end)
end
