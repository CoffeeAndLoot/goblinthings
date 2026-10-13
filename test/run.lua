-- Run from the repository root through lupa (see CLAUDE.md).
local harness = dofile("test/harness.lua")

-- Same (addonName, ns) the client passes, loaded in TOC order into one ns.
-- API.lua and Core.lua touch Blizzard globals, so they are not loaded here.
-- A missing module is a hard failure: a suite that silently skips proves nothing.
local modules = {
    { "Features", "GoblinThings/Features.lua" },
    { "Hands", "GoblinThings/Hands.lua" },
    { "Vendor", "GoblinThings/Vendor.lua" },
    { "Camera", "GoblinThings/Camera.lua" },
    { "Cinematics", "GoblinThings/Cinematics.lua" },
    { "Decline", "GoblinThings/Decline.lua" },
    { "TrackerSort", "GoblinThings/TrackerSort.lua" },
    { "Look", "GoblinThings/Look.lua" },
    { "Options", "GoblinThings/Options.lua" },
    { "Window", "GoblinThings/Window.lua" },
    { "MinimapButton", "GoblinThings/MinimapButton.lua" },
}

local ns = {}
local loaded = { ns = ns }
for i = 1, #modules do
    local name, path = modules[i][1], modules[i][2]
    loaded[name] = assert(loadfile(path))("GoblinThings", ns)
end

local suites = {
    "test/test_features.lua",
    "test/test_look.lua",
    "test/test_camera.lua",
    "test/test_options.lua",
    "test/test_hands.lua",
    "test/test_vendor.lua",
    "test/test_cinematics.lua",
    "test/test_decline.lua",
    "test/test_trackersort.lua",
    "test/test_minimap.lua",
    "test/test_window.lua",
    "test/test_api_tracker.lua",
}

for i = 1, #suites do
    dofile(suites[i])(harness, loaded)
end

os.exit(harness.run())
