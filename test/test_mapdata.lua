-- The generated gathering lists (tools/make_gathering.py): shaped and sorted
-- as MapInfo and the readout rely on.
return function(h, loaded)
    local MapData, MapInfo = loaded.ns.MapData, loaded.ns.MapInfo
    local BARRENS, DARKSHORE = 1413, 1439

    local function names(list)
        local out = {}
        for i, row in ipairs(list) do
            out[i] = row[1]
        end
        return table.concat(out, ", ")
    end

    h.describe("MapData", function()
        h.it("every list is rows of a name and a number, keyed by a map ID", function()
            for _, key in ipairs({ "HERBS", "ORE", "FISH", "SKINS" }) do
                for id, list in pairs(MapData[key]) do
                    h.truthy(type(id) == "number" and id > 1400, key .. " " .. tostring(id))
                    h.truthy(#list > 0, key .. " " .. id)
                    for _, row in ipairs(list) do
                        h.truthy(type(row[1]) == "string" and row[1] ~= "" and type(row[2]) == "number",
                            key .. " " .. id)
                    end
                end
            end
        end)
        h.it("herbs and ore run easiest first, then by name, with no name twice", function()
            for _, key in ipairs({ "HERBS", "ORE" }) do
                for id, list in pairs(MapData[key]) do
                    local seen = {}
                    for i, row in ipairs(list) do
                        h.truthy(row[2] >= 1 and row[2] <= 305 and not seen[row[1]], key .. " " .. id)
                        seen[row[1]] = true
                        local before = list[i - 1]
                        h.truthy(not before or before[2] < row[2]
                            or (before[2] == row[2] and before[1] < row[1]), key .. " " .. id)
                    end
                end
            end
        end)
        h.it("fish run most common first, 3% or more, eight at most", function()
            for id, list in pairs(MapData.FISH) do
                h.truthy(#list <= 8, id)
                for i, row in ipairs(list) do
                    h.truthy(row[2] >= 3 and row[2] <= 100, id)
                    h.truthy(i == 1 or list[i - 1][2] >= row[2], id)
                end
            end
        end)
        h.it("skins run most common first, ten at most, and the special ones are in however rare", function()
            for id, list in pairs(MapData.SKINS) do
                h.truthy(#list <= 10, id)
                for i, row in ipairs(list) do
                    h.truthy(row[2] >= 0 and row[2] <= 100, id)
                    h.truthy(i == 1 or list[i - 1][2] >= row[2], id)
                end
            end
            h.eq(MapData.SKINS[BARRENS][1][1], "Light Leather")
            h.truthy(names(MapData.SKINS[BARRENS]):find("Deviate Scale"))
            h.truthy(names(MapData.SKINS[1449]):find("Devilsaur Leather"))   -- Un'Goro Crater
            h.truthy(names(MapData.SKINS[1452]):find("Frostsaber Leather"))  -- Winterspring
            h.truthy(names(MapData.SKINS[1433]):find("Black Whelp Scale"))   -- Redridge Mountains
            h.eq(names(MapData.SKINS[1431]):find("Dreamscale"), nil)         -- Duskwood's raid dragon
        end)
        h.it("the Barrens reads as its Wowhead Forever page did on 2026-11-14", function()
            h.eq(names(MapData.HERBS[BARRENS]), "Peacebloom, Silverleaf, Earthroot, Mageroyal, Briarthorn, "
                .. "Stranglekelp, Bruiseweed, Wild Steelbloom, Grave Moss, Kingsblood")
            h.eq(names(MapData.ORE[BARRENS]), "Copper Vein, Tin Vein, Silver Vein")
            h.eq(MapData.FISH[BARRENS][1][1] .. " " .. MapData.FISH[BARRENS][1][2], "Raw Rainbow Fin Albacore 22")
            h.eq(#MapData.FISH[BARRENS], 7)
        end)
        h.it("quest objects and quest items never made it in", function()
            h.eq(names(MapData.HERBS[DARKSHORE]):find("Sea"), nil)         -- Beached Sea Creature
            h.eq(names(MapData.FISH[DARKSHORE]):find("Gaffer Jack"), nil)  -- a quest item, 4% of its catch
            h.eq(names(MapData.HERBS[BARRENS]):find("Serpentbloom"), nil)
        end)
        h.it("Forever's own nodes are in, and the Classic marks name zones that have such a list", function()
            h.eq(names(MapData.ORE[1411]), "Copper Vein, Poor Copper Vein")  -- Durotar
            h.eq(names(MapData.ORE[1438]), "Chunk of Amber, Large Chunk of Amber")  -- Teldrassil
            for id in pairs(MapData.CLASSIC_NODES) do
                h.truthy(MapData.HERBS[id] or MapData.ORE[id], id)
            end
            for id in pairs(MapData.CLASSIC_FISH) do
                h.truthy(MapData.FISH[id], id)
            end
            h.eq(MapData.CLASSIC_NODES[BARRENS], nil)
            h.eq(MapData.CLASSIC_FISH[BARRENS], nil)
        end)
        h.it("Forever's new zones are in: Zephras Isle, Riverglades, Shen'dralas, Mount Hyjal", function()
            h.eq(names(MapData.HERBS[2521]), "Peacebloom, Silverleaf, Earthroot, Mageroyal")
            h.eq(names(MapData.FISH[2521]), "Raw Brilliant Smallfish, Raw Longjaw Mud Snapper")
            h.eq(MapData.FISH[2548][1][1], "Raw Rockscale Cod")
            h.eq(names(MapData.HERBS[2652]), "Bruiseweed, Grave Moss")
            h.eq(names(MapData.ORE[2652]), "Iron Deposit, Mithril Deposit")
            h.eq(names(MapData.ORE[2482]), "Rich Thorium Vein, Heavy Thorium Vein")
            h.eq(MapInfo.LEVELS[2652], nil)  -- Wowhead gives Shen'dralas no level range
        end)
    end)
end
