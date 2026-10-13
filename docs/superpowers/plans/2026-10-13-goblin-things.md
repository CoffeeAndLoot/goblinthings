# Goblin Things Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build Goblin Things, a WoW Forever addon of eight quality-of-life switches in one Goblin-look window.

**Architecture:** Goblin Flyout's skeleton (API.lua with `attempt()`, Look, the window, an options-page stub, a minimap button, `guard()` in Core, the lupa test harness, CI) plus GoblinQuest's pure quest (`Hands`) and vendor (`Vendor`) rules. Every switch is a row of data in `Features.LIST`; each rule is a small pure module that decides, and `API.lua` is the only file that acts on the game.

**Tech Stack:** Lua 5.1 (WoW addon, interface 16001), lupa for tests on Windows, Lua 5.1 + luacheck in CI, lua-language-server, Python + Pillow for the icon.

**Spec:** `docs/superpowers/specs/2026-10-13-goblin-things-design.md`

## Global Constraints

- Repo root `D:\GoblinThings`; the addon folder is `GoblinThings/` inside it.
- Interface `16001`; TOC version `2026.10.13`; SavedVariable `GoblinThingsDB` (account-wide).
- Blizzard source of truth: `D:\wow-api\1.60.1.70291\Interface\AddOns`. Never guess an API, event or template name.
- `API.lua` is the only file that calls Blizzard game APIs, each through `attempt()` (or `call()` for one that may be missing).
- Pure modules touch no Blizzard global at file load; `test/run.lua` loads them.
- No libraries. No Blizzard frame templates in the window, options page or minimap button; colours only from `Look.COLOUR`.
- An unknown answer from the game (nil quality, price, quest ID, tag, key) means do nothing.
- luacheck and lua-language-server at zero warnings. A new WoW global goes in both `.luacheckrc` and `.luarc.json`.
- Commit after each task: `Area: plain sentence`, ending with the line `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Never push.
- `test/run.lua` keeps two hand-kept lists (modules in TOC order, suites); every new module and suite is added there or it silently does not run.

Commands, from `D:\GoblinThings` in PowerShell:

```powershell
# Tests (always the whole suite)
python -c "import lupa.lua51 as L; lua=L.LuaRuntime(unpack_returned_tuples=True); print(lua.execute(open('test/run.lua').read().replace('os.exit(harness.run())','return harness.run()')))"

# Lint
$env:PATH = "$HOME\AppData\Local\Programs\Lua\bin;$env:PATH"
$env:LUA_PATH = "$HOME\.luarocks\share\lua\5.4\?.lua;$HOME\.luarocks\share\lua\5.4\?\init.lua;;"
lua "$HOME\.luarocks\share\lua\5.4\luacheck\main.lua" GoblinThings test --no-color --no-cache
lua-language-server --check D:\GoblinThings --checklevel=Warning --check_out_path=$env:TEMP\gt-luals.json
```

The test command prints `N passed, 0 failed` and then `0` on success; any `FAIL:` line is a failure.

## Review Focus

1. **Opening the window must not write the camera CVar.** Refresh moves the slider with `SetValue`, which fires `OnValueChanged`; only a player's drag may call `core.Set`. Owned by Task 10 (the `refreshing` guard) and pinned by a checklist entry in Task 12.
2. **A cinematic that cannot be cancelled is a vehicle ride, not a cinematic** (`CinematicFrame.lua`: `isRealCinematic = canBeCancelled`). It must never be stopped, even in mode All. Pinned by a test in Task 7.
3. **Junk in the SavedVariable** (a hand-edited or older file: `cinematics = "sometimes"`, `autoAccept = "yes"`, a stray `cameraDistance`) must reset to defaults, not break the window. Pinned by a test in Task 4.
4. **Repeats mode with no key** (race or map unknown) must do nothing, not skip a cinematic the player has never seen. Pinned by a test in Task 7.
5. **A decline with no name** (an empty or nil inviter) still says a sensible line. Pinned by a test in Task 8.

---

### Task 1: Repo skeleton, Look, icon, CI

**Files:**
- Create: `.gitignore`, `LICENSE`, `CLAUDE.md`, `.luacheckrc`, `.luarc.json`
- Create: `.github/workflows/test.yml`, `.github/workflows/release-addon.yml`
- Create: `GoblinThings/GoblinThings.toc`, `GoblinThings/Look.lua`, `GoblinThings/Media/icons/close-{32,64,128}.tga`
- Create: `tools/make_icon.py`, `tools/fonts/Cinzel.ttf`, `tools/fonts/OFL.txt`
- Generated: `GoblinThings/Media/icon.tga`, `images/thumbnail.png`
- Test: `test/harness.lua`, `test/run.lua`, `test/test_look.lua`

**Interfaces:**
- Produces: `ns.Look` with `COLOUR`, `WORDS`, `ICONS`, `RGB(name)`, `File(name, pixels)`, `Pixels(frame, units)`, `Texture(parent, layer, colour, a)`, `Text(parent, face, size, colour)`, `Outline(frame, colour, layer)`, `Style(b, style)`, `Button(parent, text, width, height, onClick, style)` (returns a button with `.label`), `Check(parent, size, onClick)` (returns a button with `.SetOn(on)`), `IconButton(parent, name, size, onClick, fallbackText)`, and new `Slider(parent, width, height, min, max, step, onChange)`.
- Produces: `test/run.lua` with the two hand-kept lists every later task appends to.

- [ ] **Step 1: Copy the unchanged files from Goblin Flyout**

```bash
cd /d/GoblinThings
mkdir -p GoblinThings/Media/icons tools/fonts test .github/workflows images
cp /d/GoblinFlyout/.gitignore /d/GoblinFlyout/LICENSE .
cp /d/GoblinFlyout/test/harness.lua test/
cp /d/GoblinFlyout/GoblinFlyout/Media/icons/close-*.tga GoblinThings/Media/icons/
cp /d/GoblinFlyout/tools/fonts/Cinzel.ttf /d/GoblinFlyout/tools/fonts/OFL.txt tools/fonts/
cp /d/GoblinFlyout/tools/make_icon.py tools/
cp /d/GoblinFlyout/GoblinFlyout/Look.lua GoblinThings/
sed -e 's/GoblinFlyout/GoblinThings/g' -e 's/Goblin Flyout/Goblin Things/g' \
    /d/GoblinFlyout/.github/workflows/test.yml > .github/workflows/test.yml
sed -e 's/GoblinFlyout/GoblinThings/g' -e 's/Goblin Flyout/Goblin Things/g' \
    /d/GoblinFlyout/.github/workflows/release-addon.yml > .github/workflows/release-addon.yml
```

- [ ] **Step 2: Write the TOC**

`GoblinThings/GoblinThings.toc` (no `X-Wago-ID` until the owner makes the Wago project):

```
## Interface: 16001
## Title: Goblin Things
## Notes: Small goblin conveniences: auto accept and turn in quests, sell junk, repair, decline duels and guild invites, skip cinematics, and zoom the camera out further. Time is money, friend.
## Author: CoffeeAndLoot
## Version: 2026.10.13
## IconTexture: Interface\AddOns\GoblinThings\Media\icon
## SavedVariables: GoblinThingsDB

API.lua
Features.lua
Hands.lua
Vendor.lua
Camera.lua
Cinematics.lua
Decline.lua
Look.lua
Options.lua
Window.lua
MinimapButton.lua
Core.lua
```

- [ ] **Step 3: Write the lint configs with every global the addon will use**

`.luacheckrc`:

```lua
std = "lua51"
max_line_length = 120
self = false
globals = {
    "GoblinThingsDB", "SLASH_GOBLINTHINGS1", "SLASH_GOBLINTHINGS2", "SlashCmdList",
}
read_globals = {
    "print", "CreateFrame", "UIParent", "UISpecialFrames", "GameTooltip",
    "Settings", "SettingsPanel", "HideUIPanel",
    "Minimap", "GetCursorPosition", "GetPhysicalScreenSize", "C_Timer",
    "IsShiftKeyDown", "C_GossipInfo", "C_QuestLog",
    "GetNumActiveQuests", "GetActiveTitle", "GetActiveQuestID",
    "GetNumAvailableQuests", "GetAvailableQuestInfo", "GetAvailableTitle",
    "GetQuestID", "QuestFlagsPVP", "QuestGetAutoAccept", "GetSuggestedGroupSize", "GetTitleText",
    "IsQuestCompletable", "GetQuestMoneyToGet", "GetNumQuestChoices",
    "SelectActiveQuest", "SelectAvailableQuest", "AcceptQuest", "AcknowledgeAutoAcceptQuest",
    "CompleteQuest", "GetQuestReward",
    "C_Container", "C_Item", "CanMerchantRepair", "GetRepairAllCost", "GetMoney", "RepairAllItems",
    "C_CVar", "CancelDuel", "DeclineGuild",
    "StopCinematic", "MovieFrame", "GetCurrentCinematicSummary", "UnitRace", "C_Map",
}
```

`.luarc.json`:

```json
{
  "runtime.version": "Lua 5.1",
  "workspace.ignoreDir": [".remember", ".superpowers", "docs"],
  "diagnostics.globals": [
    "GoblinThingsDB", "SLASH_GOBLINTHINGS1", "SLASH_GOBLINTHINGS2", "SlashCmdList",
    "print", "CreateFrame", "UIParent", "UISpecialFrames", "GameTooltip",
    "Settings", "SettingsPanel", "HideUIPanel",
    "Minimap", "GetCursorPosition", "GetPhysicalScreenSize", "C_Timer",
    "IsShiftKeyDown", "C_GossipInfo", "C_QuestLog",
    "GetNumActiveQuests", "GetActiveTitle", "GetActiveQuestID",
    "GetNumAvailableQuests", "GetAvailableQuestInfo", "GetAvailableTitle",
    "GetQuestID", "QuestFlagsPVP", "QuestGetAutoAccept", "GetSuggestedGroupSize", "GetTitleText",
    "IsQuestCompletable", "GetQuestMoneyToGet", "GetNumQuestChoices",
    "SelectActiveQuest", "SelectAvailableQuest", "AcceptQuest", "AcknowledgeAutoAcceptQuest",
    "CompleteQuest", "GetQuestReward",
    "C_Container", "C_Item", "CanMerchantRepair", "GetRepairAllCost", "GetMoney", "RepairAllItems",
    "C_CVar", "CancelDuel", "DeclineGuild",
    "StopCinematic", "MovieFrame", "GetCurrentCinematicSummary", "UnitRace", "C_Map"
  ]
}
```

- [ ] **Step 4: Write the failing Look test and the runner**

`test/test_look.lua` (Goblin Flyout's suite with this addon's path):

```lua
return function(h, loaded)
    local Look = loaded.ns.Look

    h.describe("Look.RGB", function()
        h.it("gives a palette colour as three 0..1 numbers", function()
            local r, g, b = Look.RGB("gold")
            h.eq(string.format("%.3f %.3f %.3f", r, g, b), "0.839 0.667 0.306")
        end)
        h.it("an unknown name falls back to dim, never an error", function()
            local r = Look.RGB("chartreuse")
            h.eq(r, Look.COLOUR.dim[1])
        end)
    end)

    h.describe("Look.File", function()
        local path = "Interface\\AddOns\\GoblinThings\\Media\\icons\\close-"
        h.it("picks the smallest copy at least as big as the pixels drawn", function()
            h.eq(Look.File("close", 20), path .. "32")
            h.eq(Look.File("close", 32), path .. "32")
            h.eq(Look.File("close", 33), path .. "64")
            h.eq(Look.File("close", 100), path .. "128")
        end)
        h.it("bigger than every copy gets the largest", function()
            h.eq(Look.File("close", 300), path .. "128")
        end)
        h.it("no screen size from the client gets the middle copy", function()
            h.eq(Look.File("close", nil), path .. "64")
            h.eq(Look.File("close", 0 / 0), path .. "64")
        end)
    end)
end
```

`test/run.lua`:

```lua
-- Run from the repository root through lupa (see CLAUDE.md).
local harness = dofile("test/harness.lua")

-- Same (addonName, ns) the client passes, loaded in TOC order into one ns.
-- API.lua and Core.lua touch Blizzard globals, so they are not loaded here.
-- A missing module is a hard failure: a suite that silently skips proves nothing.
local modules = {
    { "Look", "GoblinThings/Look.lua" },
}

local ns = {}
local loaded = { ns = ns }
for i = 1, #modules do
    local name, path = modules[i][1], modules[i][2]
    loaded[name] = assert(loadfile(path))("GoblinThings", ns)
end

local suites = {
    "test/test_look.lua",
}

for i = 1, #suites do
    dofile(suites[i])(harness, loaded)
end

