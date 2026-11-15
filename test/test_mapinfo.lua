return function(h, loaded)
    local MapInfo = loaded.ns.MapInfo

    local KALIMDOR, BARRENS, DUROTAR, ORGRIMMAR, BADLANDS, SHENDRALAS = 1414, 1413, 1411, 1454, 1418, 2652
    local RIVERGLADES, ZEPHRAS = 2548, 2521

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
        h.it("a neighbouring zone at the edge of a zone's own map never takes over", function()
            h.eq(MapInfo.Pick(2482, 1452), 2482)        -- Winterspring at the edge of Mount Hyjal's map
            h.eq(MapInfo.Pick(BARRENS, DUROTAR), BARRENS)
            h.eq(MapInfo.Pick(KALIMDOR, 1452), 1452)    -- a continent still follows the cursor
        end)
        h.it("the zone round a city never takes over the city's own map", function()
            h.eq(MapInfo.Pick(ORGRIMMAR, DUROTAR), ORGRIMMAR)
            h.eq(MapInfo.Pick(ORGRIMMAR, nil), ORGRIMMAR)
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
        if not lines then
            return "nil"
        end
        local texts = {}
        for i, line in ipairs(lines) do
            texts[i] = line.text
        end
        return table.concat(texts, " / ")
    end

    h.describe("MapInfo.Lines", function()
        h.it("a zone with both: name, levels, fishing", function()
            h.eq(joined(MapInfo.Lines(BARRENS, "The Barrens")),
                "The Barrens / Levels 10-25 / Fishing 1 (no getaways at 75)")
        end)
        h.it("one level reads singular", function()
            h.eq(MapInfo.Lines(2482, "Mount Hyjal")[2].text, "Level 60")
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

    -- The gathering lines against a small stand-in for the generated data.
    local ns = loaded.ns
    local ALL = { herbs = true, ore = true, fish = true, skins = true }
    local FAKE = {
        HERBS = { [BARRENS] = { { "Peacebloom", 1 }, { "Kingsblood", 125 } }, [BADLANDS] = { { "Firebloom", 205 } },
            [SHENDRALAS] = { { "Icecap", 290 } } },
        ORE = { [BARRENS] = { { "Copper Vein", 1 }, { "Silver Vein", 75 } } },
        FISH = { [BARRENS] = { { "Oily Blackmouth", 41 }, { "Stranglekelp", 6 } } },
        SKINS = { [BARRENS] = { { "Light Leather", 62 }, { "Ruined Leather Scraps", 21 }, { "Medium Leather", 11 },
            { "Light Hide", 5 }, { "Deviate Scale", 0 } }, [ZEPHRAS] = { { "Silithid Chitin", 100 } } },
        CLASSIC_NODES = { [BADLANDS] = true },
        CLASSIC_FISH = {},
    }
    local function with(data, fn)
        local real = ns.MapData
        ns.MapData = data
        local ok, err = pcall(fn)
        ns.MapData = real
        if not ok then
            error(err, 0)
        end
    end
    local function kinds(lines)
        local out = {}
        for i, line in ipairs(lines) do
            out[i] = line.kind or "-"
        end
        return table.concat(out, " ")
    end

    h.describe("MapInfo.Lines with gathering", function()
        h.it("all on: herbs and ore lines follow fishing, each list marked", function()
            with(FAKE, function()
                local lines = MapInfo.Lines(BARRENS, "The Barrens", ALL)
                h.eq(joined(lines),
                    "The Barrens / Levels 10-25 / Fishing 1 (no getaways at 75) / Herbs 1-125 / Ore 1-75"
                    .. " / Skins: Ruined, Light, Medium")
                h.eq(kinds(lines), "- - fish herbs ore skins")
            end)
        end)
        h.it("a switch off drops its line, or for fish only its mark", function()
            with(FAKE, function()
                local lines = MapInfo.Lines(BARRENS, nil, { herbs = false, ore = true, fish = false })
                h.eq(joined(lines), "Levels 10-25 / Fishing 1 (no getaways at 75) / Ore 1-75")
                h.eq(kinds(lines), "- - ore")
            end)
        end)
        h.it("no switches given reads as the three lines there were before", function()
            with(FAKE, function()
                local lines = MapInfo.Lines(BARRENS, "The Barrens")
                h.eq(joined(lines), "The Barrens / Levels 10-25 / Fishing 1 (no getaways at 75)")
                h.eq(kinds(lines), "- - -")
            end)
        end)
        h.it("the Skins line names the grades worth a tenth of the skins, lowest first, or none", function()
            with(FAKE, function()
                local only = { skins = true }
                h.eq(joined(MapInfo.Lines(BARRENS, nil, only)),
                    "Levels 10-25 / Fishing 1 (no getaways at 75) / Skins: Ruined, Light, Medium")
                h.eq(joined(MapInfo.Lines(ZEPHRAS, nil, only)), "Levels 1-12 / Skins")
                h.eq(joined(MapInfo.Lines(BARRENS, nil, { skins = false })),
                    "Levels 10-25 / Fishing 1 (no getaways at 75)")
            end)
        end)
        h.it("herbs but no ore is one line, and one skill reads as one number", function()
            with(FAKE, function()
                h.eq(joined(MapInfo.Lines(BADLANDS, "Badlands", ALL)), "Badlands / Levels 35-45 / Herbs 205")
            end)
        end)
        h.it("a zone known only for what grows there still shows, and can be picked", function()
            with(FAKE, function()
                h.eq(joined(MapInfo.Lines(SHENDRALAS, "Shen'dralas", ALL)), "Shen'dralas / Herbs 290")
                h.eq(MapInfo.Pick(KALIMDOR, SHENDRALAS, ALL), SHENDRALAS)
                h.eq(MapInfo.Pick(BARRENS, SHENDRALAS, ALL), SHENDRALAS)
            end)
        end)
        h.it("with its switch off such a zone is unknown again: no bare name, and never picked", function()
            with(FAKE, function()
                local noHerbs = { herbs = false, ore = true, fish = true }
                h.eq(MapInfo.Lines(SHENDRALAS, "Shen'dralas", noHerbs), nil)
                h.eq(MapInfo.Lines(SHENDRALAS, "Shen'dralas"), nil)
                h.eq(MapInfo.Pick(KALIMDOR, SHENDRALAS, noHerbs), nil)
                h.eq(MapInfo.Pick(BARRENS, SHENDRALAS), BARRENS)
            end)
        end)
        h.it("a zone round a map known only by its lists takes over only while those lists are off", function()
            with(FAKE, function()
                h.eq(MapInfo.Pick(SHENDRALAS, 1444, ALL), SHENDRALAS)  -- Feralas at Shen'dralas' edge
                h.eq(MapInfo.Pick(SHENDRALAS, 1444), 1444)
            end)
        end)
        h.it("a catch list with no known skill gets a bare Fishing line, only while Fish list is on", function()
            with({ FISH = { [RIVERGLADES] = { { "Raw Rockscale Cod", 22 } } } }, function()
                local lines = MapInfo.Lines(RIVERGLADES, "Riverglades", ALL)
                h.eq(joined(lines), "Riverglades / Levels 36-44 / Fishing")
                h.eq(kinds(lines), "- - fish")
                h.eq(joined(MapInfo.Lines(RIVERGLADES, "Riverglades", { fish = false })), "Riverglades / Levels 36-44")
            end)
        end)
        h.it("a zone the data has never heard of keeps its old lines", function()
            with(FAKE, function()
                h.eq(joined(MapInfo.Lines(2482, "Mount Hyjal", ALL)), "Mount Hyjal / Level 60")
                h.eq(MapInfo.Lines(KALIMDOR, "Kalimdor", ALL), nil)
            end)
        end)
        h.it("missing or broken data shows the old lines, never an error", function()
            local broken = { false, "junk", { HERBS = "junk" }, { HERBS = { [BARRENS] = "junk" } },
                { HERBS = { [BARRENS] = { "Peacebloom" } } }, { ORE = { [BARRENS] = { { "Copper Vein" } } } },
                { FISH = { [BARRENS] = { { 41, "Oily Blackmouth" } } } }, { HERBS = { [BARRENS] = {} } } }
            for _, data in ipairs(broken) do
                with(data or nil, function()
                    local lines = MapInfo.Lines(BARRENS, "The Barrens", ALL)
                    h.eq(joined(lines), "The Barrens / Levels 10-25 / Fishing 1 (no getaways at 75)")
                    h.eq(kinds(lines), "- - -")
                    h.eq(MapInfo.List("herbs", BARRENS), nil)
                end)
            end
        end)
    end)

    h.describe("MapInfo.List", function()
        local function flat(list)
            local out = { list.title }
            for i, row in ipairs(list.rows) do
                out[i + 1] = row[1] .. "=" .. row[2]
            end
            out[#out + 1] = list.note or "no note"
            return table.concat(out, " / ")
        end
        h.it("herbs and ore read name and skill", function()
            with(FAKE, function()
                h.eq(flat(MapInfo.List("herbs", BARRENS)), "Herbalism / Peacebloom=1 / Kingsblood=125 / no note")
                h.eq(flat(MapInfo.List("ore", BARRENS)), "Mining / Copper Vein=1 / Silver Vein=75 / no note")
            end)
        end)
        h.it("fish read name and share", function()
            with(FAKE, function()
                h.eq(flat(MapInfo.List("fish", BARRENS)), "Fishing / Oily Blackmouth=41% / Stranglekelp=6% / no note")
            end)
        end)
        h.it("a list from Classic's pages says so; missing marks read as Forever's", function()
            with(FAKE, function()
                h.eq(flat(MapInfo.List("herbs", BADLANDS)),
                    "Herbalism / Firebloom=205 / Classic figures, not checked on Forever")
            end)
            with({ FISH = FAKE.FISH, CLASSIC_FISH = { [BARRENS] = true } }, function()
                h.eq(MapInfo.List("fish", BARRENS).note, "Classic figures, not checked on Forever")
            end)
            with({ FISH = FAKE.FISH, CLASSIC_FISH = "junk" }, function()
                h.eq(MapInfo.List("fish", BARRENS).note, nil)
            end)
        end)
        h.it("skins read name and share, a rare one as under one percent", function()
            with(FAKE, function()
                h.eq(flat(MapInfo.List("skins", BARRENS)), "Skinning / Light Leather=62% / Ruined Leather Scraps=21%"
                    .. " / Medium Leather=11% / Light Hide=5% / Deviate Scale=<1% / no note")
            end)
        end)
        h.it("no such list, or no such kind, is nil", function()
            with(FAKE, function()
                h.eq(MapInfo.List("ore", BADLANDS), nil)
                h.eq(MapInfo.List("tailoring", BARRENS), nil)
                h.eq(MapInfo.List(nil, BARRENS), nil)
            end)
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
        h.it("has the 42 ranges copied from GoblinPS and Zephras Isle's from Wowhead", function()
            local n = 0
            for _ in pairs(MapInfo.LEVELS) do
                n = n + 1
            end
            h.eq(n, 43)
            h.eq(table.concat(MapInfo.LEVELS[ZEPHRAS], "-"), "1-12")
        end)
        h.it("the starter zones and the second tier are told apart", function()
            h.eq(table.concat(MapInfo.FISHING[DUROTAR], " "), "1 25")
            h.eq(table.concat(MapInfo.FISHING[BARRENS], " "), "1 75")
            h.eq(table.concat(MapInfo.FISHING[1451], " "), "330 425")  -- Silithus
        end)
    end)
end
