return function(h, loaded)
    local QuestPlates = loaded.ns.QuestPlates

    local function objective(text, completed)
        return { kind = "objective", text = text, completed = completed }
    end

    h.describe("QuestPlates.Remaining", function()
        h.it("is what is still to go from an objective's figures", function()
            h.eq(QuestPlates.Remaining({ { kind = "title", text = "Kobold Camp Cleanup" },
                objective("Kobold Vermin slain: 4/10", false) }), 6)
            h.eq(QuestPlates.Remaining({ objective("Spider Legs: 7 / 8", false) }), 1)
        end)
        h.it("is the smallest across several objectives", function()
            h.eq(QuestPlates.Remaining({ objective("Kobold Vermin slain: 4/10", false),
                objective("Linen Scraps: 7/8", false) }), 1)
        end)
        h.it("counts a finished objective for nothing", function()
            h.eq(QuestPlates.Remaining({ objective("Kobold Vermin slain: 10/10", true) }), nil)
            h.eq(QuestPlates.Remaining({ objective("Kobold Vermin slain: 10/10", false) }), nil)
            h.eq(QuestPlates.Remaining({ objective("Kobold Vermin slain: 10/10", true),
                objective("Linen Scraps: 2/8", false) }), 6)
        end)
        h.it("counts an unfinished objective with no figures as one", function()
            h.eq(QuestPlates.Remaining({ objective("Slay Hogger", false) }), 1)
            h.eq(QuestPlates.Remaining({ objective("Slay Hogger", true) }), nil)
            h.eq(QuestPlates.Remaining({ objective(nil, false) }), 1)  -- a secret text is unreadable
            h.eq(QuestPlates.Remaining({ objective(nil, true) }), nil)
        end)
        h.it("never counts a title or any other line", function()
            h.eq(QuestPlates.Remaining({ { kind = "title", text = "4/10" },
                { kind = "other", text = "Level 7 (4/10)" } }), nil)
        end)
        h.it("is nothing for no lines or bad input", function()
            h.eq(QuestPlates.Remaining({}), nil)
            h.eq(QuestPlates.Remaining(nil), nil)
            h.eq(QuestPlates.Remaining("4/10"), nil)
            h.eq(QuestPlates.Remaining({ "4/10", 5, objective("Boars: 1/3", false) }), 2)
        end)
    end)
end
