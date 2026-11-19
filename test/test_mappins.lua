return function(h, loaded)
    local MapPins = loaded.ns.MapPins

    local BARRENS, SEARING_GORGE = 1413, 1427

    h.describe("MapPins.For", function()
        h.it("gives the Barrens its three doors, as fractions of the map", function()
            local pins = MapPins.For(BARRENS)
            h.eq(#pins, 3)
            h.eq(pins[1].rows[1][1], "Wailing Caverns")
            h.eq(pins[1].rows[1][2], "15-25")
            h.eq(pins[1].kind, "dungeon")
            h.eq(pins[1].x, 0.455)
            h.eq(pins[1].y, 0.355)
            h.eq(pins[3].rows[1][1], "Razorfen Downs")
        end)
        h.it("doors on one spot share a pin: Blackrock Mountain's three", function()
            local pins = MapPins.For(SEARING_GORGE)
            h.eq(#pins, 1)
            h.eq(#pins[1].rows, 3)
            h.eq(pins[1].rows[2][1], "Lower Blackrock Spire")
            h.eq(pins[1].rows[3][2], "58-60")
        end)
        h.it("a shared pin is a raid's only when every door is a raid", function()
            local mixed = MapPins.For(1, { { 1, 10, 10, "raid", "A" }, { 1, 10, 10, "dungeon", "B", 5, 9 } })
            h.eq(#mixed, 1)
            h.eq(mixed[1].kind, "dungeon")
            local raids = MapPins.For(1, { { 1, 10, 10, "raid", "A" }, { 1, 10, 10, "raid", "B", 60, 60 } })
            h.eq(raids[1].kind, "raid")
            h.eq(raids[1].rows[1][2], "Raid")
            h.eq(raids[1].rows[2][2], "60")
        end)
        h.it("a dungeon with no levels says nothing after its name", function()
            h.eq(MapPins.For(1, { { 1, 10, 10, "dungeon", "A" } })[1].rows[1][2], "")
        end)
        h.it("leaves out a malformed row and keeps the rest", function()
            local pins = MapPins.For(1, {
                { 1, 101, 10, "dungeon", "off the map" },
                { 1, 10, -1, "dungeon", "off the map" },
                { 1, "10", 10, "dungeon", "words for a number" },
                { 1, 10, 10, "delve", "no such kind" },
                { 1, 10, 10, "dungeon" },
                "not a row",
                { 2, 10, 10, "dungeon", "another map" },
                { 1, 20, 30, "dungeon", "Good", 1, 2 },
            })
            h.eq(#pins, 1)
            h.eq(pins[1].rows[1][1], "Good")
        end)
        h.it("gives an empty list for a map with no doors, no map, or no table", function()
            h.eq(#MapPins.For(1414), 0)
            h.eq(#MapPins.For(nil), 0)
            h.eq(#MapPins.For("1413"), 0)
            h.eq(#MapPins.For(1, "nothing"), 0)
        end)
    end)

    h.describe("MapPins.ENTRANCES", function()
        h.it("every row is well formed, so every door gets its pin", function()
            local doors = 0
            local maps = {}
            for _, row in ipairs(MapPins.ENTRANCES) do
                maps[row[1]] = true
            end
            for mapID in pairs(maps) do
                for _, pin in ipairs(MapPins.For(mapID)) do
                    doors = doors + #pin.rows
                end
            end
            h.eq(doors, #MapPins.ENTRANCES)
        end)
    end)
end
