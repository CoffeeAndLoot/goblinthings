return function(h, loaded)
    local Window = loaded.ns.Window
    local L = Window.LAYOUT
    local Features = loaded.ns.Features

    h.describe("Window.PageHeight", function()
        h.it("is the padding plus a row per feature", function()
            local section = { name = "A", features = { {}, {} } }
            h.eq(Window.PageHeight(section), 2 * L.WELL_PAD + 2 * L.ROW)
        end)
        h.it("adds one header per run of a group, and the note", function()
            local section = { name = "A", note = "n", features = {
                {}, { group = "G" }, { group = "G" }, { group = "H" },
            } }
            h.eq(Window.PageHeight(section), 2 * L.WELL_PAD + 4 * L.ROW + 2 * L.GROUP + L.NOTE)
        end)
    end)

    h.describe("Window.WIDTH", function()
        h.it("is wide enough for ten tabs at 82 px", function()
            h.eq(math.floor((Window.WIDTH - 2 * L.PAD + 9) / 10), 82)
        end)
    end)

    h.describe("Window.Height", function()
        h.it("is the frame around the tallest page: the Quests tab", function()
            local sections = Features.Sections()
            h.eq(Window.Height(sections), L.TOP_EDGE + L.HEADER + L.PAD + L.TAB_H + L.PAD
                + Window.PageHeight(sections[1]) + L.FOOT)
            for _, s in ipairs(sections) do
                h.truthy(Window.PageHeight(s) <= Window.PageHeight(sections[1]), s.name)
            end
        end)
    end)
end
