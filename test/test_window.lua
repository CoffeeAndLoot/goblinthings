return function(h, loaded)
    local Window = loaded.ns.Window
    local L = Window.LAYOUT

    h.describe("Window.WellHeight", function()
        h.it("is the padding plus a header per section and a row per feature", function()
            local sections = { { name = "A", features = { 1, 2 } }, { name = "B", features = { 3 } } }
            h.eq(Window.WellHeight(sections), 2 * L.WELL_PAD + 2 * L.SECTION + 3 * L.ROW)
        end)
        h.it("fits every switch under its five headers", function()
            h.eq(Window.WellHeight(loaded.ns.Features.Sections()),
                2 * L.WELL_PAD + 5 * L.SECTION + #loaded.ns.Features.LIST * L.ROW)
        end)
    end)
end
