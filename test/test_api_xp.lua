-- luacheck: globals UnitXP UnitXPMax IsXPUserDisabled GameRulesUtil issecretvalue GT_TEST_FORMAT
-- The experience reads against stand-in globals: two numbers or nothing,
-- whether more XP can be earned, and chat text the addon is allowed to read.
return function(h)
    local function fresh()
        local ns = {}
        assert(loadfile("GoblinThings/API.lua"))("GoblinThings", ns)
        return ns.API
    end

    h.describe("API.PlayerXP", function()
        h.it("is the two numbers, or nothing", function()
            UnitXP = function(unit)
                h.eq(unit, "player")
                return 450
            end
            UnitXPMax = function() return 2000 end
            local xp, max = fresh().PlayerXP()
            h.eq(xp .. " " .. max, "450 2000")
            UnitXPMax = function() return nil end
            h.eq(fresh().PlayerXP(), nil)
            _G.UnitXP = nil
            h.eq(fresh().PlayerXP(), nil)
        end)
    end)

    h.describe("API.CanEarnXP", function()
        h.it("is false at max level or with XP off, true when the game says neither", function()
            IsXPUserDisabled, GameRulesUtil = nil, nil
            h.eq(fresh().CanEarnXP(), true)
            IsXPUserDisabled = function() return true end
            h.eq(fresh().CanEarnXP(), false)
            IsXPUserDisabled = function() return false end
            GameRulesUtil = { IsPlayerAtEffectiveMaxLevel = function() return true end }
            h.eq(fresh().CanEarnXP(), false)
            GameRulesUtil = { IsPlayerAtEffectiveMaxLevel = function() error("boom") end }
            h.eq(fresh().CanEarnXP(), true)
        end)
    end)

    h.describe("API.Readable", function()
        h.it("gives a plain string and nothing for a secret or a non-string", function()
            issecretvalue = function(v) return v == "hidden" end
            local API = fresh()
            h.eq(API.Readable("Boar dies, you gain 45 experience."), "Boar dies, you gain 45 experience.")
            h.eq(API.Readable("hidden"), nil)
            h.eq(API.Readable(45), nil)
            h.eq(API.Readable(nil), nil)
            _G.issecretvalue = nil
            h.eq(fresh().Readable("hidden"), "hidden")
        end)
    end)

    h.describe("API.GlobalText", function()
        h.it("is a global string by name, nil when missing or not a string", function()
            GT_TEST_FORMAT = "%s dies."
            local API = fresh()
            h.eq(API.GlobalText("GT_TEST_FORMAT"), "%s dies.")
            h.eq(API.GlobalText("GT_NO_SUCH"), nil)
            GT_TEST_FORMAT = 5
            h.eq(API.GlobalText("GT_TEST_FORMAT"), nil)
            _G.GT_TEST_FORMAT = nil
        end)
    end)

    -- must not leak into the next suite
    for _, name in ipairs({ "UnitXP", "UnitXPMax", "IsXPUserDisabled", "GameRulesUtil", "issecretvalue" }) do
        _G[name] = nil
    end
end