os.exit(harness.run())
```

- [ ] **Step 5: Run the tests to see Look.File fail on the old path**

Run the test command. Expected: `2 passed, 3 failed`, each failure showing `GoblinFlyout` in the actual path.

- [ ] **Step 6: Point Look at this addon and add the slider**

In `GoblinThings/Look.lua`, replace:

```lua
Look.ICONS = "Interface\\AddOns\\GoblinFlyout\\Media\\icons\\"
```

with:

```lua
Look.ICONS = "Interface\\AddOns\\GoblinThings\\Media\\icons\\"
```

and insert before the final `return Look`:

```lua
-- A flat horizontal slider: a thin track and a gold thumb. SetThumbTexture
-- takes a file (SimpleSliderAPIDocumentation: TextureAsset), so it is given a
-- file this addon ships and the colour then replaces it. onChange(value) runs
-- on every change, a SetValue from code included: the caller tells them apart.
function Look.Slider(parent, width, height, min, max, step, onChange)
    local s = CreateFrame("Slider", nil, parent)
    s:SetSize(width, height)
    s:SetOrientation("HORIZONTAL")
    s:SetMinMaxValues(min, max)
    s:SetValueStep(step)
    s:SetObeyStepOnDrag(true)
    s:EnableMouse(true)
    local track = Look.Texture(s, "BACKGROUND", Look.COLOUR.line)
    track:SetHeight(2)
    track:SetPoint("LEFT", s, "LEFT")
    track:SetPoint("RIGHT", s, "RIGHT")
    s:SetThumbTexture(Look.ICONS .. "close-32")
    local thumb = s:GetThumbTexture()
    if thumb then
        thumb:SetColorTexture(Look.RGB("gold"))
        thumb:SetSize(10, height)
    end
    s:SetScript("OnValueChanged", function(_, value)
        onChange(value)
    end)
    return s
end
```

- [ ] **Step 7: Make the icon: "GT" on a teal disc**

In `tools/make_icon.py` change the docstring's first lines, `DEST`, `LETTERS` and `DISC`:

```python
"""Build GoblinThings/Media/icon.tga (256x256 RGBA, round): the minimap
button and the AddOns-list icon, plus images/thumbnail.png (512 px).

Goblin Flyout's icon recipe (D:\\GoblinFlyout\\tools\\make_icon.py), with Goblin
Things' letters and disc: a shaded disc with a gold rim and "GT" in Cinzel
(tools/fonts, SIL Open Font License), gold with a dark outline and a drop
shadow. Everything is drawn at 4x and shrunk for smooth edges. Coordinates
are in a 100-unit square.
Run from anywhere: python tools/make_icon.py [preview_dir]
"""
```

```python
DEST = ROOT / "GoblinThings" / "Media" / "icon.tga"
```

```python
LETTERS = "GT"
# The disc, lit centre to dark edge. GoblinQuest is forest, Goblin Flyout is
# oxblood, Goblin Things is teal.
```

```python
DISC = "teal"
```

Run: `python tools/make_icon.py` from `D:\GoblinThings`. Expected: `Wrote ...\GoblinThings\Media\icon.tga` and `Wrote ...\images\thumbnail.png`.

- [ ] **Step 8: Write CLAUDE.md**

```markdown
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Goblin Things

WoW Forever addon (interface 16001: Classic data on the 12.x engine, game type `camelot`).
Eight quality-of-life switches in one Goblin-look window: auto accept and turn in quests, auto sell
junk, auto repair, decline duels, decline guild invites, camera distance past Blizzard's 2.0, and
skipping cinematics. Spec: `docs/superpowers/specs/2026-10-13-goblin-things-design.md`.
Sibling of Goblin Flyout (`D:\GoblinFlyout`); the quest and vendor rules came from GoblinQuest
(`D:\goblinquest`, shelved).

## Rules

- Blizzard source of truth: `D:\wow-api\1.60.1.70291\Interface\AddOns` (the `forever` branch).
  `12.1.5.*` is Retail and never the authority. Never guess an API, event or template name.
- "Verified in source" is not "verified in game". Only the owner runs the client; in-game
  checks live in `docs/manual-test-checklist.md` and every UI or behaviour change adds an entry.
  Tick a box only for what the owner saw; `[-]` means skipped by choice, with the reason.
- `API.lua` is the only file that calls Blizzard game APIs, each through `attempt()`.
- Pure modules touch no Blizzard global at file load; test/run.lua loads them.
- No libraries. An unknown answer from the game means do nothing.
- The window, options page and minimap button wear the Goblin look (`Look.lua`, from Goblin
  Flyout): plain frames and colour textures, **no Blizzard frame templates**, colours only from
  `Look.COLOUR`.
- `GoblinThings/Media/icon.tga` and `images/thumbnail.png` are generated by
  `python tools/make_icon.py [preview_dir]` ("GT" on teal); never edit either by hand.
  `Media/icons/close-*.tga` are Goblin Flyout's, copied. A new or changed TGA needs a full client restart.
- Adding a file to the TOC needs a full client restart, not `/reload`. Say so.
- Calendar versions (`2026.10.13`, `.2` for a second that day), written only in the TOC.
- Commit after each change: `Area: plain sentence`. Push only when the owner asks. A release is a
  `v<TOC version>` tag: the release workflow zips the addon and posts it to Wago when the repo has
  the `WAGO_API_TOKEN` secret and the TOC an `X-Wago-ID`. CI runs the suite on Lua 5.1 and luacheck.

## How it fits together

TOC load order is `API, Features, Hands, Vendor, Camera, Cinematics, Decline, Look, Options, Window, MinimapButton, Core`.

1. `Features.LIST` is the eight switches as data: key, label, section, control (`check`, `slider`,
   `choice`) and default. The window builds its rows from it; `Options.Init` stores every feature
   with a default. The camera has none: the game's own CVar is its store.
2. `Hands` (quests), `Vendor`, `Camera`, `Cinematics` and `Decline` are pure: each takes plain values
   (views built by `API.lua`) and the settings, and says what to do.
3. `Core` routes events to them behind `guard(label, ...)` (one error per label per session) and has
   `API` carry out the result. `Core.Get(key)` / `Core.Set(key, value)` are the one door to every
   setting, the camera's CVar included.
4. Holding Shift as an NPC or vendor window opens skips every quest and vendor action that visit.

## Client facts (verified in game)

- `cameraDistanceMaxZoomFactor` keeps 2.6 and 4, the camera zooms further than at 2.0, and opening
  Options > Controls does not reset it (2026-10-13).

## Deploy

The addon folder is junctioned into the client:
`New-Item -ItemType Junction -Path "D:\World of Warcraft\_classic_beta_\Interface\AddOns\GoblinThings" -Target "D:\GoblinThings\GoblinThings"`

## Commands (this Windows box)

Tests through `lupa` from the repo root; there is no per-test filter, always run it all:

```
python -c "import lupa.lua51 as L; lua=L.LuaRuntime(unpack_returned_tuples=True); print(lua.execute(open('test/run.lua').read().replace('os.exit(harness.run())','return harness.run()')))"
```

`test/run.lua` keeps two **hand-kept lists**: pure modules (TOC order) and suites. A new module or
`test/test_*.lua` must be added there or it silently does not run.

luacheck and lua-language-server:

```
$env:PATH = "$HOME\AppData\Local\Programs\Lua\bin;$env:PATH"
$env:LUA_PATH = "$HOME\.luarocks\share\lua\5.4\?.lua;$HOME\.luarocks\share\lua\5.4\?\init.lua;;"
lua "$HOME\.luarocks\share\lua\5.4\luacheck\main.lua" GoblinThings test --no-color --no-cache
lua-language-server --check D:\GoblinThings --checklevel=Warning --check_out_path=$env:TEMP\gt-luals.json
```

Keep both at zero warnings. A new WoW global goes in both `.luacheckrc` and `.luarc.json`.
```

- [ ] **Step 9: Run tests and lint**

Run the test command. Expected: `5 passed, 0 failed`. Run luacheck: expected `0 warnings / 0 errors`.

- [ ] **Step 10: Commit**

```bash
git add -A
git commit -m "Repo: skeleton from Goblin Flyout, Look with a slider, the GT icon, CI and release workflows

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Features

**Files:**
- Create: `GoblinThings/Features.lua`
- Test: `test/test_features.lua`; modify `test/run.lua`

**Interfaces:**
- Produces: `ns.Features.LIST` (array of `{ key, label, section, control, default?, min?, max?, step?, choices?, labels? }`), `Features.ByKey(key) -> feature|nil`, `Features.Valid(feature, value) -> boolean`, `Features.Sections() -> { { name = string, features = { feature... } }... }` in LIST order.

- [ ] **Step 1: Write the failing test**

`test/test_features.lua`:

```lua
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
```

In `test/run.lua`, make the lists:

```lua
local modules = {
    { "Features", "GoblinThings/Features.lua" },
    { "Look", "GoblinThings/Look.lua" },
}
```

```lua
local suites = {
    "test/test_features.lua",
    "test/test_look.lua",
}
```

- [ ] **Step 2: Run to verify it fails**

Run the test command. Expected: a Lua error `cannot open GoblinThings/Features.lua` from the `assert(loadfile(...))`.

- [ ] **Step 3: Write Features.lua**

```lua
local _, ns = ...

-- The switches as data (spec 2026-10-13-goblin-things-design.md, Scope). The
-- window builds its rows from LIST and Options.Init stores every feature with
-- a default; the camera has none, because the game's own CVar is its store.
-- Pure: test/run.lua loads this file.
local Features = {}
ns.Features = Features

Features.LIST = {
    { key = "autoAccept", label = "Auto accept quests", section = "Quests", control = "check", default = true },
    { key = "autoTurnIn", label = "Auto turn-in quests", section = "Quests", control = "check", default = true },
    { key = "autoSellJunk", label = "Auto sell junk", section = "Vendors", control = "check", default = true },
    { key = "autoRepair", label = "Auto repair", section = "Vendors", control = "check", default = true },
    { key = "declineDuels", label = "Decline duels", section = "Social", control = "check", default = false },
    { key = "declineGuild", label = "Decline guild invites", section = "Social", control = "check",
        default = false },
    { key = "cameraDistance", label = "Camera distance", section = "Camera", control = "slider",
        min = 1.0, max = 4.0, step = 0.1 },
    { key = "cinematics", label = "Skip cinematics", section = "Cinematics", control = "choice",
        default = "repeats", choices = { "off", "repeats", "all" },
        labels = { off = "Off", repeats = "Repeats only", all = "All" } },
}

function Features.ByKey(key)
    for _, feature in ipairs(Features.LIST) do
        if feature.key == key then
            return feature
        end
    end
    return nil
end

-- Whether value is one this feature can hold.
function Features.Valid(feature, value)
    if type(feature) ~= "table" then
        return false
    end
    if feature.control == "check" then
        return type(value) == "boolean"
    elseif feature.control == "choice" then
        return type(value) == "string" and feature.labels[value] ~= nil
    elseif feature.control == "slider" then
        return type(value) == "number" and value == value and value >= feature.min and value <= feature.max
    end
    return false
end

-- { { name, features } ... }: LIST grouped by section, in LIST order.
function Features.Sections()
    local out, byName = {}, {}
    for _, feature in ipairs(Features.LIST) do
        local section = byName[feature.section]
        if not section then
            section = { name = feature.section, features = {} }
            byName[feature.section] = section
            out[#out + 1] = section
        end
        section.features[#section.features + 1] = feature
    end
    return out
end

return Features
```

- [ ] **Step 4: Run tests and lint**

Expected: `14 passed, 0 failed`; luacheck `0 warnings / 0 errors`.

- [ ] **Step 5: Commit**

```bash
git add GoblinThings/Features.lua test/test_features.lua test/run.lua
git commit -m "Features: the eight switches as data, with validation and sections

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Camera

**Files:**
- Create: `GoblinThings/Camera.lua`
- Test: `test/test_camera.lua`; modify `test/run.lua`

**Interfaces:**
- Consumes: `ns.Features.ByKey("cameraDistance")` for `min`, `max`, `step` (read at call time, never at load).
- Produces: `ns.Camera.KEY = "cameraDistance"`, `Camera.CVAR = "cameraDistanceMaxZoomFactor"`, `Camera.Clamp(value) -> number|nil` (accepts a number or a numeric string; nil for anything else), `Camera.Text(number) -> "%.1f"`.

- [ ] **Step 1: Write the failing test**

`test/test_camera.lua`:

```lua
return function(h, loaded)
    local Camera = loaded.ns.Camera

    h.describe("Camera", function()
        h.it("names the feature and Blizzard's CVar", function()
            h.eq(Camera.KEY, "cameraDistance")
            h.eq(Camera.CVAR, "cameraDistanceMaxZoomFactor")
        end)
        h.it("reads the CVar's string as a number", function()
            h.eq(Camera.Clamp("4"), 4)
            h.eq(Camera.Clamp("2.6"), 2.6)
            h.eq(Camera.Clamp(2.6), 2.6)
        end)
        h.it("rounds to the slider's step", function()
            h.eq(Camera.Clamp("3.24"), 3.2)
            h.eq(Camera.Clamp(3.26), 3.3)
        end)
        h.it("keeps a value inside 1.0 to 4.0", function()
            h.eq(Camera.Clamp(0.5), 1)
            h.eq(Camera.Clamp(9), 4)
            h.eq(Camera.Clamp("50"), 4)
        end)
        h.it("anything that is not a number is no answer", function()
            h.eq(Camera.Clamp(nil), nil)
            h.eq(Camera.Clamp("far"), nil)
            h.eq(Camera.Clamp(0 / 0), nil)
            h.eq(Camera.Clamp({}), nil)
        end)
        h.it("writes one decimal for the CVar and the window", function()
            h.eq(Camera.Text(4), "4.0")
            h.eq(Camera.Text(2.6), "2.6")
            h.eq(Camera.Text(Camera.Clamp("3.24")), "3.2")
        end)
    end)
