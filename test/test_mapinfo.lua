return function(h, loaded)
    local MapInfo = loaded.ns.MapInfo

    local KALIMDOR, BARRENS, DUROTAR, ORGRIMMAR, BADLANDS, SHENDRALAS = 1414, 1413, 1411, 1454, 1418, 2652

    h.describe("MapInfo.Pick", function()
        h.it("a continent shows the zone under the cursor", function()
            h.eq(MapInfo.Pick(KALIMDOR, BARRENS), BARRENS)
        end)
        h.it("a continent shows nothing off the land or with the cursor away", function()
            h.eq(MapInfo.Pick(KALIMDOR, nil), nil)
            h.eq(MapInfo.Pick(KALIMDOR, KALIMDOR), nil)
        end)
        h.it("a zone's own map shows that zone, hovered or not", function()
            h.eq(MapInfo.Pick(BARRENS, nil), BARRENS)
            h.eq(MapInfo.Pick(BARRENS, BARRENS), BARRENS)
        end)
        h.it("a city drawn inside a zone's map shows the city while hovered", function()
            h.eq(MapInfo.Pick(DUROTAR, ORGRIMMAR), ORGRIMMAR)
        end)
        h.it("a hovered map it knows nothing about falls back to the shown one", function()
            h.eq(MapInfo.Pick(BARRENS, SHENDRALAS), BARRENS)
            h.eq(MapInfo.Pick(KALIMDOR, SHENDRALAS), nil)
        end)
        h.it("no answer from the game shows nothing", function()
            h.eq(MapInfo.Pick(nil, nil), nil)
            h.eq(MapInfo.Pick("1413", nil), nil)
        end)
    end)

    local function joined(lines)
        return lines and table.concat(lines, " / ") or "nil"
    end

    h.describe("MapInfo.Lines", function()
        h.it("a zone with both: name, levels, fishing", function()
            h.eq(joined(MapInfo.Lines(BARRENS, "The Barrens")),
                "The Barrens / Levels 10-25 / Fishing 1 (no getaways at 75)")
        end)
        h.it("one level reads singular", function()
            h.eq(MapInfo.Lines(2482, "Mount Hyjal")[2], "Level 60")
        end)
        h.it("a line it has no data for is left out", function()
            h.eq(joined(MapInfo.Lines(BADLANDS, "Badlands")), "Badlands / Levels 35-45")
            h.eq(joined(MapInfo.Lines(ORGRIMMAR, "Orgrimmar")), "Orgrimmar / Fishing 1 (no getaways at 75)")
        end)
        h.it("a map it knows nothing about has no lines", function()
            h.eq(MapInfo.Lines(SHENDRALAS, "Shen'dralas"), nil)
            h.eq(MapInfo.Lines(KALIMDOR, "Kalimdor"), nil)
        end)
        h.it("no name from the game still gives the numbers", function()
            h.eq(joined(MapInfo.Lines(BARRENS, nil)), "Levels 10-25 / Fishing 1 (no getaways at 75)")
        end)
    end)

    h.describe("MapInfo data", function()
        h.it("every level range is low <= high, within 1-60", function()
            for id, range in pairs(MapInfo.LEVELS) do
                h.truthy(range[1] >= 1 and range[1] <= range[2] and range[2] <= 60, id)
            end
        end)
        h.it("every fishing pair is one of the six Classic tiers", function()
            local tiers = { ["1 25"] = true, ["1 75"] = true, ["55 150"] = true, ["130 225"] = true,
                ["205 300"] = true, ["330 425"] = true }
            for id, pair in pairs(MapInfo.FISHING) do
                h.truthy(tiers[pair[1] .. " " .. pair[2]], id)
            end
        end)
        h.it("has the 42 ranges copied from GoblinPS", function()
            local n = 0
            for _ in pairs(MapInfo.LEVELS) do
                n = n + 1
            end
            h.eq(n, 42)
        end)
        h.it("the starter zones and the second tier are told apart", function()
            h.eq(table.concat(MapInfo.FISHING[DUROTAR], " "), "1 25")
            h.eq(table.concat(MapInfo.FISHING[BARRENS], " "), "1 75")
            h.eq(table.concat(MapInfo.FISHING[1451], " "), "330 425")  -- Silithus
        end)
    end)
end
