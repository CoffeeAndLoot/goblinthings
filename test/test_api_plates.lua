-- luacheck: globals C_NamePlate C_QuestLog C_TooltipInfo Enum issecretvalue
-- The nameplate reads against stand-in globals: the plate frame for a unit,
-- and the unit's typed tooltip lines as QuestPlates.Remaining wants them.
return function(h)
    local function fresh()
        local ns = {}
        assert(loadfile("GoblinThings/API.lua"))("GoblinThings", ns)
        return ns.API
    end

    local function game(related, lines)
        C_QuestLog = { UnitIsRelatedToActiveQuest = function() return related end }
        C_TooltipInfo = lines and { GetUnit = function(unit)
            h.eq(unit, "nameplate3")
            return { lines = lines }
        end } or nil
        Enum = { TooltipDataLineType = { QuestTitle = 17, QuestObjective = 8, UnitName = 0 } }
        issecretvalue = function(v) return v == "hidden" end
    end

    h.describe("API.NamePlate", function()
        h.it("is the plate the game gives for a unit, or nothing", function()
            local plate = {}
            C_NamePlate = { GetNamePlateForUnit = function(unit)
                return unit == "nameplate3" and plate or nil
            end }
            local API = fresh()
            h.eq(API.NamePlate("nameplate3"), plate)
            h.eq(API.NamePlate("nameplate4"), nil)
            C_NamePlate = nil
            h.eq(fresh().NamePlate("nameplate3"), nil)
        end)
    end)

    h.describe("API.UnitQuestLines", function()
        h.it("is each tooltip line's kind, readable text and finished flag", function()
            game(true, {
                { type = 0, leftText = "Kobold Vermin" },
                { type = 17, leftText = "Kobold Camp Cleanup" },
                { type = 8, leftText = "Kobold Vermin slain: 4/10", completed = false },
                { type = 8, leftText = "hidden", completed = true },
            })
            local lines = fresh().UnitQuestLines("nameplate3")
            h.eq(#lines, 4)
            h.eq(lines[1].kind, "other")
            h.eq(lines[2].kind .. " " .. lines[2].text, "title Kobold Camp Cleanup")
            h.eq(lines[3].kind .. " " .. lines[3].text .. " " .. tostring(lines[3].completed),
                "objective Kobold Vermin slain: 4/10 false")
            h.eq(lines[4].text, nil)
            h.eq(lines[4].completed, true)
        end)
        h.it("does not read the tooltip of a unit the game says is no quest's", function()
            game(false, { { type = 8, leftText = "Boars: 1/3" } })
            C_TooltipInfo.GetUnit = function() error("asked") end
            h.eq(fresh().UnitQuestLines("nameplate3"), nil)
        end)
        h.it("asks the tooltip when the game cannot say whether the unit is a quest's", function()
            game(nil, { { type = 8, leftText = "Boars: 1/3" } })
            h.eq(fresh().UnitQuestLines("nameplate3")[1].kind, "objective")
            C_QuestLog = nil
            h.eq(fresh().UnitQuestLines("nameplate3")[1].kind, "objective")
        end)
        h.it("is nothing without tooltip data", function()
            game(true, nil)
            h.eq(fresh().UnitQuestLines("nameplate3"), nil)
            game(true, nil)
            C_TooltipInfo = { GetUnit = function() return {} end }
            h.eq(fresh().UnitQuestLines("nameplate3"), nil)
        end)
        h.it("knows no kind without the game's enum", function()
            game(true, { { type = 8, leftText = "Boars: 1/3" } })
            Enum = nil
            h.eq(fresh().UnitQuestLines("nameplate3")[1].kind, "other")
        end)
    end)
end
