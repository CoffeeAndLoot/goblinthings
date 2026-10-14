-- luacheck: globals IsGuildMember C_FriendList C_BattleNet WillAcceptInviteRemoveQueues
-- luacheck: globals C_SummonInfo Enum UnitAffectingCombat PlayerCanTeleport
-- API.InviterView and API.SummonView against stand-in game calls: a false
-- answer must stay false, not turn into nil ("no answer").
return function(h)
    -- Cleared by name: the stand-ins must not leak into the next suite.
    local function clear(names)
        for _, name in ipairs(names) do
            _G[name] = nil
        end
    end

    local function api()
        local ns = {}
        assert(loadfile("GoblinThings/API.lua"))("GoblinThings", ns)
        return ns.API
    end

    local function inviter(guild, friend, bnet, drops, roles, questSession)
        IsGuildMember = function() return guild end
        C_FriendList = { IsFriend = function() return friend end }
        C_BattleNet = { GetGameAccountInfoByGUID = function() return bnet end }
        WillAcceptInviteRemoveQueues = function() return drops end
        local view = api().InviterView("Bob", roles, questSession, "Player-1-0001")
        clear({ "IsGuildMember", "C_FriendList", "C_BattleNet", "WillAcceptInviteRemoveQueues" })
        return view
    end

    h.describe("API.InviterView", function()
        h.it("reads guild, character friend and Battle.net friend from the GUID", function()
            h.eq(inviter(true, false, nil, false, false).guild, true)
            h.eq(inviter(false, true, nil, false, false).friend, true)
            h.eq(inviter(false, false, {}, false, false).friend, true)
            h.eq(inviter(false, false, nil, false, false).friend, false)
        end)
        h.it("no queue to drop stays false, so the invite can be accepted", function()
            h.eq(inviter(true, false, nil, false, false).dropsQueue, false)
            h.eq(inviter(true, false, nil, true, false).dropsQueue, true)
            h.eq(inviter(true, false, nil, nil, false).dropsQueue, nil)
        end)
        h.it("plain unless roles or party sync are offered; party sync unsent is none", function()
            h.eq(inviter(true, false, nil, false, false, nil).plain, true)
            h.eq(inviter(true, false, nil, false, true, false).plain, false)
            h.eq(inviter(true, false, nil, false, false, true).plain, false)
        end)
    end)

    local function summon(inCombat, reason, skipping)
        C_SummonInfo = {
            GetSummonConfirmSummoner = function() return "Bob" end,
            GetSummonConfirmAreaName = function() return "Blackrock Mountain" end,
        }
        Enum = { SummonReason = { Spell = 0, Scenario = 1 } }
        UnitAffectingCombat = function() return inCombat end
        PlayerCanTeleport = function() return true end
        local view = api().SummonView(reason, skipping)
        clear({ "C_SummonInfo", "Enum", "UnitAffectingCombat", "PlayerCanTeleport" })
        return view
    end

    h.describe("API.SummonView", function()
        h.it("out of combat stays false, so the summon can be accepted", function()
            h.eq(summon(false, 0, false).inCombat, false)
            h.eq(summon(true, 0, false).inCombat, true)
            h.eq(summon(nil, 0, false).inCombat, nil)
        end)
        h.it("plain only for a spell summon that is not skipping the starting area", function()
            h.eq(summon(false, 0, false).plain, true)
            h.eq(summon(false, 1, false).plain, false)
            h.eq(summon(false, 0, true).plain, false)
        end)
        h.it("reads the summoner and the place", function()
            local view = summon(false, 0, false)
            h.eq(view.summoner, "Bob")
            h.eq(view.area, "Blackrock Mountain")
            h.eq(view.canTeleport, true)
        end)
    end)
end