end
```

In `test/run.lua` add `{ "Camera", "GoblinThings/Camera.lua" },` after the Features entry, and `"test/test_camera.lua",` to the suites.

- [ ] **Step 2: Run to verify it fails**

Expected: `cannot open GoblinThings/Camera.lua`.

- [ ] **Step 3: Write Camera.lua**

```lua
local _, ns = ...

-- The camera distance (spec 2026-10-13-goblin-things-design.md, Camera): the
-- game's cameraDistanceMaxZoomFactor CVar is the only store, read every time
-- the window shows and written only when the player moves our slider. The
-- range is the feature's (Features.LIST), read at call time. Pure.
local Camera = {}
ns.Camera = Camera

Camera.KEY = "cameraDistance"
Camera.CVAR = "cameraDistanceMaxZoomFactor"

-- A number or a numeric string, kept in range and rounded to the step; nil
-- for anything else (the client gave no answer).
function Camera.Clamp(value)
    local n = tonumber(value)
    if type(value) == "table" or not n or n ~= n then
        return nil
    end
    local feature = ns.Features.ByKey(Camera.KEY)
    n = math.max(feature.min, math.min(feature.max, n))
    local per = math.floor(1 / feature.step + 0.5)
    return math.floor(n * per + 0.5) / per
end

function Camera.Text(value)
    return string.format("%.1f", value)
end

return Camera
```

- [ ] **Step 4: Run tests and lint**

Expected: `20 passed, 0 failed`; luacheck clean.

- [ ] **Step 5: Commit**

```bash
git add GoblinThings/Camera.lua test/test_camera.lua test/run.lua
git commit -m "Camera: clamp and round the zoom factor to the slider's range

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Options

**Files:**
- Create: `GoblinThings/Options.lua`
- Test: `test/test_options.lua`; modify `test/run.lua`

**Interfaces:**
- Consumes: `ns.Features.LIST`, `Features.Valid`; `ns.Look.Button` (in `Register`, at call time only).
- Produces: `ns.Options.NAME = "Goblin Things"`, `Options.DEFAULT_ANGLE = 195`, `Options.Init(db) -> db` with shape `{ features = { key = value }, seen = { movies = {}, cinematics = {} }, minimap = { angle, hide }, window = { point, relativePoint, x, y } | nil }`, `Options.Register(openWindow) -> boolean`.

- [ ] **Step 1: Write the failing test**

`test/test_options.lua`:

```lua
return function(h, loaded)
    local Options = loaded.ns.Options

    h.describe("Options.Init", function()
        h.it("no SavedVariable: every stored default, empty seen lists, minimap at 195, no window", function()
            local db = Options.Init(nil)
            h.eq(db.features.autoAccept, true)
            h.eq(db.features.autoTurnIn, true)
            h.eq(db.features.autoSellJunk, true)
            h.eq(db.features.autoRepair, true)
            h.eq(db.features.declineDuels, false)
            h.eq(db.features.declineGuild, false)
            h.eq(db.features.cinematics, "repeats")
            h.eq(db.features.cameraDistance, nil)
            h.eq(next(db.seen.movies), nil)
            h.eq(next(db.seen.cinematics), nil)
            h.eq(db.minimap.angle, 195)
            h.eq(db.minimap.hide, false)
            h.eq(db.window, nil)
        end)
        h.it("keeps the table it was given and every valid value", function()
            local db = { features = { autoAccept = false, cinematics = "all" } }
            h.eq(Options.Init(db), db)
            h.eq(db.features.autoAccept, false)
            h.eq(db.features.cinematics, "all")
            h.eq(db.features.autoRepair, true)
        end)
        h.it("junk values reset to defaults; unknown and camera keys are dropped", function()
            local db = Options.Init({ features = { autoAccept = "yes", cinematics = "sometimes",
                cameraDistance = 3, autoDance = true } })
            h.eq(db.features.autoAccept, true)
            h.eq(db.features.cinematics, "repeats")
            h.eq(db.features.cameraDistance, nil)
            h.eq(db.features.autoDance, nil)
            h.eq(Options.Init({ features = "junk" }).features.autoRepair, true)
        end)
        h.it("a junk SavedVariable starts fresh", function()
            h.eq(Options.Init("junk").features.declineDuels, false)
        end)
        h.it("keeps what was seen; junk seen lists start empty", function()
            local db = Options.Init({ seen = { movies = { [5] = true } } })
            h.eq(db.seen.movies[5], true)
            h.eq(next(db.seen.cinematics), nil)
            h.eq(next(Options.Init({ seen = "junk" }).seen.movies), nil)
        end)
        h.it("the minimap button shows unless hidden on purpose; a junk angle resets", function()
            h.eq(Options.Init({ minimap = { hide = true } }).minimap.hide, true)
            h.eq(Options.Init({ minimap = { hide = "yes" } }).minimap.hide, false)
            h.eq(Options.Init({ minimap = { angle = "left" } }).minimap.angle, 195)
            h.eq(Options.Init({ minimap = { angle = 90 } }).minimap.angle, 90)
        end)
        h.it("keeps a whole window position and drops a broken one", function()
            local window = { point = "TOPLEFT", relativePoint = "BOTTOMLEFT", x = 10, y = 500 }
            h.eq(Options.Init({ window = window }).window, window)
            h.eq(Options.Init({ window = { point = "TOPLEFT", x = 10 } }).window, nil)
        end)
    end)
end
```

In `test/run.lua` add `{ "Options", "GoblinThings/Options.lua" },` after the Look entry, and `"test/test_options.lua",` to the suites.

- [ ] **Step 2: Run to verify it fails**

Expected: `cannot open GoblinThings/Options.lua`.

- [ ] **Step 3: Write Options.lua**

```lua
local _, ns = ...

-- The settings (spec 2026-10-13-goblin-things-design.md): the SavedVariable's
-- shape, and a stub page in Blizzard's options (Esc > Options > AddOns >
-- Goblin Things) that opens our own window. Init is pure; Register uses
-- Blizzard's Settings UI only when called, so test/run.lua loads this file.
local Options = {}
ns.Options = Options

Options.NAME = "Goblin Things"
Options.DEFAULT_ANGLE = 195  -- degrees round the minimap: clear of Goblin Flyout's 225

local function list(t)
    return type(t) == "table" and t or {}
end

-- The SavedVariable with every field valid (see the spec's SavedVariable).
-- Keeps the given table, so writes to it are saved.
function Options.Init(db)
    if type(db) ~= "table" then
        db = {}
    end
    local saved = list(db.features)
    local features = {}
    for _, feature in ipairs(ns.Features.LIST) do
        if feature.default ~= nil then
            local value = saved[feature.key]
            if ns.Features.Valid(feature, value) then
                features[feature.key] = value
            else
                features[feature.key] = feature.default
            end
        end
    end
    db.features = features
    local seen = list(db.seen)
    db.seen = { movies = list(seen.movies), cinematics = list(seen.cinematics) }
    local minimap = list(db.minimap)
    db.minimap = {
        angle = type(minimap.angle) == "number" and minimap.angle or Options.DEFAULT_ANGLE,
        hide = minimap.hide == true,  -- shown unless hidden on purpose
    }
    local window = db.window
    if not (type(window) == "table" and type(window.point) == "string" and type(window.relativePoint) == "string"
        and type(window.x) == "number" and type(window.y) == "number") then
        db.window = nil
    end
    return db
end

local category

-- Adds the page; false when this client's Settings UI lacks a piece.
-- openWindow() shows Goblin Things' own window.
function Options.Register(openWindow)
    if category then
        return true
    end
    if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then
        return false
    end
    local panel = CreateFrame("Frame")
    local open = ns.Look.Button(panel, "Open " .. Options.NAME, 200, 28, function()
        if SettingsPanel and HideUIPanel then
            HideUIPanel(SettingsPanel)
        end
        openWindow()
    end, "gold")
    open:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)
    category = Settings.RegisterCanvasLayoutCategory(panel, Options.NAME)
    Settings.RegisterAddOnCategory(category)
    return true
end

return Options
```

- [ ] **Step 4: Run tests and lint**

Expected: `27 passed, 0 failed`; luacheck clean.

- [ ] **Step 5: Commit**

