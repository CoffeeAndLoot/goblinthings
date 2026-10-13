return function(h, loaded)
    local Features = loaded.ns.Features

    h.describe("Features.LIST", function()
        h.it("holds the eight switches in window order", function()
            local keys = {}
            for _, f in ipairs(Features.LIST) do
                keys[#keys + 1] = f.key
            end
            h.eq(table.concat(keys, " "), "autoAccept autoTurnIn autoSellJunk autoRepair declineDuels "
                .. "declineGuild cameraDistance cinematics")
        end)
        h.it("every stored switch's default is valid; the camera has none, the CVar is its store", function()
            for _, f in ipairs(Features.LIST) do
                if f.key == "cameraDistance" then
                    h.eq(f.default, nil, f.key)
                else
                    h.truthy(Features.Valid(f, f.default), f.key)
                end
            end
        end)
        h.it("the declines start off, the chores on, cinematics at repeats only", function()
            h.eq(Features.ByKey("declineDuels").default, false)
            h.eq(Features.ByKey("declineGuild").default, false)
            h.eq(Features.ByKey("autoAccept").default, true)
            h.eq(Features.ByKey("autoRepair").default, true)
            h.eq(Features.ByKey("cinematics").default, "repeats")
        end)
    end)

    h.describe("Features.ByKey", function()
        h.it("finds a feature and returns nil for an unknown key", function()
            h.eq(Features.ByKey("autoRepair").label, "Auto repair")
            h.eq(Features.ByKey("autoDance"), nil)
            h.eq(Features.ByKey(nil), nil)
        end)
    end)

    h.describe("Features.Valid", function()
        h.it("a check takes only a boolean", function()
            local f = Features.ByKey("autoAccept")
            h.truthy(Features.Valid(f, true))
            h.truthy(Features.Valid(f, false))
            h.falsy(Features.Valid(f, nil))
            h.falsy(Features.Valid(f, "yes"))
            h.falsy(Features.Valid(f, 1))
        end)
        h.it("a choice takes only one of its values", function()
            local f = Features.ByKey("cinematics")
            h.truthy(Features.Valid(f, "off"))
            h.truthy(Features.Valid(f, "repeats"))
            h.truthy(Features.Valid(f, "all"))
            h.falsy(Features.Valid(f, "sometimes"))
            h.falsy(Features.Valid(f, nil))
        end)
        h.it("a slider takes a number in its range", function()
            local f = Features.ByKey("cameraDistance")
            h.truthy(Features.Valid(f, 1))
            h.truthy(Features.Valid(f, 2.5))
            h.truthy(Features.Valid(f, 4))
            h.falsy(Features.Valid(f, 0.9))
            h.falsy(Features.Valid(f, 4.1))
            h.falsy(Features.Valid(f, "3"))
            h.falsy(Features.Valid(f, 0 / 0))
        end)
        h.it("no feature is never valid", function()
            h.falsy(Features.Valid(nil, true))
        end)
    end)

    h.describe("Features.Sections", function()
        h.it("groups rows by section in LIST order", function()
            local names, counts = {}, {}
            for _, s in ipairs(Features.Sections()) do
                names[#names + 1] = s.name
                counts[#counts + 1] = #s.features
            end
            h.eq(table.concat(names, " "), "Quests Vendors Social Camera Cinematics")
            h.eq(table.concat(counts, " "), "2 2 2 1 1")
        end)
    end)
end
