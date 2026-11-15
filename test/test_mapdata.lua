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
        h.it("every list is rows of a name and a number, for a zone MapInfo knows", function()
            for _, key in ipairs({ "HERBS", "ORE", "FISH" }) do
                for id, list in pairs(MapData[key]) do
                    h.truthy(MapInfo.LEVELS[id], key .. " " .. id)
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
        h.it("fish run most common first, 3% or more, eight at most, only where there is a Fishing line", function()
            for id, list in pairs(MapData.FISH) do
                h.truthy(MapInfo.FISHING[id], id)
                h.truthy(#list <= 8, id)
                for i, row in ipairs(list) do
                    h.truthy(row[2] >= 3 and row[2] <= 100, id)
                    h.truthy(i == 1 or list[i - 1][2] >= row[2], id)
                end
            end
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
    end)
end