```bash
git add GoblinThings/Options.lua test/test_options.lua test/run.lua
git commit -m "Options: the SavedVariable's shape and the options-page stub

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Hands (quests)

**Files:**
- Create: `GoblinThings/Hands.lua` (GoblinQuest's, without the route filter and the recorder; dungeon skipping always on)
- Test: `test/test_hands.lua`; modify `test/run.lua`

**Interfaces:**
- Produces: `ns.Hands.NewVisit() -> { held = false, tried = {} }`; `Hands.Decide(view, prefs, visit) -> { op, arg?, key } | nil` where `prefs = { autoAccept, autoTurnIn }` and `op` is one of `selectActive`, `selectAvailable`, `accept`, `acknowledge`, `complete`, `reward`. The caller marks `visit.tried[action.key] = true` and sets `visit.held = true` for Shift.
- View shapes (built by `API.NpcView` in Task 11): gossip/greeting `{ kind, active = { { arg, questID, complete } }, available = { { arg, questID, trivial, repeatable, ignored, tag, title } } }`; detail `{ kind, questID, pvp, auto, group, tag, title }`; progress `{ kind, questID, completable, money }`; complete `{ kind, questID, choices, money }`.

- [ ] **Step 1: Write the failing test**

`test/test_hands.lua`:

```lua
return function(h, loaded)
    local Hands = loaded.ns.Hands
    local ON = { autoAccept = true, autoTurnIn = true }

    local function decide(view, prefs, visit)
        return Hands.Decide(view, prefs or ON, visit or Hands.NewVisit())
    end

    h.describe("Hands at a gossip or greeting window", function()
        h.it("turns in a finished quest first", function()
            local a = decide({ kind = "gossip",
                active = { { arg = 11, complete = false }, { arg = 12, complete = true } },
                available = { { arg = 20, trivial = false } } })
            h.eq(a.op, "selectActive")
            h.eq(a.arg, 12)
        end)
        h.it("picks up when nothing is ready to hand in", function()
            local a = decide({ kind = "gossip", active = { { arg = 11, complete = false } },
                available = { { arg = 21, trivial = true }, { arg = 22, trivial = false } } })
            h.eq(a.op, "selectAvailable")
            h.eq(a.arg, 22)
        end)
        h.it("never picks up a gray quest", function()
            h.eq(decide({ kind = "gossip", active = {}, available = { { arg = 21, trivial = true } } }), nil)
        end)
        h.it("never picks up a repeatable quest", function()
            h.eq(decide({ kind = "gossip", active = {},
                available = { { arg = 21, trivial = false, repeatable = true } } }), nil)
        end)
        h.it("never picks up an ignored quest", function()
            h.eq(decide({ kind = "gossip", active = {},
                available = { { arg = 21, trivial = false, ignored = true } } }), nil)
        end)
        h.it("picks up a non-repeatable quest next to a repeatable one", function()
            local a = decide({ kind = "gossip", active = {},
                available = { { arg = 21, trivial = false, repeatable = true }, { arg = 22, trivial = false } } })
            h.eq(a.op, "selectAvailable")
            h.eq(a.arg, 22)
        end)
        h.it("still turns in a finished repeatable quest already held", function()
            local a = decide({ kind = "gossip",
                active = { { arg = 12, complete = true } },
                available = { { arg = 21, trivial = false, repeatable = true } } })
            h.eq(a.op, "selectActive")
            h.eq(a.arg, 12)
        end)
        h.it("does nothing at an NPC with no quests", function()
            h.eq(decide({ kind = "gossip", active = {}, available = {} }), nil)
        end)
        h.it("with turn-in off, still picks up", function()
            local a = decide({ kind = "gossip", active = { { arg = 12, complete = true } },
                available = { { arg = 22, trivial = false } } }, { autoAccept = true, autoTurnIn = false })
            h.eq(a.op, "selectAvailable")
        end)
        h.it("with pick-up off, still turns in and picks up nothing", function()
            local off = { autoAccept = false, autoTurnIn = true }
            h.eq(decide({ kind = "gossip", active = {}, available = { { arg = 22, trivial = false } } }, off), nil)
            h.eq(decide({ kind = "gossip", active = { { arg = 12, complete = true } }, available = {} }, off).op,
                "selectActive")
        end)
        h.it("works the same at a greeting window, by index", function()
            local a = decide({ kind = "greeting", active = { { arg = 2, complete = true } }, available = {} })
            h.eq(a.op, "selectActive")
            h.eq(a.arg, 2)
        end)
        h.it("never picks up a dungeon-tagged quest at gossip", function()
            h.eq(decide({ kind = "gossip", active = {},
                available = { { arg = 21, trivial = false, tag = 81 } } }), nil)
        end)
        h.it("never picks up a raid-tagged quest at greeting", function()
            h.eq(decide({ kind = "greeting", active = {},
                available = { { arg = 21, trivial = false, tag = 62 } } }), nil)
        end)
        h.it("picks up a normal quest next to a dungeon one", function()
            local a = decide({ kind = "gossip", active = {},
                available = { { arg = 21, trivial = false, tag = 81 }, { arg = 22, trivial = false } } })
            h.eq(a.op, "selectAvailable")
            h.eq(a.arg, 22)
        end)
        h.it("a tag of 0 is not a signal: picked up", function()
            local a = decide({ kind = "gossip", active = {},
                available = { { arg = 21, trivial = false, tag = 0 } } })
            h.eq(a.op, "selectAvailable")
            h.eq(a.arg, 21)
        end)
    end)

    h.describe("Hands at the quest offer", function()
        h.it("accepts", function()
            h.eq(decide({ kind = "detail", questID = 5 }).op, "accept")
        end)
        h.it("acknowledges an auto-accept quest, as Blizzard's button does", function()
            h.eq(decide({ kind = "detail", auto = true, questID = 5 }).op, "acknowledge")
        end)
        h.it("leaves a PvP quest to the player", function()
            h.eq(decide({ kind = "detail", pvp = true, questID = 5 }), nil)
        end)
        h.it("does nothing with pick-up off", function()
            h.eq(decide({ kind = "detail", questID = 5 }, { autoAccept = false, autoTurnIn = true }), nil)
        end)
        h.it("does not accept a dungeon- or raid-tagged quest", function()
            h.eq(decide({ kind = "detail", questID = 5, tag = 81 }), nil)
            h.eq(decide({ kind = "detail", questID = 5, tag = 62 }), nil)
        end)
        h.it("does not accept a quest suggesting a full group", function()
            h.eq(decide({ kind = "detail", questID = 5, group = 5 }), nil)
        end)
        h.it("accepts a quest suggesting a group of 4 or fewer", function()
            h.eq(decide({ kind = "detail", questID = 5, group = 3 }).op, "accept")
            h.eq(decide({ kind = "detail", questID = 5, group = 4 }).op, "accept")
        end)
        h.it("a nil tag and group are not a positive signal", function()
            h.eq(decide({ kind = "detail", questID = 5, tag = nil, group = nil }).op, "accept")
        end)
    end)

    h.describe("Hands at the hand-in check", function()
        h.it("continues when the quest can be completed", function()
            h.eq(decide({ kind = "progress", completable = true, money = 0, questID = 5 }).op, "complete")
        end)
        h.it("waits when it cannot", function()
            h.eq(decide({ kind = "progress", completable = false, money = 0 }), nil)
        end)
        h.it("waits when it costs gold", function()
            h.eq(decide({ kind = "progress", completable = true, money = 500 }), nil)
        end)
        h.it("waits when the gold cost is unknown", function()
            h.eq(decide({ kind = "progress", completable = true }), nil)
        end)
        h.it("does nothing with turn-in off", function()
            h.eq(decide({ kind = "progress", completable = true, money = 0 },
                { autoAccept = true, autoTurnIn = false }), nil)
        end)
    end)

    h.describe("Hands at the rewards", function()
        h.it("takes the reward with no choice as choice 0", function()
            local a = decide({ kind = "complete", choices = 0, money = 0, questID = 5 })
            h.eq(a.op, "reward")
            h.eq(a.arg, 0)
        end)
        h.it("takes the only choice as choice 1", function()
            h.eq(decide({ kind = "complete", choices = 1, money = 0, questID = 5 }).arg, 1)
        end)
        h.it("waits for the player on a real choice", function()
            h.eq(decide({ kind = "complete", choices = 2, money = 0 }), nil)
        end)
        h.it("waits when it costs gold", function()
            h.eq(decide({ kind = "complete", choices = 0, money = 100 }), nil)
        end)
        h.it("waits when the choice count is unknown", function()
            h.eq(decide({ kind = "complete", money = 0 }), nil)
        end)
    end)

    h.describe("Hands keep off", function()
        h.it("a held visit stays held", function()
            local visit = Hands.NewVisit()
            visit.held = true
            h.eq(decide({ kind = "detail", questID = 5 }, ON, visit), nil)
        end)
        h.it("tries each action once per visit", function()
            local visit = Hands.NewVisit()
            local view = { kind = "gossip", active = { { arg = 12, complete = true } }, available = {} }
            local a = decide(view, ON, visit)
            visit.tried[a.key] = true
            h.eq(decide(view, ON, visit), nil)
            local other = { kind = "gossip", active = { { arg = 13, complete = true } }, available = {} }
            h.eq(decide(other, ON, visit).arg, 13)
        end)
        h.it("a new visit starts clean", function()
            local visit = Hands.NewVisit()
            h.eq(visit.held, false)
            h.eq(next(visit.tried), nil)
        end)
        h.it("ignores a view it does not understand", function()
            h.eq(decide(nil), nil)
            h.eq(decide({ kind = "mailbox" }), nil)
        end)
    end)
end
```

In `test/run.lua` add `{ "Hands", "GoblinThings/Hands.lua" },` after the Features entry (TOC order: Features, Hands, Vendor, Camera, ...; move the Camera entry below it), and `"test/test_hands.lua",` to the suites. The modules list is now:

```lua
local modules = {
    { "Features", "GoblinThings/Features.lua" },
    { "Hands", "GoblinThings/Hands.lua" },
    { "Camera", "GoblinThings/Camera.lua" },
    { "Look", "GoblinThings/Look.lua" },
    { "Options", "GoblinThings/Options.lua" },
}
```

- [ ] **Step 2: Run to verify it fails**

Expected: `cannot open GoblinThings/Hands.lua`.

- [ ] **Step 3: Write Hands.lua**

```lua
local _, ns = ...

-- What to do at an NPC's quest window: one action or nothing (spec
-- 2026-10-13-goblin-things-design.md, Quests; from GoblinQuest's Hands.lua).
-- Pure: API.lua reads the window into a plain view and carries out the action.
-- The rules copy Blizzard's own buttons (Mainline/QuestFrame.lua in the forever
-- source) and keep off: Shift, grays, repeatables, ignored quests, dungeon,
-- raid and full-group quests, PvP, gold costs, real reward choices, and one try
-- per action per visit. An unknown answer is a reason to wait, never to act.
--
-- prefs = { autoAccept, autoTurnIn } (the SavedVariable's features table)
local Hands = {}
ns.Hands = Hands

-- Enum.QuestTag Dungeon and Raid (QuestLogDocumentation.lua ~1509-1510):
-- an offered quest tagged with either is left for the player to take by hand.
Hands.DUNGEON_TAGS = { [81] = true, [62] = true }
Hands.GROUP_SIZE = 5

function Hands.NewVisit()
    return { held = false, tried = {} }
end

-- Only a positive signal skips: a nil or zero tag, or a group below
-- Hands.GROUP_SIZE, is an ordinary quest.
local function isDungeon(tag)
    return tag ~= nil and tag ~= 0 and Hands.DUNGEON_TAGS[tag] == true
end

local function isFullGroup(group)
    return type(group) == "number" and group >= Hands.GROUP_SIZE
end

local function atQuestList(view, prefs)
    if prefs.autoTurnIn then
        for _, q in ipairs(view.active or {}) do
            if q.complete then
                return { op = "selectActive", arg = q.arg }
            end
        end
    end
    if prefs.autoAccept then
        for _, q in ipairs(view.available or {}) do
            if not (q.trivial or q.repeatable or q.ignored or isDungeon(q.tag)) then
                return { op = "selectAvailable", arg = q.arg }
            end
        end
    end
    return nil
end

local function choose(view, prefs)
    local kind = view.kind
    if kind == "gossip" or kind == "greeting" then
        return atQuestList(view, prefs)
    elseif kind == "detail" then
        if prefs.autoAccept and not view.pvp and not isDungeon(view.tag) and not isFullGroup(view.group) then
            return { op = view.auto and "acknowledge" or "accept" }
        end
    elseif kind == "progress" then
        if prefs.autoTurnIn and view.completable and view.money == 0 then
            return { op = "complete" }
        end
    elseif kind == "complete" then
        if prefs.autoTurnIn and view.money == 0 and type(view.choices) == "number" and view.choices <= 1 then
            return { op = "reward", arg = (view.choices == 1) and 1 or 0 }
        end
    end
    return nil
end

function Hands.Decide(view, prefs, visit)
    if type(view) ~= "table" or visit.held then
        return nil
    end
    local action = choose(view, prefs)
    if not action then
        return nil
    end
    action.key = view.kind .. ":" .. action.op .. ":" .. tostring(action.arg or view.questID or "")
    if visit.tried[action.key] then
        return nil
    end
    return action
end

return Hands
```

- [ ] **Step 4: Run tests and lint**

Expected: `64 passed, 0 failed`; luacheck clean.

- [ ] **Step 5: Commit**

```bash
git add GoblinThings/Hands.lua test/test_hands.lua test/run.lua
git commit -m "Hands: auto accept and turn-in rules from GoblinQuest, dungeon quests always left alone

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Vendor

**Files:**
- Create: `GoblinThings/Vendor.lua` (GoblinQuest's, header comment updated)
- Test: `test/test_vendor.lua` (GoblinQuest's, unchanged); modify `test/run.lua`

**Interfaces:**
- Produces: `ns.Vendor.Money(copper) -> "1g 2s 5c"`, `Vendor.Plan(view, prefs) -> { sell = { { bag, slot } }, repair = boolean, line = string|nil }` with `view = { shift, slots = { { bag, slot, quality, hasNoValue, locked, count, price } }, canRepair, repairCost, money }` and `prefs = { autoSellJunk, autoRepair }`.

- [ ] **Step 1: Copy the failing test**

```bash
cp /d/goblinquest/test/test_vendor.lua test/
```

In `test/run.lua` add `{ "Vendor", "GoblinThings/Vendor.lua" },` after Hands, and `"test/test_vendor.lua",` to the suites.

- [ ] **Step 2: Run to verify it fails**

Expected: `cannot open GoblinThings/Vendor.lua`.

- [ ] **Step 3: Write Vendor.lua**

```lua
local _, ns = ...

-- What to do at a vendor window (spec 2026-10-13-goblin-things-design.md,
-- Vendors; from GoblinQuest's Vendor.lua): sell the gray items and repair.
-- Pure: API.lua reads the bags and the vendor into a plain view and carries
-- out the plan; Core says the line.
--
-- view = { shift, slots = { { bag, slot, quality, hasNoValue, locked, count,
--   price } ... }, canRepair, repairCost, money }   (price per item, nil when
--   unknown; quality nil when the game gave no answer)
-- prefs = { autoSellJunk, autoRepair }
local Vendor = {}
ns.Vendor = Vendor

Vendor.POOR = 0 -- Enum.ItemQuality.Poor (gray)

-- "1g 2s 5c", zero parts left out; "0c" for nothing.
function Vendor.Money(copper)
    copper = math.max(0, math.floor(tonumber(copper) or 0))
    local g, s, c = math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100
    local parts = {}
    if g > 0 then parts[#parts + 1] = g .. "g" end
    if s > 0 then parts[#parts + 1] = s .. "s" end
    if c > 0 or #parts == 0 then parts[#parts + 1] = c .. "c" end
    return table.concat(parts, " ")
end

local function junk(s)
    return s.quality == Vendor.POOR and s.hasNoValue == false and s.locked == false
end

function Vendor.Plan(view, prefs)
    local plan = { sell = {}, repair = false }
    if view.shift then
        return plan
    end
    local said = {}
    if prefs.autoSellJunk then
        local value, known = 0, true
        for _, s in ipairs(view.slots or {}) do
            if junk(s) then
                plan.sell[#plan.sell + 1] = { bag = s.bag, slot = s.slot }
                if type(s.price) == "number" then
                    value = value + s.price * (s.count or 1)
                else
                    known = false
                end
            end
        end
        if #plan.sell > 0 then
            said[#said + 1] = known and ("Sold %d junk for %s."):format(#plan.sell, Vendor.Money(value))
                or ("Sold %d junk."):format(#plan.sell)
        end
    end
    local cost, money = view.repairCost, view.money
    if prefs.autoRepair and view.canRepair and type(cost) == "number" and cost > 0 and type(money) == "number" then
        if money >= cost then
            plan.repair = true
            said[#said + 1] = ("Repaired for %s."):format(Vendor.Money(cost))
        else
            said[#said + 1] = ("Not enough gold to repair (costs %s)."):format(Vendor.Money(cost))
        end
    end
    plan.line = #said > 0 and table.concat(said, " ") or nil
    return plan
end

return Vendor
```

- [ ] **Step 4: Run tests and lint**

Expected: `73 passed, 0 failed`; luacheck clean (the copied suite passes luacheck in GoblinQuest's identical config; if it reports a warning, fix it in the suite here).

- [ ] **Step 5: Commit**

```bash
git add GoblinThings/Vendor.lua test/test_vendor.lua test/run.lua
git commit -m "Vendor: sell junk and repair rules from GoblinQuest

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: Cinematics

**Files:**
- Create: `GoblinThings/Cinematics.lua`
- Test: `test/test_cinematics.lua`; modify `test/run.lua`

**Interfaces:**
- Produces: `ns.Cinematics.LISTS = { movie = "movies", cinematic = "cinematics" }`, `Cinematics.Key(race, map) -> "Race:map" | nil`, `Cinematics.Decide(mode, seen, kind, key, canCancel) -> "stop" | "mark" | nil`, `Cinematics.Mark(seen, kind, key)`.
- Movies call `Decide(mode, seen, "movie", movieID, true)`; in-engine cinematics call `Decide(mode, seen, "cinematic", Key(race, map), canBeCancelled)`.
- Key choice: race plus map. Each race's intro plays once in its starting zone; `GetCurrentCinematicSummary()` is recorded for the probe (open fact 1) and may replace this key later.

- [ ] **Step 1: Write the failing test**

`test/test_cinematics.lua`:

```lua
return function(h, loaded)
    local Cinematics = loaded.ns.Cinematics

    local function seen()
        return { movies = {}, cinematics = {} }
    end

    h.describe("Cinematics.Key", function()
        h.it("is the race and the map", function()
            h.eq(Cinematics.Key("Scourge", 1420), "Scourge:1420")
        end)
        h.it("no race or no map is no key", function()
            h.eq(Cinematics.Key(nil, 1420), nil)
            h.eq(Cinematics.Key("", 1420), nil)
            h.eq(Cinematics.Key("Scourge", nil), nil)
        end)
    end)

    h.describe("Cinematics.Decide", function()
        h.it("off does nothing", function()
            h.eq(Cinematics.Decide("off", seen(), "movie", 5, true), nil)
            h.eq(Cinematics.Decide("off", seen(), "cinematic", "Scourge:1420", true), nil)
        end)
        h.it("all stops every movie and real cinematic, seen or not", function()
            h.eq(Cinematics.Decide("all", seen(), "movie", 5, true), "stop")
            h.eq(Cinematics.Decide("all", seen(), "cinematic", "Scourge:1420", true), "stop")
            h.eq(Cinematics.Decide("all", seen(), "cinematic", nil, true), "stop")
        end)
        h.it("never touches one that cannot be cancelled: that is a vehicle ride", function()
            h.eq(Cinematics.Decide("all", seen(), "cinematic", "Scourge:1420", false), nil)
            h.eq(Cinematics.Decide("repeats", seen(), "cinematic", "Scourge:1420", false), nil)
            h.eq(Cinematics.Decide("all", seen(), "cinematic", "Scourge:1420", nil), nil)
        end)
        h.it("repeats plays and marks the first viewing, then stops it", function()
            local s = seen()
            h.eq(Cinematics.Decide("repeats", s, "movie", 5, true), "mark")
            Cinematics.Mark(s, "movie", 5)
            h.eq(Cinematics.Decide("repeats", s, "movie", 5, true), "stop")
        end)
        h.it("repeats with no key does nothing: it cannot know the cinematic was seen", function()
            h.eq(Cinematics.Decide("repeats", seen(), "cinematic", nil, true), nil)
        end)
        h.it("movies and cinematics keep separate lists", function()
            local s = seen()
            Cinematics.Mark(s, "movie", "Scourge:1420")
            h.eq(Cinematics.Decide("repeats", s, "cinematic", "Scourge:1420", true), "mark")
        end)
        h.it("an unknown mode, kind or seen table does nothing", function()
            h.eq(Cinematics.Decide("sometimes", seen(), "movie", 5, true), nil)
            h.eq(Cinematics.Decide("all", seen(), "trailer", 5, true), nil)
            h.eq(Cinematics.Decide("repeats", nil, "movie", 5, true), nil)
            h.eq(Cinematics.Decide("repeats", { movies = "junk" }, "movie", 5, true), nil)
        end)
    end)
end
```

In `test/run.lua` add `{ "Cinematics", "GoblinThings/Cinematics.lua" },` after Camera, and `"test/test_cinematics.lua",` to the suites.

- [ ] **Step 2: Run to verify it fails**

Expected: `cannot open GoblinThings/Cinematics.lua`.

- [ ] **Step 3: Write Cinematics.lua**

```lua
local _, ns = ...

-- Skipping cinematics (spec 2026-10-13-goblin-things-design.md, Cinematics).
-- Mode "off" does nothing, "all" stops every movie and real cinematic,
-- "repeats" plays one the first time and stops it after. A cinematic that
-- cannot be cancelled is a vehicle ride (CinematicFrame.lua: isRealCinematic
-- = canBeCancelled) and is never touched. Movies carry an ID; in-engine
-- cinematics carry none, so they are known by race and map. Pure.
local Cinematics = {}
ns.Cinematics = Cinematics

Cinematics.LISTS = { movie = "movies", cinematic = "cinematics" }

function Cinematics.Key(race, map)
    if type(race) == "string" and race ~= "" and type(map) == "number" then
        return race .. ":" .. map
    end
    return nil
end

-- "stop", "mark" (play it, then remember it) or nil.
function Cinematics.Decide(mode, seen, kind, key, canCancel)
    local list = Cinematics.LISTS[kind]
    if not list or canCancel ~= true then
        return nil
    end
    if mode == "all" then
        return "stop"
    end
    if mode ~= "repeats" or key == nil or type(seen) ~= "table" or type(seen[list]) ~= "table" then
        return nil
    end
    return seen[list][key] and "stop" or "mark"
end

function Cinematics.Mark(seen, kind, key)
    seen[Cinematics.LISTS[kind]][key] = true
end

return Cinematics
```

- [ ] **Step 4: Run tests and lint**

Expected: `82 passed, 0 failed`; luacheck clean.

- [ ] **Step 5: Commit**

```bash
git add GoblinThings/Cinematics.lua test/test_cinematics.lua test/run.lua
git commit -m "Cinematics: off, repeats only or all, never touching a vehicle ride

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8: Decline

**Files:**
- Create: `GoblinThings/Decline.lua`
- Test: `test/test_decline.lua`; modify `test/run.lua`

**Interfaces:**
- Produces: `ns.Decline.Who(name) -> name | "someone"`, `Decline.Duel(on, name) -> line | nil`, `Decline.Guild(on, inviter, guild) -> line | nil`. A line means "decline and say this"; nil means leave the popup to the player.

- [ ] **Step 1: Write the failing test**

`test/test_decline.lua`:

```lua
return function(h, loaded)
    local Decline = loaded.ns.Decline

    h.describe("Decline.Duel", function()
        h.it("declines and names the challenger when on", function()
            h.eq(Decline.Duel(true, "Bob"), "Declined a duel from Bob.")
        end)
        h.it("leaves it to the player when off or unset", function()
            h.eq(Decline.Duel(false, "Bob"), nil)
            h.eq(Decline.Duel(nil, "Bob"), nil)
        end)
        h.it("no name still makes a sensible line", function()
            h.eq(Decline.Duel(true, nil), "Declined a duel from someone.")
            h.eq(Decline.Duel(true, ""), "Declined a duel from someone.")
        end)
    end)

    h.describe("Decline.Guild", function()
        h.it("declines and names the inviter and the guild when on", function()
            h.eq(Decline.Guild(true, "Bob", "Goblin Union"), "Declined a guild invite from Bob (Goblin Union).")
        end)
        h.it("leaves the guild out when the game gives none", function()
            h.eq(Decline.Guild(true, "Bob", ""), "Declined a guild invite from Bob.")
            h.eq(Decline.Guild(true, "Bob", nil), "Declined a guild invite from Bob.")
        end)
        h.it("no inviter still makes a sensible line", function()
            h.eq(Decline.Guild(true, nil, "Goblin Union"), "Declined a guild invite from someone (Goblin Union).")
        end)
        h.it("leaves it to the player when off", function()
            h.eq(Decline.Guild(false, "Bob", "Goblin Union"), nil)
        end)
    end)
end
```

In `test/run.lua` add `{ "Decline", "GoblinThings/Decline.lua" },` after Cinematics, and `"test/test_decline.lua",` to the suites.

- [ ] **Step 2: Run to verify it fails**

Expected: `cannot open GoblinThings/Decline.lua`.

- [ ] **Step 3: Write Decline.lua**

```lua
local _, ns = ...

-- Refusing duels and guild invites (spec 2026-10-13-goblin-things-design.md,
-- Social). Each answer is the chat line to say after declining, or nil to
-- leave Blizzard's popup to the player. Pure: Core calls API.CancelDuel or
-- API.DeclineGuild when a line comes back.
local Decline = {}
ns.Decline = Decline

function Decline.Who(name)
    return (type(name) == "string" and name ~= "") and name or "someone"
end

function Decline.Duel(on, name)
    if on ~= true then
        return nil
    end
    return ("Declined a duel from %s."):format(Decline.Who(name))
end

function Decline.Guild(on, inviter, guild)
    if on ~= true then
        return nil
    end
    if type(guild) == "string" and guild ~= "" then
        return ("Declined a guild invite from %s (%s)."):format(Decline.Who(inviter), guild)
    end
    return ("Declined a guild invite from %s."):format(Decline.Who(inviter))
end

return Decline
```

- [ ] **Step 4: Run tests and lint**

Expected: `89 passed, 0 failed`; luacheck clean.

- [ ] **Step 5: Commit**

```bash
git add GoblinThings/Decline.lua test/test_decline.lua test/run.lua
git commit -m "Decline: the lines for refusing duels and guild invites

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 9: Minimap button

**Files:**
- Create: `GoblinThings/MinimapButton.lua` (Goblin Flyout's, renamed)
- Test: `test/test_minimap.lua` (Goblin Flyout's, unchanged); modify `test/run.lua`

**Interfaces:**
- Consumes: `core.ToggleWindow()`, `core.Angle()`, `core.SetAngle(angle)`, `core.MinimapShown()` (Task 12), `ns.API.CursorPosition()` (Task 11), `ns.Options.NAME`.
- Produces: `ns.MinimapButton.Position(angle, radius) -> x, y`, `MinimapButton.Angle(dx, dy) -> 0..360`, `MinimapButton.Create(core)`, `MinimapButton.SetShown(shown)`.

- [ ] **Step 1: Copy the failing test**

```bash
cp /d/GoblinFlyout/test/test_minimap.lua test/
```

In `test/run.lua` add `{ "MinimapButton", "GoblinThings/MinimapButton.lua" },` after Options, and `"test/test_minimap.lua",` to the suites.

- [ ] **Step 2: Run to verify it fails**

Expected: `cannot open GoblinThings/MinimapButton.lua`.

- [ ] **Step 3: Copy and rename the module**

```bash
sed -e 's/2026-10-12-goblin-flyout-design.md/2026-10-13-goblin-things-design.md/' \
    -e 's/GoblinFlyout/GoblinThings/g' \
    -e 's/GF on oxblood/GT on teal/' \
    /d/GoblinFlyout/GoblinFlyout/MinimapButton.lua > GoblinThings/MinimapButton.lua
grep -n "Flyout\|GF" GoblinThings/MinimapButton.lua
```

Expected from the `grep`: no output. If a line remains, edit it by hand so the file names Goblin Things, `GoblinThingsMinimapButton`, `Interface\\AddOns\\GoblinThings\\Media\\icon` and "GT on teal".

- [ ] **Step 4: Run tests and lint**

Expected: `92 passed, 0 failed`; luacheck clean.

- [ ] **Step 5: Commit**

```bash
git add GoblinThings/MinimapButton.lua test/test_minimap.lua test/run.lua
git commit -m "Minimap: Goblin Flyout's draggable button, as Goblin Things

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 10: Window

**Files:**
- Create: `GoblinThings/Window.lua`
- Test: `test/test_window.lua`; modify `test/run.lua`

**Interfaces:**
- Consumes: `ns.Features.Sections()`, `ns.Look.*` (including `Look.Slider`), `ns.Camera.Text`, `ns.Options.NAME`; from Core (Task 12): `core.Get(key)`, `core.Set(key, value)`, `core.MinimapShown()`, `core.SetMinimapShown(shown)`, `core.Window()`, `core.SaveWindow(point, relativePoint, x, y)`.
- Produces: `ns.Window.WellHeight(sections) -> number` (pure), `Window.Toggle(core)`, `Window.Refresh(core)` (a no-op before the window is made).

- [ ] **Step 1: Write the failing test**

`test/test_window.lua`:

```lua
return function(h, loaded)
    local Window = loaded.ns.Window
    local L = Window.LAYOUT

    h.describe("Window.WellHeight", function()
        h.it("is the padding plus a header per section and a row per feature", function()
            local sections = { { name = "A", features = { 1, 2 } }, { name = "B", features = { 3 } } }
            h.eq(Window.WellHeight(sections), 2 * L.WELL_PAD + 2 * L.SECTION + 3 * L.ROW)
        end)
        h.it("fits the eight switches under five headers", function()
            h.eq(Window.WellHeight(loaded.ns.Features.Sections()), 2 * L.WELL_PAD + 5 * L.SECTION + 8 * L.ROW)
        end)
    end)
end
```

In `test/run.lua` add `{ "Window", "GoblinThings/Window.lua" },` after Options (before MinimapButton), and `"test/test_window.lua",` to the suites. Update the comment above `modules` to say only `API.lua and Core.lua` are left out.

- [ ] **Step 2: Run to verify it fails**

Expected: `cannot open GoblinThings/Window.lua`.

- [ ] **Step 3: Write Window.lua**

```lua
local _, ns = ...

-- The settings window (spec 2026-10-13-goblin-things-design.md, Window) in the
-- Goblin look (Look.lua): a dark window with a gold top edge, a header to drag
-- it by, and one inset well holding every row of Features.LIST under gold
-- section headers. Each row reads and writes through core.Get / core.Set.
-- Plain frames, no Blizzard templates. WellHeight is pure; the rest makes
-- frames only when called, so test/run.lua loads this file.
local Window = {}
ns.Window = Window

Window.NAME = "GoblinThingsWindow"  -- UISpecialFrames closes frames by name on Escape
Window.WIDTH = 420
Window.HOME = { "CENTER", "CENTER", 0, 40 }  -- where it opens until dragged
Window.LAYOUT = {
    TOP_EDGE = 2, HEADER = 56, PAD = 16, CLOSE = 28, WELL_PAD = 4, SECTION = 28, ROW = 36, INDENT = 26,
    CHECK = 18, SLIDER_W = 160, SLIDER_H = 16, VALUE_W = 34, CHOICE_H = 24, CHOICE_PAD = 20, FOOT = 62,
}
local L = Window.LAYOUT

function Window.WellHeight(sections)
    local height = 2 * L.WELL_PAD
    for _, section in ipairs(sections) do
        height = height + L.SECTION + #section.features * L.ROW
    end
    return height
end

local frame
local controls = {}  -- feature key -> { feature, check } | { feature, slider, value } | { feature, buttons }
local minimapCheck
local refreshing = false  -- a slider moved by Refresh is not the player moving it

local function buildHeader(core)
    local Look = ns.Look
    local head = CreateFrame("Frame", nil, frame)
    head:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -L.TOP_EDGE)
    head:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -L.TOP_EDGE)
    head:SetHeight(L.HEADER)
    head:EnableMouse(true)
    head:RegisterForDrag("LeftButton")
    head:SetScript("OnDragStart", function() frame:StartMoving() end)
    head:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        -- Re-anchor TOPLEFT by where the window sits, and keep both points.
        local x, y = frame:GetLeft(), frame:GetTop()
        if x and y then
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
            core.SaveWindow("TOPLEFT", "BOTTOMLEFT", x, y)
        end
    end)
    local rule = Look.Texture(head, "BORDER", Look.COLOUR.divider)
    rule:SetHeight(1)
    rule:SetPoint("BOTTOMLEFT", head, "BOTTOMLEFT")
    rule:SetPoint("BOTTOMRIGHT", head, "BOTTOMRIGHT")

    local close = Look.IconButton(head, "close", L.CLOSE, function() frame:Hide() end, "X")
    close:SetPoint("RIGHT", head, "RIGHT", -12, 0)
    local name = Look.Text(head, Look.WORDS, 17, "gold")
    name:SetPoint("TOPLEFT", head, "TOPLEFT", L.PAD, -12)
    name:SetPoint("RIGHT", close, "LEFT", -12, 0)
    name:SetText(ns.Options.NAME)
    local tagline = Look.Text(head, Look.WORDS, 10, "dim")
    tagline:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4)
    tagline:SetPoint("RIGHT", close, "LEFT", -12, 0)
    tagline:SetText("Time is money, friend.")
end

local function checkControl(core, r, feature)
    local check = ns.Look.Check(r, L.CHECK, function()
        core.Set(feature.key, not core.Get(feature.key))
    end)
    check:SetPoint("RIGHT", r, "RIGHT", -10, 0)
    return { check = check }
end

local function sliderControl(core, r, feature)
    local Look = ns.Look
    local value = Look.Text(r, Look.WORDS, 12, "text")
    value:SetWidth(L.VALUE_W)
    value:SetJustifyH("RIGHT")
    value:SetPoint("RIGHT", r, "RIGHT", -10, 0)
    local slider = Look.Slider(r, L.SLIDER_W, L.SLIDER_H, feature.min, feature.max, feature.step, function(v)
        if not refreshing then
            core.Set(feature.key, v)
        end
    end)
    slider:SetPoint("RIGHT", value, "LEFT", -10, 0)
    return { slider = slider, value = value }
end

-- One button per choice, right to left, their borders overlapping into one
-- switch, each as wide as its words.
local function choiceControl(core, r, feature)
    local Look = ns.Look
    local buttons, right = {}, nil
    for i = #feature.choices, 1, -1 do
        local choice = feature.choices[i]
        local b = Look.Button(r, feature.labels[choice], 10, L.CHOICE_H, function()
            core.Set(feature.key, choice)
        end)
        b:SetWidth(math.ceil(b.label:GetStringWidth()) + L.CHOICE_PAD)
        if right then
            b:SetPoint("RIGHT", right, "LEFT", 1, 0)
        else
            b:SetPoint("RIGHT", r, "RIGHT", -10, 0)
        end
        buttons[choice] = b
        right = b
    end
    return { buttons = buttons }
end

local MAKERS = { check = checkControl, slider = sliderControl, choice = choiceControl }

local function row(core, well, feature, y)
    local r = CreateFrame("Frame", nil, well)
    r:SetHeight(L.ROW)
    r:SetPoint("TOPLEFT", well, "TOPLEFT", L.WELL_PAD, y)
    r:SetPoint("TOPRIGHT", well, "TOPRIGHT", -L.WELL_PAD, y)
    local control = MAKERS[feature.control](core, r, feature)
    control.feature = feature
    controls[feature.key] = control
    local name = ns.Look.Text(r, ns.Look.WORDS, 13, "text")
    name:SetPoint("LEFT", r, "LEFT", L.INDENT, 0)
    name:SetText(feature.label)
end

local function sectionHeader(well, name, y, first)
    local Look = ns.Look
    if not first then
        local rule = Look.Texture(well, "BORDER", Look.COLOUR.divider)
        rule:SetHeight(1)
        rule:SetPoint("TOPLEFT", well, "TOPLEFT", L.WELL_PAD + 10, y)
        rule:SetPoint("TOPRIGHT", well, "TOPRIGHT", -(L.WELL_PAD + 10), y)
    end
    local text = Look.Text(well, Look.WORDS, 12, "gold")
    text:SetPoint("TOPLEFT", well, "TOPLEFT", L.WELL_PAD + 10, y - 10)
    text:SetText(name)
end

local function make(core)
    local Look = ns.Look
    local sections = ns.Features.Sections()
    local wellHeight = Window.WellHeight(sections)
    frame = CreateFrame("Frame", Window.NAME, UIParent)
    frame:SetSize(Window.WIDTH, L.TOP_EDGE + L.HEADER + L.PAD + wellHeight + L.FOOT)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    Look.Texture(frame, "BACKGROUND", Look.COLOUR.window):SetAllPoints(frame)
    Look.Outline(frame, Look.COLOUR.line)
    local topEdge = Look.Texture(frame, "ARTWORK", Look.COLOUR.gold)
    topEdge:SetPoint("TOPLEFT", frame, "TOPLEFT")
    topEdge:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
    topEdge:SetHeight(L.TOP_EDGE)
    buildHeader(core)

    local well = CreateFrame("Frame", nil, frame)
    well:SetPoint("TOPLEFT", frame, "TOPLEFT", L.PAD, -(L.TOP_EDGE + L.HEADER + L.PAD))
    well:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -L.PAD, -(L.TOP_EDGE + L.HEADER + L.PAD))
    well:SetHeight(wellHeight)
    Look.Texture(well, "BACKGROUND", Look.COLOUR.inset):SetAllPoints(well)
    Look.Outline(well, Look.COLOUR.line)
    local y = -L.WELL_PAD
    for i, section in ipairs(sections) do
        sectionHeader(well, section.name, y, i == 1)
        y = y - L.SECTION
        for _, feature in ipairs(section.features) do
            row(core, well, feature, y)
            y = y - L.ROW
        end
    end

    -- Hiding the minimap button leaves /gt and Esc > Options to open this window.
    minimapCheck = Look.Check(frame, L.CHECK, function()
        core.SetMinimapShown(not core.MinimapShown())
    end)
    minimapCheck:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", L.PAD, 34)
    local checkLabel = Look.Text(frame, Look.WORDS, 12, "text")
    checkLabel:SetPoint("LEFT", minimapCheck, "RIGHT", 10, 0)
    checkLabel:SetPoint("RIGHT", frame, "RIGHT", -L.PAD, 0)
    checkLabel:SetText("Show minimap button")

    local hint = Look.Text(frame, Look.WORDS, 10, "dim")
    hint:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", L.PAD, 11)
    hint:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -L.PAD, 11)
    hint:SetText("Hold Shift at an NPC or vendor to skip.")

    frame:ClearAllPoints()
    local saved = core.Window()
    if saved then
        frame:SetPoint(saved.point, UIParent, saved.relativePoint, saved.x, saved.y)
    else
        frame:SetPoint(Window.HOME[1], UIParent, Window.HOME[2], Window.HOME[3], Window.HOME[4])
    end
    frame:Hide()
    table.insert(UISpecialFrames, Window.NAME)  -- Escape closes it
end

-- Draws every control from core.Get: checks on or off, the slider and its
-- number (the camera CVar, read fresh: "?" when the game gives no answer),
-- the chosen choice gold, and the minimap check.
function Window.Refresh(core)
    if not frame then
        return
    end
    minimapCheck.SetOn(core.MinimapShown())
    for key, c in pairs(controls) do
        local value = core.Get(key)
        if c.check then
            c.check.SetOn(value)
        elseif c.slider then
            refreshing = true
            c.slider:SetValue(value or c.feature.min)
            refreshing = false
            c.value:SetText(value and ns.Camera.Text(value) or "?")
        elseif c.buttons then
            for choice, b in pairs(c.buttons) do
                ns.Look.Style(b, choice == value and "gold" or "quiet")
            end
        end
    end
end

function Window.Toggle(core)
    if not frame then
        make(core)
    end
    if frame:IsShown() then
        frame:Hide()
        return
    end
    Window.Refresh(core)
    frame:Show()
end

return Window
```

- [ ] **Step 4: Run tests and lint**

Expected: `94 passed, 0 failed`; luacheck clean.

- [ ] **Step 5: Commit**

```bash
git add GoblinThings/Window.lua test/test_window.lua test/run.lua
git commit -m "Window: the Goblin-look window, rows built from Features under section headers

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 11: API

**Files:**
- Create: `GoblinThings/API.lua`

No unit test: every function here calls the game. luacheck and lua-language-server are its checks, and Task 12's checklist is its test in game.

**Interfaces:**
- Produces: `API.Errors() -> { name = message }`, `API.ShiftDown() -> boolean`, `API.NpcView(kind) -> view` (shapes in Task 5), `API.NpcAct(kind, op, arg)`, `API.MerchantView() -> view` (shape in Task 6), `API.SellSlot(bag, slot)`, `API.RepairAll()`, `API.GetCVar(name) -> string|nil`, `API.SetCVar(name, value)`, `API.CancelDuel()`, `API.DeclineGuild()`, `API.StopCinematic()`, `API.FinishMovie()`, `API.CinematicSummary() -> string|nil`, `API.Race() -> string|nil` (English race file name), `API.PlayerMap() -> number|nil`, `API.Later(fn)`, `API.ScreenPixelsPerUnit() -> number|nil`, `API.CursorPosition() -> x, y | nil`, `API.OnEvents(names, fn)`.

- [ ] **Step 1: Write API.lua**

Sources for each call are noted inline; every one was checked in `D:\wow-api\1.60.1.70291\Interface\AddOns`.

```lua
local _, ns = ...

-- The ONLY file that calls Blizzard game APIs (spec 2026-10-13-goblin-things-
-- design.md). Everything is defensive: a missing API or an odd return means
-- "no answer", never an error. Every Blizzard call goes through attempt(),
-- which pcalls it and remembers the message under the call's name so
-- /gt probe can say why a call went quiet.
local API = {}
ns.API = API

local errors = {}

local function finish(name, ok, ...)
    if ok then
        return ...
    end
    errors[name] = tostring((...))
    return nil
end

local function attempt(name, fn, ...)
    return finish(name, pcall(fn, ...))
end

-- attempt() for a function that may not exist on this client.
local function call(name, fn, ...)
    if type(fn) ~= "function" then
        return nil
    end
    return attempt(name, fn, ...)
end

-- name -> message for every call that has thrown since login.
function API.Errors()
    local copy = {}
    for name, message in pairs(errors) do
        copy[name] = message
    end
    return copy
end

function API.ShiftDown()
    return call("IsShiftKeyDown", IsShiftKeyDown) and true or false
end

-- ---- NPC quest windows (from GoblinQuest's API.lua) ----

local function count(n)
    return (type(n) == "number" and n > 0) and math.floor(n) or 0
end

local function str(t)
    return (type(t) == "string") and t or nil
end

local function gossipList(fn, name, keep)
    local out = {}
    local list = call(name, fn)
    if type(list) == "table" then
        for _, q in ipairs(list) do
            if type(q) == "table" and type(q.questID) == "number" then
                out[#out + 1] = keep(q)
            end
        end
    end
    return out
end

-- The window the client just opened, as the plain table Hands.Decide reads.
-- A number the client will not give stays nil, and the Hands wait on nil.
-- An unknown isTrivial counts as trivial: never taken.
function API.NpcView(kind)
    local view = { kind = kind }
    if kind == "gossip" then
        local g = C_GossipInfo or {}
        view.active = gossipList(g.GetActiveQuests, "GetActiveQuests",
            function(q) return { arg = q.questID, questID = q.questID, complete = q.isComplete and true or false } end)
        view.available = gossipList(g.GetAvailableQuests, "GetAvailableQuests",
            function(q)
                return {
                    arg = q.questID,
                    questID = q.questID,
                    trivial = (q.isTrivial ~= false),
                    repeatable = q.repeatable and true or false,
                    ignored = q.isIgnored and true or false,
                    tag = (type(q.questInfoID) == "number") and q.questInfoID or nil,
                    title = str(q.title),
                }
            end)
    elseif kind == "greeting" then
        view.active, view.available = {}, {}
        for i = 1, count(call("GetNumActiveQuests", GetNumActiveQuests)) do
            local _, complete = call("GetActiveTitle", GetActiveTitle, i)
            local activeQuestID = call("GetActiveQuestID", GetActiveQuestID, i)
            view.active[#view.active + 1] = {
                arg = i,
                questID = (type(activeQuestID) == "number") and activeQuestID or nil,
                complete = complete and true or false,
            }
        end
        for i = 1, count(call("GetNumAvailableQuests", GetNumAvailableQuests)) do
            local trivial, _, repeatable, _, questID, _, _, questInfoID =
                call("GetAvailableQuestInfo", GetAvailableQuestInfo, i)
            local title = call("GetAvailableTitle", GetAvailableTitle, i)
            view.available[#view.available + 1] = {
                arg = i,
                questID = (type(questID) == "number") and questID or nil,
                trivial = (trivial ~= false),
                repeatable = repeatable and true or false,
                tag = (type(questInfoID) == "number") and questInfoID or nil,
                title = str(title),
            }
        end
    elseif kind == "detail" or kind == "progress" or kind == "complete" then
        local questID = call("GetQuestID", GetQuestID)
        if kind == "detail" then
            view.pvp = call("QuestFlagsPVP", QuestFlagsPVP) and true or false
            view.auto = call("QuestGetAutoAccept", QuestGetAutoAccept) and true or false
            view.group = call("GetSuggestedGroupSize", GetSuggestedGroupSize)
            if type(view.group) ~= "number" then view.group = nil end
            view.title = str(call("GetTitleText", GetTitleText))
            local tagInfo
            if type(questID) == "number" and C_QuestLog and C_QuestLog.GetQuestTagInfo then
                tagInfo = call("GetQuestTagInfo", C_QuestLog.GetQuestTagInfo, questID)
            end
            view.tag = (type(tagInfo) == "table" and type(tagInfo.tagID) == "number") and tagInfo.tagID or nil
        elseif kind == "progress" then
            view.completable = call("IsQuestCompletable", IsQuestCompletable) and true or false
            local money = call("GetQuestMoneyToGet", GetQuestMoneyToGet)
            view.money = (type(money) == "number") and money or nil
        elseif kind == "complete" then
            local choices = call("GetNumQuestChoices", GetNumQuestChoices)
            view.choices = (type(choices) == "number") and choices or nil
            local money = call("GetQuestMoneyToGet", GetQuestMoneyToGet)
            view.money = (type(money) == "number") and money or nil
        end
        view.questID = questID
    end
    return view
end

-- What each Hands op calls. Gossip selects by questID, the greeting pane by
-- index, as Blizzard's own buttons do.
local ACT = {
    selectActive = function(kind, arg)
        if kind == "gossip" then return C_GossipInfo.SelectActiveQuest(arg) end
        return SelectActiveQuest(arg)
    end,
    selectAvailable = function(kind, arg)
        if kind == "gossip" then return C_GossipInfo.SelectAvailableQuest(arg) end
        return SelectAvailableQuest(arg)
    end,
    accept = function() return AcceptQuest() end,
    acknowledge = function() return AcknowledgeAutoAcceptQuest() end,
    complete = function() return CompleteQuest() end,
    reward = function(_, arg) return GetQuestReward(arg) end,
}

function API.NpcAct(kind, op, arg)
    local fn = ACT[op]
    if fn then
        attempt("NpcAct " .. op, fn, kind, arg)
    end
end

-- ---- vendor (from GoblinQuest's API.lua) ----

-- Sell price (copper) of an item: the 11th return of GetItemInfo.
local function sellPrice(itemID)
    if type(itemID) ~= "number" then
        return nil
    end
    local _, _, _, _, _, _, _, _, _, _, price = call("GetItemInfo", C_Item and C_Item.GetItemInfo, itemID)
    return (type(price) == "number") and price or nil
end

-- The bags and the window as the plain table Vendor.Plan reads. Money is
-- read here, so call this before any selling.
function API.MerchantView()
    local view = { slots = {}, shift = API.ShiftDown() }
    local c = C_Container or {}
    for bag = 0, 4 do
        local n = call("GetContainerNumSlots", c.GetContainerNumSlots, bag)
        for slot = 1, (type(n) == "number") and n or 0 do
            local info = call("GetContainerItemInfo", c.GetContainerItemInfo, bag, slot)
            if type(info) == "table" then
                view.slots[#view.slots + 1] = {
                    bag = bag,
                    slot = slot,
                    quality = info.quality,
                    hasNoValue = info.hasNoValue == true,
                    locked = info.isLocked == true,
                    count = info.stackCount or 1,
                    price = sellPrice(info.itemID),
                }
            end
        end
    end
    view.canRepair = call("CanMerchantRepair", CanMerchantRepair) and true or false
    local cost = call("GetRepairAllCost", GetRepairAllCost)
    view.repairCost = (type(cost) == "number") and cost or nil
    local money = call("GetMoney", GetMoney)
    view.money = (type(money) == "number") and money or nil
    return view
end

function API.SellSlot(bag, slot)
    call("UseContainerItem", C_Container and C_Container.UseContainerItem, bag, slot)
end

function API.RepairAll()
    call("RepairAllItems", RepairAllItems)  -- no argument: own gold
end

-- ---- camera (CVarDocumentation.lua: C_CVar.GetCVar / SetCVar) ----

function API.GetCVar(name)
    return call("GetCVar", C_CVar and C_CVar.GetCVar, name)
end

function API.SetCVar(name, value)
    call("SetCVar", C_CVar and C_CVar.SetCVar, name, value)
end

-- ---- declines: what Blizzard's own popups call ----

-- Blizzard_StaticPopup_Game/GameDialogDefs.lua, DUEL_REQUESTED's decline.
function API.CancelDuel()
    call("CancelDuel", CancelDuel)
end

-- Blizzard_FrameXML/GuildInviteFrame.xml, the Decline button.
function API.DeclineGuild()
    call("DeclineGuild", DeclineGuild)
end

-- ---- cinematics ----

-- CinematicFrame_CancelCinematic's call for a real (cancellable) cinematic.
function API.StopCinematic()
    call("StopCinematic", StopCinematic)
end

-- MovieFrameMixin:FinishMovie (Blizzard_FrameXML/MovieFrame.lua), what its
-- own confirm-skip button calls; only while the movie frame is up.
function API.FinishMovie()
    if MovieFrame and call("MovieFrame:IsShown", MovieFrame.IsShown, MovieFrame) then
        call("MovieFrame:FinishMovie", MovieFrame.FinishMovie, MovieFrame)
    end
end

function API.CinematicSummary()
    return str(call("GetCurrentCinematicSummary", GetCurrentCinematicSummary))
end

-- The English race file name (UnitRace's second return), or nil.
function API.Race()
    local _, race = call("UnitRace", UnitRace, "player")
    return str(race)
end

-- The map the client places the player on, or nil.
function API.PlayerMap()
    local map = call("GetBestMapForUnit", C_Map and C_Map.GetBestMapForUnit, "player")
    return (type(map) == "number" and map ~= 0) and map or nil
end

-- fn on the next frame, after Blizzard's own handler for the same event has
-- shown its frame; at once if the client has no timer.
function API.Later(fn)
    if C_Timer and C_Timer.After then
        call("C_Timer.After", C_Timer.After, 0, fn)
    else
        fn()
    end
end

-- ---- screen (from Goblin Flyout's API.lua) ----

-- Physical pixels per UI unit at scale 1 (the UI is 768 units tall), so a
-- glyph picks a copy that is sharp from 1080p to 4K; nil when unknown.
function API.ScreenPixelsPerUnit()
    local _, height = call("GetPhysicalScreenSize", GetPhysicalScreenSize)
    if type(height) ~= "number" or height <= 0 then
        return nil
    end
    return height / 768
end

-- The cursor's x, y in screen units at scale 1, or nil.
function API.CursorPosition()
    return call("GetCursorPosition", GetCursorPosition)
end

-- ---- events (from Goblin Flyout's API.lua) ----

local eventFrame
local handlers = {}

-- fn(event, ...) for each name. An unknown name is a hard error in the
-- client, so each registration is pcalled and a failure is kept for the probe.
function API.OnEvents(names, fn)
    if not eventFrame then
        eventFrame = CreateFrame("Frame")
        eventFrame:SetScript("OnEvent", function(_, event, ...)
            for _, handler in ipairs(handlers[event] or {}) do
                handler(event, ...)
            end
        end)
    end
    for _, name in ipairs(names) do
        local ok, err = pcall(eventFrame.RegisterEvent, eventFrame, name)
        if ok then
            handlers[name] = handlers[name] or {}
            table.insert(handlers[name], fn)
        else
            errors["RegisterEvent " .. name] = tostring(err)
        end
    end
end

return API
```

- [ ] **Step 2: Run tests, luacheck and lua-language-server**

Expected: tests unchanged (`94 passed, 0 failed`); luacheck `0 warnings / 0 errors`; lua-language-server reports no diagnostics (an empty or `[]` file at `$env:TEMP\gt-luals.json`, or "no problems"). A global it flags that the list in Task 1 missed goes into both `.luacheckrc` and `.luarc.json`.

- [ ] **Step 3: Commit**

```bash
git add GoblinThings/API.lua .luacheckrc .luarc.json
git commit -m "API: the one door to the game for quests, vendors, camera, declines and cinematics

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 12: Core, checklist, README, junction

**Files:**
- Create: `GoblinThings/Core.lua`, `docs/manual-test-checklist.md`, `README.md`

**Interfaces:**
- Consumes: everything above.
- Produces (for Window and MinimapButton): `Core.Get(key)`, `Core.Set(key, value)`, `Core.Angle()`, `Core.SetAngle(angle)`, `Core.MinimapShown()`, `Core.SetMinimapShown(shown)`, `Core.Window()`, `Core.SaveWindow(point, relativePoint, x, y)`, `Core.ToggleWindow()`. Slash `/gt` and `/goblinthings`.

- [ ] **Step 1: Write Core.lua**

```lua
local _, ns = ...

-- Glue (spec 2026-10-13-goblin-things-design.md): the SavedVariable, the
-- events that drive each rule, /gt and the chat lines. Every handler runs
-- behind guard(), so an error is one chat line, said once per label, never a
-- raise. Core.Get / Core.Set are the one door to every setting; the camera's
-- store is the game's own CVar.
local API, Camera, Cinematics, Decline, Features, Hands, MinimapButton, Options, Vendor, Window =
    ns.API, ns.Camera, ns.Cinematics, ns.Decline, ns.Features, ns.Hands, ns.MinimapButton, ns.Options,
    ns.Vendor, ns.Window
local Core = {}
ns.Core = Core

local function say(text)
    print("|cffffd100Goblin Things|r " .. text)
end

local said = {}
local function guard(label, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok and not said[label] then
        said[label] = true
        say(label .. " error: " .. tostring(err) .. " (said once; tell Claude).")
    end
    return ok
end

-- Looked up lazily: SavedVariables load after this file runs, before any
-- handler or command can ask. Checked and repaired once, then read as is.
local checked = false
local function db()
    if not checked then
        GoblinThingsDB = Options.Init(GoblinThingsDB)
        checked = true
    end
    return GoblinThingsDB
end

function Core.Get(key)
    if key == Camera.KEY then
        return Camera.Clamp(API.GetCVar(Camera.CVAR))
    end
    return db().features[key]
end

-- Called from the window's clicks and drags, so it carries its own guard.
function Core.Set(key, value)
    guard("Settings", function()
        if not Features.Valid(Features.ByKey(key), value) then
            return
        end
        if key == Camera.KEY then
            API.SetCVar(Camera.CVAR, Camera.Text(Camera.Clamp(value)))
        else
            db().features[key] = value
        end
        Window.Refresh(Core)
    end)
end

function Core.Angle()
    return db().minimap.angle
end

function Core.SetAngle(angle)
    if type(angle) == "number" then
        db().minimap.angle = angle
    end
end

function Core.MinimapShown()
    return not db().minimap.hide
end

function Core.SetMinimapShown(shown)
    db().minimap.hide = not shown
    MinimapButton.SetShown(shown)
    Window.Refresh(Core)
end

function Core.Window()
    return db().window
end

function Core.SaveWindow(point, relativePoint, x, y)
    if type(point) == "string" and type(relativePoint) == "string" and type(x) == "number" and type(y) == "number" then
        db().window = { point = point, relativePoint = relativePoint, x = x, y = y }
    end
end

function Core.ToggleWindow()
    guard("Window", Window.Toggle, Core)
end

-- ---- quests ----

-- The NPC windows the Hands answer, and the events that end a visit.
Core.NPC_WINDOWS = {
    GOSSIP_SHOW = "gossip", QUEST_GREETING = "greeting", QUEST_DETAIL = "detail",
    QUEST_PROGRESS = "progress", QUEST_COMPLETE = "complete",
}
Core.NPC_END = { GOSSIP_CLOSED = true, QUEST_FINISHED = true }

local visit = Hands.NewVisit()

local function atNpc(event, continuing)
    local kind = Core.NPC_WINDOWS[event]
    if not kind then
        if event == "GOSSIP_CLOSED" and continuing then
            return  -- gossip is handing off to the quest frame; the visit goes on
        end
        visit = Hands.NewVisit()  -- GOSSIP_CLOSED or QUEST_FINISHED: the visit is over
        return
    end
    if API.ShiftDown() then
        visit.held = true  -- Shift at any window keeps the whole visit manual
    end
    local action = Hands.Decide(API.NpcView(kind), db().features, visit)
    if action then
        visit.tried[action.key] = true
        API.NpcAct(kind, action.op, action.arg)
    end
end

local npcEvents = {}
for name in pairs(Core.NPC_WINDOWS) do npcEvents[#npcEvents + 1] = name end
for name in pairs(Core.NPC_END) do npcEvents[#npcEvents + 1] = name end
API.OnEvents(npcEvents, function(event, ...)
    guard("Quests", atNpc, event, ...)
end)

-- ---- vendors ----

local vendorDone = false

local function atVendor(event)
    if event == "MERCHANT_CLOSED" then
        vendorDone = false
        return
    end
    if vendorDone then
        return
    end
    vendorDone = true
    local plan = Vendor.Plan(API.MerchantView(), db().features)
    for _, e in ipairs(plan.sell) do
        API.SellSlot(e.bag, e.slot)
    end
    if plan.repair then
        API.RepairAll()
    end
    if plan.line then
        say(plan.line)
    end
end

API.OnEvents({ "MERCHANT_SHOW", "MERCHANT_CLOSED" }, function(event)
    guard("Vendor", atVendor, event)
end)

-- ---- declines ----

API.OnEvents({ "DUEL_REQUESTED" }, function(_, name)
    guard("Decline", function()
        local line = Decline.Duel(db().features.declineDuels, name)
        if line then
            API.CancelDuel()
            say(line)
        end
    end)
end)

API.OnEvents({ "GUILD_INVITE_REQUEST" }, function(_, inviter, guild)
    guard("Decline", function()
        local line = Decline.Guild(db().features.declineGuild, inviter, guild)
        if line then
            API.DeclineGuild()
            say(line)
        end
    end)
end)

-- ---- cinematics ----

local lastSummary  -- GetCurrentCinematicSummary at the last cinematic, for the probe

local function cinematic(kind, key, canCancel, stop)
    local seen = db().seen
    local action = Cinematics.Decide(db().features.cinematics, seen, kind, key, canCancel)
    if action == "mark" then
        Cinematics.Mark(seen, kind, key)
    elseif action == "stop" then
        API.Later(stop)
    end
end

API.OnEvents({ "PLAY_MOVIE" }, function(_, movieID)
    guard("Cinematics", cinematic, "movie", movieID, true, API.FinishMovie)
end)

API.OnEvents({ "CINEMATIC_START" }, function(_, canBeCancelled)
    guard("Cinematics", function()
        lastSummary = API.CinematicSummary()
        cinematic("cinematic", Cinematics.Key(API.Race(), API.PlayerMap()), canBeCancelled, API.StopCinematic)
    end)
end)

-- ---- /gt ----

local commands = {}
local HELP = "Commands: /gt, /gt minimap, /gt probe."

commands[""] = function()
    Core.ToggleWindow()
end
commands.options = commands[""]

function commands.minimap()
    Core.SetMinimapShown(not Core.MinimapShown())
    if Core.MinimapShown() then
        say("Minimap button shown.")
    else
        say("Minimap button hidden; /gt opens the window.")
    end
end

local function size(t)
    local n = 0
    for _ in pairs(t) do
        n = n + 1
    end
    return n
end

-- What the addon sees, to settle in-game unknowns (the spec's Open facts).
function commands.probe()
    for _, feature in ipairs(Features.LIST) do
        say("Probe: " .. feature.key .. " = " .. tostring(Core.Get(feature.key)))
    end
    say("Probe: " .. Camera.CVAR .. " reads " .. tostring(API.GetCVar(Camera.CVAR)) .. ".")
    local seen = db().seen
    say(("Probe: seen %d movie(s) and %d cinematic(s); this spot's cinematic key is %s."):format(
        size(seen.movies), size(seen.cinematics), tostring(Cinematics.Key(API.Race(), API.PlayerMap()))))
    say("Probe: last cinematic summary: "
        .. (lastSummary and ('"' .. lastSummary .. '"') or "none this session") .. ".")
    for name, message in pairs(API.Errors()) do
        say("Probe: " .. name .. " threw: " .. message)
    end
end

local function slash(msg)
    local word = string.match(msg or "", "^%s*(%S*)")
    local command = commands[string.lower(word or "")]
    if command then
        command()
    else
        say(HELP)
    end
end

API.OnEvents({ "PLAYER_LOGIN" }, function()
    guard("Setup", function()
        if not Options.Register(Core.ToggleWindow) then
            say("Couldn't add the options page; /gt still opens the window.")
        end
        MinimapButton.Create(Core)
    end)
end)

SLASH_GOBLINTHINGS1 = "/gt"
SLASH_GOBLINTHINGS2 = "/goblinthings"
SlashCmdList.GOBLINTHINGS = function(msg) guard("Slash", slash, msg) end

return Core
```

- [ ] **Step 2: Run tests, luacheck and lua-language-server**

Expected: `94 passed, 0 failed`; both linters clean.

- [ ] **Step 3: Write the manual test checklist**

`docs/manual-test-checklist.md`:

```markdown
# Manual test checklist

In-game checks for what unit tests cannot reach. Only the owner runs the client.
Mark each with the build and date when walked; `[-]` is skipped by choice, with the reason.

## Install

- [ ] After the junction and a **full client restart**, Goblin Things is listed and enabled in the
      AddOns list with its round GT icon; no Lua error on login.
- [ ] `/gt probe` lists the eight settings (autoAccept true ... declineDuels false, cinematics
      repeats, cameraDistance a number), the CVar, the seen counts, a cinematic key like
      `Scourge:1420`, "none this session", and no "threw:".

## Window and minimap

- [ ] A round minimap button sits on the rim, clear of Goblin Flyout's: gold "GT" on a teal disc.
      Hover: "Goblin Things / Click for options, drag to move. / Time is money, friend."
- [ ] Dragging it slides it round the rim; `/reload`: it stays where it was put.
- [ ] Click, `/gt` and `/gt options` open the window; Escape or the X closes it.
- [ ] Esc > Options > AddOns lists "Goblin Things" with a gold "Open Goblin Things" button that opens the window.
- [ ] The window shows five gold headers (Quests, Vendors, Social, Camera, Cinematics), eight rows, the
      "Show minimap button" check and "Hold Shift at an NPC or vendor to skip." Nothing overlaps.
- [ ] Each check flips on click and stays flipped after `/reload`.
- [ ] Off | Repeats only | All: the chosen one is gold; it stays after `/reload`.
- [ ] Unticking "Show minimap button" hides it; `/gt minimap` brings it back.
- [ ] The window remembers where it was dragged after `/reload`.

## Camera

- [ ] Before touching our slider, `/dump GetCVar("cameraDistanceMaxZoomFactor")`, open and close the
      window, `/dump` again: **the same value** (opening the window writes nothing).
- [ ] The slider shows the CVar (e.g. 4.0 after the 2026-10-13 test). Dragging it moves the number in
      0.1 steps from 1.0 to 4.0, and `/dump` shows the new value; the camera zooms out further at 4.0.
- [ ] Set 3.0 here, then move Blizzard's Options > Controls slider to 1.5, reopen our window: it shows 1.5.
- [ ] Moving our slider in combat changes the CVar, or `/gt probe` shows a SetCVar error (open fact 3).

## Quests

- [ ] An NPC with one quest: the offer is accepted with no clicks.
- [ ] Turning in a quest with no reward choice: completed and rewarded with no clicks.
- [ ] A quest with two or more reward choices: the reward window waits for you.
- [ ] A gray, a repeatable, a dungeon, a PvP or a gold-costing quest: left for you.
- [ ] Shift held while talking to the NPC: nothing is accepted or turned in that visit.
- [ ] Each switch off on its own: only the other thing happens.

## Vendors

- [ ] A vendor with grays (one a stack) and damaged gear: grays sold, gear repaired, one chat line,
      Buyback shows the grays.
- [ ] A vendor that cannot repair: grays sold, no repair, no complaint.
- [ ] Short of gold for the repair: "Not enough gold to repair (costs ...)", nothing repaired, grays still sold.
- [ ] Shift held while opening the vendor: nothing sold, nothing repaired, no line.
- [ ] Open a vendor, close, reopen: it acts again on the reopen, once.
- [ ] Each switch off on its own: only the other thing happens.

## Social

- [ ] Decline duels on: a friend's duel request is refused, "Declined a duel from <name>." is said,
      and **no duel popup lingers** (open fact 2).
- [ ] Decline duels off: the duel popup appears as normal.
- [ ] Decline guild invites on: an invite is refused with "Declined a guild invite from <name>
      (<guild>)." and **no invite window lingers** (open fact 2).
- [ ] Decline guild invites off: the invite window appears as normal.

## Cinematics

- [ ] New character, Skip cinematics on Repeats only: the race intro plays. Then `/gt probe`: the
      last cinematic summary line shows what the game said (open fact 1; tell Claude what it was).
- [ ] Same race, another new character in the same zone: the intro is skipped.
- [ ] Mode All: an intro you have never seen is skipped.
- [ ] Mode Off: the intro plays.
- [ ] A flight path or any vehicle ride plays normally in every mode (it is not a cinematic).
```

- [ ] **Step 4: Write README.md**

```markdown
# Goblin Things

*Time is money, friend.*

Small goblin conveniences for **WoW Forever** (interface 16001), set once in one window and forgotten.

| Switch | What it does | Starts |
|---|---|---|
| Auto accept quests | Takes offered quests, except gray, repeatable, dungeon, raid, group and PvP quests | On |
| Auto turn-in quests | Hands in finished quests, except ones that cost gold or offer a reward choice | On |
| Auto sell junk | Sells gray items at any vendor, with one chat line | On |
| Auto repair | Repairs with your own gold at vendors who repair | On |
| Decline duels | Refuses every duel request | Off |
| Decline guild invites | Refuses every guild invite | Off |
| Camera distance | Zooms the camera out to 4.0, past Blizzard's 2.0 | Untouched |
| Skip cinematics | Off, repeats only, or all | Repeats only |

Hold **Shift** while talking to an NPC or opening a vendor to skip everything that visit.

## Getting started

Click the round **GT** button on the minimap, or type `/gt`.

## Commands

| Command | Does |
|---|---|
| `/gt` | Opens the Goblin Things window |
| `/gt minimap` | Hides or shows the minimap button |
| `/gt probe` | Prints what the addon sees; include it in bug reports |

## Install

Copy the `GoblinThings` folder into `World of Warcraft\_classic_beta_\Interface\AddOns\` and restart the game.

## For developers

See `CLAUDE.md` for the rules, architecture, tests and lint commands, and `docs/` for the design
spec and the in-game test checklist.
```

- [ ] **Step 5: Junction the addon into the client**

```powershell
New-Item -ItemType Junction -Path "D:\World of Warcraft\_classic_beta_\Interface\AddOns\GoblinThings" -Target "D:\GoblinThings\GoblinThings"
```

Expected: a junction listing for `GoblinThings`. If the path already exists, stop and tell the owner instead of overwriting it.

- [ ] **Step 6: Run everything once more**

Tests `94 passed, 0 failed`; luacheck and lua-language-server clean.

- [ ] **Step 7: Commit**

```bash
git add GoblinThings/Core.lua docs/manual-test-checklist.md README.md
git commit -m "Core: events, settings door and /gt; the in-game checklist and README

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 8: Hand over to the owner**

Tell the owner: a **full client restart** is needed (a new addon, a new TOC and new TGAs), then walk `docs/manual-test-checklist.md`, starting with Install and Camera, and send the `/gt probe` output plus the cinematic summary line.
