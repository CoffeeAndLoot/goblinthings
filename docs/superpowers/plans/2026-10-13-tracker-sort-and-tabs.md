# Tracker Sort and Tabs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the player order the built-in quest tracker by up to three tiers (Level, Finished, This zone), and turn the Goblin Things window into tabs.

**Architecture:** Three new choice features in `Features.LIST` drive a pure `TrackerSort` module (tiers, no-repeats, comparison). `API.lua` installs a wrapper on `QuestObjectiveTracker.BuildQuestWatchInfos` that reorders a copy of Blizzard's list, and removes it when every tier is None. The window becomes one tab per `Features` section, with group sub-headers and a per-section note, every page as tall as the tallest.

**Tech Stack:** Lua 5.1 WoW addon (interface 16001), lupa tests, luacheck, lua-language-server.

**Spec:** `docs/superpowers/specs/2026-10-13-tracker-sort-and-tabs-design.md` (builds on `docs/superpowers/specs/2026-10-13-goblin-things-design.md`)

## Global Constraints

- Repo root `D:\GoblinThings`; addon folder `GoblinThings/`.
- `API.lua` is the only file that calls Blizzard game APIs, each through `attempt()` / `call()`.
- Pure modules touch no Blizzard global at file load; `test/run.lua` loads them (hand-kept lists: add every new module and suite).
- No libraries; no Blizzard frame templates in the window; colours only from `Look.COLOUR`.
- An unknown answer from the game means do nothing; a sort bug must return Blizzard's list, never an empty tracker.
- All three tiers on `none` means the addon never touches the tracker.
- Adding a file to the TOC needs a full client restart.
- luacheck and lua-language-server at zero warnings; new globals in both `.luacheckrc` and `.luarc.json`.
- Commit after each task: `Area: plain sentence`, ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Never push.

Commands, from `D:\GoblinThings`:

```powershell
# Tests (whole suite)
python -c "import lupa.lua51 as L; lua=L.LuaRuntime(unpack_returned_tuples=True); print(lua.execute(open('test/run.lua').read().replace('os.exit(harness.run())','return harness.run()')))"

# Lint
$env:PATH = "$HOME\AppData\Local\Programs\Lua\bin;$env:PATH"
$env:LUA_PATH = "$HOME\.luarocks\share\lua\5.4\?.lua;$HOME\.luarocks\share\lua\5.4\?\init.lua;;"
lua "$HOME\.luarocks\share\lua\5.4\luacheck\main.lua" GoblinThings test --no-color --no-cache
lua-language-server --check D:\GoblinThings --checklevel=Warning --check_out_path=$env:TEMP\gt-luals.json
```

## Review Focus

1. **Turning the sort off when it was never on must not touch the tracker** (no taint for a player who never uses it). Owned by Task 6 (`installed` flag); pinned by a checklist entry.
2. **A sort error must leave the tracker showing Blizzard's list.** The wrapper `pcall`s the sorter and checks the result's length. Owned by Task 5; pinned by a checklist entry using a deliberate bad sorter via `/run`.
3. **A quest the log has no info for** (nil level) must sort after known levels, never error. Pinned by a test in Task 2.
4. **A saved `tab` that no longer names a tab** (renamed section, junk) must open the first tab. Pinned by a test in Task 3.
5. **"This zone" must follow the player** across zone, sub-zone and indoor changes while the sort is on. Owned by Task 6; pinned by a checklist entry.

---

### Task 1: Features: tracker sort slots, groups and notes

**Files:**
- Modify: `GoblinThings/Features.lua`
- Test: `test/test_features.lua`, `test/test_window.lua`

**Interfaces:**
- Produces: features `sortFirst`, `sortSecond`, `sortThird` (section `Quests`, group `Tracker sort`, control `choice`, choices `{ "none", "level", "finished", "zone" }`, labels `{ none = "None", level = "Level", finished = "Finished", zone = "This zone" }`, default `"none"`, labels `1st`, `2nd`, `3rd`); `Features.NOTES = { Quests = "All None = Blizzard's order (fully after /reload)" }`; `Features.Sections()` entries gain `note` (string or nil).

- [ ] **Step 1: Update the tests**

In `test/test_features.lua` replace the "holds the eight switches" test with:

```lua
        h.it("holds the switches in window order", function()
            local keys = {}
            for _, f in ipairs(Features.LIST) do
                keys[#keys + 1] = f.key
            end
            h.eq(table.concat(keys, " "), "autoAccept autoTurnIn sortFirst sortSecond sortThird autoSellJunk "
                .. "autoRepair declineDuels declineGuild cameraDistance cinematics")
        end)
        h.it("the three tracker sort slots are choices grouped under Tracker sort, starting at None", function()
            for _, key in ipairs({ "sortFirst", "sortSecond", "sortThird" }) do
                local f = Features.ByKey(key)
                h.eq(f.section, "Quests", key)
                h.eq(f.group, "Tracker sort", key)
                h.eq(f.default, "none", key)
                h.eq(table.concat(f.choices, " "), "none level finished zone", key)
                h.eq(f.labels.zone, "This zone", key)
            end
            h.eq(Features.ByKey("sortFirst").label, "1st")
            h.eq(Features.ByKey("sortThird").label, "3rd")
        end)
```

Replace the "groups rows by section" test with:

```lua
        h.it("groups rows by section in LIST order", function()
            local names, counts = {}, {}
            for _, s in ipairs(Features.Sections()) do
                names[#names + 1] = s.name
                counts[#counts + 1] = #s.features
            end
            h.eq(table.concat(names, " "), "Quests Vendors Social Camera Cinematics")
            h.eq(table.concat(counts, " "), "5 2 2 1 1")
        end)
        h.it("a section carries its note; the others have none", function()
            local sections = Features.Sections()
            h.eq(sections[1].note, "All None = Blizzard's order (fully after /reload)")
            h.eq(sections[2].note, nil)
        end)
```

In `test/test_window.lua` replace the "fits the eight switches under five headers" test (the old window still lays every row in one well until Task 4) with:

```lua
        h.it("fits every switch under its five headers", function()
            h.eq(Window.WellHeight(loaded.ns.Features.Sections()),
                2 * L.WELL_PAD + 5 * L.SECTION + #loaded.ns.Features.LIST * L.ROW)
        end)
```

- [ ] **Step 2: Run to verify the new tests fail**

Expected: failures in `holds the switches in window order`, `the three tracker sort slots...`, `groups rows by section` and `a section carries its note` (no such keys or note yet); everything else passes.

- [ ] **Step 3: Add the slots and the note**

In `GoblinThings/Features.lua`, after `ns.Features = Features` add:

```lua
-- The tracker sort's three tiers share their choices (spec
-- 2026-10-13-tracker-sort-and-tabs-design.md, Settings).
local SORT_CHOICES = { "none", "level", "finished", "zone" }
local SORT_LABELS = { none = "None", level = "Level", finished = "Finished", zone = "This zone" }

local function sortSlot(key, label)
    return { key = key, label = label, section = "Quests", group = "Tracker sort", control = "choice",
        default = "none", choices = SORT_CHOICES, labels = SORT_LABELS }
end
```

In `Features.LIST`, after the `autoTurnIn` entry insert:

```lua
    sortSlot("sortFirst", "1st"),
    sortSlot("sortSecond", "2nd"),
    sortSlot("sortThird", "3rd"),
```

After `Features.LIST` add:

```lua
-- A dim line at the foot of a section's tab.
Features.NOTES = { Quests = "All None = Blizzard's order (fully after /reload)" }
```

In `Features.Sections`, change the new-section line to carry the note:

```lua
            section = { name = feature.section, features = {}, note = Features.NOTES[feature.section] }
```

and update its comment to `-- { { name, features, note } ... }: LIST grouped by section, in LIST order.`

- [ ] **Step 4: Run tests and lint**

Expected: `100 passed, 0 failed`; luacheck clean.

- [ ] **Step 5: Commit**

```bash
git add GoblinThings/Features.lua test/test_features.lua test/test_window.lua
git commit -m "Features: three tracker sort tiers on the Quests section, with groups and a note

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: TrackerSort

**Files:**
- Create: `GoblinThings/TrackerSort.lua`
- Modify: `GoblinThings/GoblinThings.toc` (add `TrackerSort.lua` after `Decline.lua`), `test/run.lua`
- Test: `test/test_trackersort.lua`

**Interfaces:**
- Produces: `ns.TrackerSort.SLOTS = { "sortFirst", "sortSecond", "sortThird" }`; `TrackerSort.IsSlot(key) -> boolean`; `TrackerSort.Tiers(features) -> { "zone", "level" ... }` (active tiers in slot order, `none` and unknown values left out); `TrackerSort.Assign(features, slot, value) -> { [slot] = value, [other] = "none" ... }`; `TrackerSort.Less(a, b, tiers) -> boolean` with `a`, `b` = `{ level = number|nil, finished = boolean|nil, onMap = boolean|nil, index = number }`; `TrackerSort.Order(entries, tiers) -> new array` (input untouched).

- [ ] **Step 1: Write the failing test**

`test/test_trackersort.lua`:

```lua
return function(h, loaded)
    local TrackerSort = loaded.ns.TrackerSort

    local function q(index, level, finished, onMap)
        return { index = index, level = level, finished = finished, onMap = onMap }
    end

    local function order(entries, tiers)
        local out = {}
        for i, e in ipairs(TrackerSort.Order(entries, tiers)) do
            out[i] = e.index
        end
        return table.concat(out, " ")
    end

    h.describe("TrackerSort.Tiers", function()
        h.it("all None is no tiers: the sort is off", function()
            h.eq(#TrackerSort.Tiers({ sortFirst = "none", sortSecond = "none", sortThird = "none" }), 0)
            h.eq(#TrackerSort.Tiers({}), 0)
        end)
        h.it("keeps the set tiers in slot order and skips None and junk", function()
            local tiers = TrackerSort.Tiers({ sortFirst = "zone", sortSecond = "none", sortThird = "level" })
            h.eq(table.concat(tiers, " "), "zone level")
            h.eq(#TrackerSort.Tiers({ sortFirst = "sideways" }), 0)
        end)
        h.it("knows its three slots", function()
            h.truthy(TrackerSort.IsSlot("sortSecond"))
            h.falsy(TrackerSort.IsSlot("autoAccept"))
        end)
    end)

    h.describe("TrackerSort.Assign", function()
        h.it("taking a key another slot holds clears that slot to None", function()
            local c = TrackerSort.Assign({ sortFirst = "level", sortSecond = "none", sortThird = "zone" },
                "sortSecond", "level")
            h.eq(c.sortSecond, "level")
            h.eq(c.sortFirst, "none")
            h.eq(c.sortThird, nil)
        end)
        h.it("None never clears another slot", function()
            local c = TrackerSort.Assign({ sortFirst = "none", sortSecond = "level" }, "sortThird", "none")
            h.eq(c.sortThird, "none")
            h.eq(c.sortFirst, nil)
            h.eq(c.sortSecond, nil)
        end)
        h.it("re-picking a slot's own key changes nothing else", function()
            local c = TrackerSort.Assign({ sortFirst = "level" }, "sortFirst", "level")
            h.eq(c.sortFirst, "level")
            h.eq(c.sortSecond, nil)
        end)
    end)

    h.describe("TrackerSort.Less", function()
        h.it("level: lower first", function()
            h.truthy(TrackerSort.Less(q(2, 10), q(1, 12), { "level" }))
            h.falsy(TrackerSort.Less(q(1, 12), q(2, 10), { "level" }))
        end)
        h.it("level: an unknown level sorts after every known one", function()
            h.truthy(TrackerSort.Less(q(2, 60), q(1, nil), { "level" }))
            h.falsy(TrackerSort.Less(q(1, nil), q(2, 60), { "level" }))
            h.truthy(TrackerSort.Less(q(1, nil), q(2, nil), { "level" }))
        end)
        h.it("finished first; unknown counts as not finished", function()
            h.truthy(TrackerSort.Less(q(2, 10, true), q(1, 10, false), { "finished" }))
            h.truthy(TrackerSort.Less(q(2, 10, true), q(1, 10, nil), { "finished" }))
        end)
        h.it("this zone first; unknown counts as elsewhere", function()
            h.truthy(TrackerSort.Less(q(2, 10, false, true), q(1, 10, false, nil), { "zone" }))
        end)
        h.it("every tier tied: Blizzard's order", function()
            h.truthy(TrackerSort.Less(q(1, 10, true, true), q(2, 10, true, true), { "level", "finished", "zone" }))
            h.falsy(TrackerSort.Less(q(2, 10), q(1, 10), {}))
        end)
    end)

    h.describe("TrackerSort.Order", function()
        h.it("steps down the tiers: this zone, then finished, then level", function()
            local entries = {
                q(1, 10, false, true), q(2, 12, true, true), q(3, 5, true, false),
                q(4, 3, false, false), q(5, 8, false, true),
            }
            h.eq(order(entries, { "zone", "finished", "level" }), "2 5 1 3 4")
        end)
        h.it("no tiers keeps Blizzard's order", function()
            h.eq(order({ q(1, 30), q(2, 10), q(3, 20) }, {}), "1 2 3")
        end)
        h.it("returns a new list and leaves Blizzard's untouched", function()
            local entries = { q(1, 30), q(2, 10) }
            local sorted = TrackerSort.Order(entries, { "level" })
            h.eq(sorted[1].index, 2)
            h.eq(entries[1].index, 1)
        end)
    end)
end
```

In `test/run.lua` add `{ "TrackerSort", "GoblinThings/TrackerSort.lua" },` after the Decline entry, and `"test/test_trackersort.lua",` after `"test/test_decline.lua",`.

- [ ] **Step 2: Run to verify it fails**

Expected: `cannot open GoblinThings/TrackerSort.lua`.

- [ ] **Step 3: Write TrackerSort.lua**

```lua
local _, ns = ...

-- The quest tracker's order (spec 2026-10-13-tracker-sort-and-tabs-design.md,
-- The rule): up to three tiers, each a step down from the last. Level is lowest
-- first, Finished puts finished quests first, This zone puts quests on the
-- current map first; whatever still ties keeps Blizzard's own order (index).
-- A value the game did not give sorts as the weakest. Pure.
local TrackerSort = {}
ns.TrackerSort = TrackerSort

TrackerSort.SLOTS = { "sortFirst", "sortSecond", "sortThird" }
TrackerSort.KEYS = { level = true, finished = true, zone = true }

function TrackerSort.IsSlot(key)
    for _, slot in ipairs(TrackerSort.SLOTS) do
        if slot == key then
            return true
        end
    end
    return false
end

-- The active tiers in slot order; none and anything unknown left out.
function TrackerSort.Tiers(features)
    local tiers = {}
    for _, slot in ipairs(TrackerSort.SLOTS) do
        local key = features[slot]
        if TrackerSort.KEYS[key] then
            tiers[#tiers + 1] = key
        end
    end
    return tiers
end

-- The settings to write when slot takes value: no key in two slots, so the
-- slot that held it goes back to none. none may repeat.
function TrackerSort.Assign(features, slot, value)
    local changes = { [slot] = value }
    if value ~= "none" then
        for _, other in ipairs(TrackerSort.SLOTS) do
            if other ~= slot and features[other] == value then
                changes[other] = "none"
            end
        end
    end
    return changes
end

local function level(entry)
    return type(entry.level) == "number" and entry.level or nil
end

function TrackerSort.Less(a, b, tiers)
    for _, tier in ipairs(tiers) do
        if tier == "level" then
            local x, y = level(a), level(b)
            if x ~= y then
                if x == nil then
                    return false
                elseif y == nil then
                    return true
                end
                return x < y
            end
        elseif tier == "finished" then
            local x, y = a.finished == true, b.finished == true
            if x ~= y then
                return x
            end
        elseif tier == "zone" then
            local x, y = a.onMap == true, b.onMap == true
            if x ~= y then
                return x
            end
        end
    end
    return a.index < b.index
end

-- A sorted copy of entries ({ level, finished, onMap, index, ... }).
function TrackerSort.Order(entries, tiers)
    local out = {}
    for i, entry in ipairs(entries) do
        out[i] = entry
    end
    table.sort(out, function(a, b)
        return TrackerSort.Less(a, b, tiers)
    end)
    return out
end

return TrackerSort
```

In `GoblinThings/GoblinThings.toc` add `TrackerSort.lua` on the line after `Decline.lua`.

- [ ] **Step 4: Run tests and lint**

Expected: `114 passed, 0 failed`; luacheck clean.

- [ ] **Step 5: Commit**

```bash
git add GoblinThings/TrackerSort.lua GoblinThings/GoblinThings.toc test/test_trackersort.lua test/run.lua
git commit -m "TrackerSort: tiers, no repeats and the step-down comparison for the quest tracker

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Options: the remembered tab

**Files:**
- Modify: `GoblinThings/Options.lua`
- Test: `test/test_options.lua`

**Interfaces:**
- Consumes: `ns.Features.Sections()` (names in order).
- Produces: `Options.IsTab(name) -> boolean`; `Options.Init(db)` also guarantees `db.tab` names a tab (default the first, `"Quests"`).

- [ ] **Step 1: Write the failing tests**

Add to the `Options.Init` describe in `test/test_options.lua`:

```lua
        h.it("the tracker sort tiers start at None and junk resets to None", function()
            local db = Options.Init({ features = { sortFirst = "level", sortSecond = "sideways" } })
            h.eq(db.features.sortFirst, "level")
            h.eq(db.features.sortSecond, "none")
            h.eq(db.features.sortThird, "none")
        end)
        h.it("opens on the first tab; keeps a saved tab only while it names one", function()
            h.eq(Options.Init(nil).tab, "Quests")
            h.eq(Options.Init({ tab = "Camera" }).tab, "Camera")
            h.eq(Options.Init({ tab = "Mail" }).tab, "Quests")
            h.eq(Options.Init({ tab = 3 }).tab, "Quests")
        end)
```

And a new describe after it:

```lua
    h.describe("Options.IsTab", function()
        h.it("is true only for a Features section", function()
            h.truthy(Options.IsTab("Social"))
            h.falsy(Options.IsTab("Mail"))
            h.falsy(Options.IsTab(nil))
        end)
    end)
```

- [ ] **Step 2: Run to verify they fail**

Expected: `opens on the first tab...` and `Options.IsTab` fail (no `tab`, no `IsTab`); the tiers test already passes because `Options.Init` stores every feature with a default (Task 1 added them). That one is a pin, not a driver.

- [ ] **Step 3: Add the tab**

In `GoblinThings/Options.lua`, before `function Options.Init`, add:

```lua
function Options.IsTab(name)
    for _, section in ipairs(ns.Features.Sections()) do
        if section.name == name then
            return true
        end
    end
    return false
end
```

In `Options.Init`, before `local window = db.window`, add:

```lua
    if not Options.IsTab(db.tab) then
        db.tab = ns.Features.Sections()[1].name  -- the window opens on the last tab used
    end
```

- [ ] **Step 4: Run tests and lint**

Expected: `117 passed, 0 failed`; luacheck clean.

- [ ] **Step 5: Commit**

```bash
git add GoblinThings/Options.lua test/test_options.lua
git commit -m "Options: remember the window's tab, falling back to the first

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Window with tabs

**Files:**
- Modify: `GoblinThings/Window.lua` (rewrite)
- Test: `test/test_window.lua` (rewrite)

**Interfaces:**
- Consumes: `ns.Features.Sections()` (`name`, `features`, `note`; features' `group`), `ns.Look.*`, `ns.Camera.Text`, `ns.Options.NAME`; from Core (Task 6): `core.Get`, `core.Set`, `core.Tab()`, `core.SetTab(name)`, `core.MinimapShown`, `core.SetMinimapShown`, `core.Window`, `core.SaveWindow`.
- Produces: `Window.PageHeight(section) -> number`, `Window.Height(sections) -> number` (pure), `Window.Toggle(core)`, `Window.Refresh(core)`. `Window.WellHeight` is removed.

- [ ] **Step 1: Write the failing test**

Replace `test/test_window.lua` with:

```lua
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
```

- [ ] **Step 2: Run to verify it fails**

Expected: the three tests fail (`PageHeight`/`Height` are nil, `L.TAB_H` nil).

- [ ] **Step 3: Rewrite Window.lua**

```lua
local _, ns = ...

-- The settings window (spec 2026-10-13-tracker-sort-and-tabs-design.md, Tabs)
-- in the Goblin look (Look.lua): a dark window with a gold top edge, a header
-- to drag it by, a strip of tabs (one per Features section), and under it one
-- inset page per tab: that section's rows, a gold sub-header over each group
-- and the section's dim note. Every page is as tall as the tallest, so
-- switching tabs never resizes the window. Rows read and write through
-- core.Get / core.Set. Plain frames, no Blizzard templates. PageHeight and
-- Height are pure; the rest makes frames only when called.
local Window = {}
ns.Window = Window

Window.NAME = "GoblinThingsWindow"  -- UISpecialFrames closes frames by name on Escape
Window.WIDTH = 420
Window.HOME = { "CENTER", "CENTER", 0, 40 }  -- where it opens until dragged
Window.LAYOUT = {
    TOP_EDGE = 2, HEADER = 56, PAD = 16, CLOSE = 28, TAB_H = 26, WELL_PAD = 4, GROUP = 26, ROW = 36,
    NOTE = 22, INDENT = 26, CHECK = 18, SLIDER_W = 160, SLIDER_H = 16, VALUE_W = 34, CHOICE_H = 24,
    CHOICE_PAD = 20, FOOT = 62,
}
local L = Window.LAYOUT

function Window.PageHeight(section)
    local height, last = 2 * L.WELL_PAD + #section.features * L.ROW, nil
    for _, feature in ipairs(section.features) do
        if feature.group and feature.group ~= last then
            height = height + L.GROUP
        end
        last = feature.group
    end
    if section.note then
        height = height + L.NOTE
    end
    return height
end

local function tallest(sections)
    local most = 0
    for _, section in ipairs(sections) do
        most = math.max(most, Window.PageHeight(section))
    end
    return most
end

function Window.Height(sections)
    return L.TOP_EDGE + L.HEADER + L.PAD + L.TAB_H + L.PAD + tallest(sections) + L.FOOT
end

local frame
local controls = {}  -- feature key -> { feature, check } | { feature, slider, value } | { feature, buttons }
local tabs = {}      -- section name -> its tab button
local pages = {}     -- section name -> its page
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

-- One button per section, equal widths, borders overlapping into one strip.
local function buildTabs(core, sections, top)
    local n = #sections
    local width = math.floor((Window.WIDTH - 2 * L.PAD + (n - 1)) / n)
    for i, section in ipairs(sections) do
        local name = section.name
        local b = ns.Look.Button(frame, name, width, L.TAB_H, function()
            core.SetTab(name)
        end)
        b:SetPoint("TOPLEFT", frame, "TOPLEFT", L.PAD + (i - 1) * (width - 1), top)
        tabs[name] = b
    end
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
-- switch, each as wide as its words. Unbounded: the label is anchored inside
-- a 10 px button, so GetStringWidth would measure the clipped text.
local function choiceControl(core, r, feature)
    local Look = ns.Look
    local buttons, right = {}, nil
    for i = #feature.choices, 1, -1 do
        local choice = feature.choices[i]
        local b = Look.Button(r, feature.labels[choice], 10, L.CHOICE_H, function()
            core.Set(feature.key, choice)
        end)
        b:SetWidth(math.ceil(b.label:GetUnboundedStringWidth()) + L.CHOICE_PAD)
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

local function row(core, page, feature, y)
    local r = CreateFrame("Frame", nil, page)
    r:SetHeight(L.ROW)
    r:SetPoint("TOPLEFT", page, "TOPLEFT", L.WELL_PAD, y)
    r:SetPoint("TOPRIGHT", page, "TOPRIGHT", -L.WELL_PAD, y)
    local control = MAKERS[feature.control](core, r, feature)
    control.feature = feature
    controls[feature.key] = control
    local name = ns.Look.Text(r, ns.Look.WORDS, 13, "text")
    name:SetPoint("LEFT", r, "LEFT", L.INDENT, 0)
    name:SetText(feature.label)
end

local function groupHeader(page, name, y)
    local text = ns.Look.Text(page, ns.Look.WORDS, 12, "gold")
    text:SetPoint("TOPLEFT", page, "TOPLEFT", L.WELL_PAD + 10, y - 8)
    text:SetText(name)
end

local function note(page, words, y)
    local text = ns.Look.Text(page, ns.Look.WORDS, 10, "dim")
    text:SetPoint("TOPLEFT", page, "TOPLEFT", L.WELL_PAD + L.INDENT, y - 4)
    text:SetPoint("RIGHT", page, "RIGHT", -10, 0)
    text:SetText(words)
end

local function buildPage(core, section, top, height)
    local Look = ns.Look
    local page = CreateFrame("Frame", nil, frame)
    page:SetPoint("TOPLEFT", frame, "TOPLEFT", L.PAD, top)
    page:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -L.PAD, top)
    page:SetHeight(height)
    Look.Texture(page, "BACKGROUND", Look.COLOUR.inset):SetAllPoints(page)
    Look.Outline(page, Look.COLOUR.line)
    local y, last = -L.WELL_PAD, nil
    for _, feature in ipairs(section.features) do
        if feature.group and feature.group ~= last then
            groupHeader(page, feature.group, y)
            y = y - L.GROUP
        end
        last = feature.group
        row(core, page, feature, y)
        y = y - L.ROW
    end
    if section.note then
        note(page, section.note, y)
    end
    return page
end

local function make(core)
    local Look = ns.Look
    local sections = ns.Features.Sections()
    frame = CreateFrame("Frame", Window.NAME, UIParent)
    frame:SetSize(Window.WIDTH, Window.Height(sections))
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

    local tabTop = -(L.TOP_EDGE + L.HEADER + L.PAD)
    buildTabs(core, sections, tabTop)
    local pageTop, height = tabTop - L.TAB_H - L.PAD, tallest(sections)
    for _, section in ipairs(sections) do
        pages[section.name] = buildPage(core, section, pageTop, height)
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

-- Shows the open tab's page with its tab gold, and draws every control from
-- core.Get: checks on or off, the slider and its number (the camera CVar,
-- read fresh: "?" when the game gives no answer), the chosen choice gold, and
-- the minimap check.
function Window.Refresh(core)
    if not frame then
        return
    end
    local open = core.Tab()
    for name, b in pairs(tabs) do
        ns.Look.Style(b, name == open and "gold" or "quiet")
    end
    for name, page in pairs(pages) do
        page:SetShown(name == open)
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

Expected: `118 passed, 0 failed`; luacheck clean.

- [ ] **Step 5: Commit**

```bash
git add GoblinThings/Window.lua test/test_window.lua
git commit -m "Window: one tab per section, group sub-headers and notes, every page the same height

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: API: hooking the tracker

**Files:**
- Modify: `GoblinThings/API.lua`, `.luacheckrc`, `.luarc.json`

No unit test: every line calls the game. Lint is its check; Task 6's checklist is its test in game.

**Interfaces:**
- Produces: `API.TrackerFacts(quest) -> { level = number|nil, finished = boolean, onMap = boolean }` (`quest` is a tracker quest object; an unreadable one gives `{}`); `API.SetTrackerSort(sorter) -> boolean` (`sorter(infos) -> reordered copy` of Blizzard's `{ { quest, index } ... }`, or nil to remove the wrapper; false when the tracker is missing); `API.RedrawTracker()`.

- [ ] **Step 1: Add the globals**

Append `"QuestObjectiveTracker", "QuestObjectiveTrackerMixin",` to `read_globals` in `.luacheckrc` (last line, before the closing brace), and the same two names to `diagnostics.globals` in `.luarc.json` (after `"C_Map"`, comma-separated).

- [ ] **Step 2: Add the tracker section to API.lua**

Insert before the `-- ---- screen (from Goblin Flyout's API.lua) ----` line:

```lua
-- ---- quest tracker (spec 2026-10-13-tracker-sort-and-tabs-design.md) ----

-- What a tracked quest is sorted by. Only the ID is read from the tracker's
-- quest object; the rest is asked of the game, nil when it gives no answer.
function API.TrackerFacts(quest)
    if type(quest) ~= "table" or type(quest.GetID) ~= "function" then
        return {}
    end
    local id = attempt("quest:GetID", quest.GetID, quest)
    if type(id) ~= "number" or not C_QuestLog then
        return {}
    end
    local logIndex = call("GetLogIndexForQuestID", C_QuestLog.GetLogIndexForQuestID, id)
    local info = type(logIndex) == "number" and call("GetInfo", C_QuestLog.GetInfo, logIndex) or nil
    return {
        level = (type(info) == "table" and type(info.level) == "number") and info.level or nil,
        finished = call("IsComplete", C_QuestLog.IsComplete, id) == true,
        onMap = call("IsOnMap", C_QuestLog.IsOnMap, id) == true,
    }
end

local trackerSorter

-- Stands in for QuestObjectiveTrackerMixin:BuildQuestWatchInfos: Blizzard's
-- list, reordered. A sorter that errors or loses quests gives Blizzard's list.
local function sortedWatchInfos(self)
    local infos = QuestObjectiveTrackerMixin.BuildQuestWatchInfos(self)
    if not trackerSorter then
        return infos
    end
    local ok, sorted = pcall(trackerSorter, infos)
    if ok and type(sorted) == "table" and #sorted == #infos then
        return sorted
    end
    errors["Tracker sort"] = ok and "the sort lost quests" or tostring(sorted)
    return infos
end

function API.RedrawTracker()
    if QuestObjectiveTracker and QuestObjectiveTracker.MarkDirty then
        attempt("QuestObjectiveTracker:MarkDirty", QuestObjectiveTracker.MarkDirty, QuestObjectiveTracker)
    end
end

-- sorter(infos) -> a reordered copy, or nil to hand the tracker back to
-- Blizzard. False when this client has no such tracker.
function API.SetTrackerSort(sorter)
    if not (QuestObjectiveTracker and QuestObjectiveTrackerMixin
        and type(QuestObjectiveTrackerMixin.BuildQuestWatchInfos) == "function") then
        errors["Tracker"] = "QuestObjectiveTracker or its BuildQuestWatchInfos is missing"
        return false
    end
    trackerSorter = sorter
    QuestObjectiveTracker.BuildQuestWatchInfos = sorter and sortedWatchInfos or nil
    API.RedrawTracker()
    return true
end
```

- [ ] **Step 3: Run tests, luacheck and lua-language-server**

Expected: `118 passed, 0 failed`; luacheck `0 warnings / 0 errors`; lua-language-server "no problems found" / `[]`.

- [ ] **Step 4: Commit**

```bash
git add GoblinThings/API.lua .luacheckrc .luarc.json
git commit -m "API: wrap the quest tracker's list builder with a sorter that falls back to Blizzard's list

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Core wiring, checklist, docs

**Files:**
- Modify: `GoblinThings/Core.lua`, `docs/manual-test-checklist.md`, `README.md`, `CLAUDE.md`

**Interfaces:**
- Consumes: `TrackerSort.IsSlot`, `TrackerSort.Assign`, `TrackerSort.Tiers`, `TrackerSort.Order`; `API.TrackerFacts`, `API.SetTrackerSort`, `API.RedrawTracker`, `API.Later`; `Options.IsTab`.
- Produces: `Core.Tab() -> string`, `Core.SetTab(name)`; `Core.Set` applies no-repeats for sort slots and turns the tracker sort on or off.

- [ ] **Step 1: Add TrackerSort to Core's locals**

Change the top of `GoblinThings/Core.lua` to:

```lua
local API, Camera, Cinematics, Decline, Features, Hands, MinimapButton, Options, TrackerSort, Vendor, Window =
    ns.API, ns.Camera, ns.Cinematics, ns.Decline, ns.Features, ns.Hands, ns.MinimapButton, ns.Options,
    ns.TrackerSort, ns.Vendor, ns.Window
```

- [ ] **Step 2: Add the tracker sort section**

Insert before `function Core.Get(key)`:

```lua
-- ---- quest tracker sort ----

local trackerInstalled = false  -- the wrapper is in place; until it is, the tracker is never touched

-- Blizzard's { { quest, index } ... } in our order.
local function sortTracker(infos)
    local entries = {}
    for i, info in ipairs(infos) do
        local facts = API.TrackerFacts(info.quest)
        entries[i] = { level = facts.level, finished = facts.finished, onMap = facts.onMap, index = i, info = info }
    end
    local out = {}
    for i, entry in ipairs(TrackerSort.Order(entries, TrackerSort.Tiers(db().features))) do
        out[i] = entry.info
    end
    return out
end

-- On when any tier is set. Off removes the wrapper only if it was ever put
-- in, so a player who never sorts never has the tracker touched.
local function applyTrackerSort()
    local on = #TrackerSort.Tiers(db().features) > 0
    if on then
        trackerInstalled = API.SetTrackerSort(sortTracker)
    elseif trackerInstalled then
        API.SetTrackerSort(nil)
        trackerInstalled = false
    end
end
```

- [ ] **Step 3: Teach Core.Set the no-repeats rule and the tab**

Replace `Core.Set` with:

```lua
-- Called from the window's clicks and drags, so it carries its own guard.
function Core.Set(key, value)
    guard("Settings", function()
        if not Features.Valid(Features.ByKey(key), value) then
            return
        end
        if key == Camera.KEY then
            API.SetCVar(Camera.CVAR, Camera.Text(Camera.Clamp(value)))
        elseif TrackerSort.IsSlot(key) then
            for slot, slotValue in pairs(TrackerSort.Assign(db().features, key, value)) do
                db().features[slot] = slotValue
            end
            applyTrackerSort()
        else
            db().features[key] = value
        end
        Window.Refresh(Core)
    end)
end

function Core.Tab()
    return db().tab
end

function Core.SetTab(name)
    guard("Window", function()
        if Options.IsTab(name) then
            db().tab = name
            Window.Refresh(Core)
        end
    end)
end
```

- [ ] **Step 4: Follow the player's zone, and install at login**

Insert before the `-- ---- /gt ----` line:

```lua
-- "This zone" changes with the map: redraw after Blizzard's own zone handler.
API.OnEvents({ "ZONE_CHANGED", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED_INDOORS" }, function()
    if trackerInstalled then
        API.Later(API.RedrawTracker)
    end
end)
```

In the `PLAYER_LOGIN` handler, after `MinimapButton.Create(Core)` add:

```lua
        applyTrackerSort()
```

- [ ] **Step 5: Add the sort to the probe**

In `commands.probe`, before the `for name, message in pairs(API.Errors()) do` loop add:

```lua
    local tiers = TrackerSort.Tiers(db().features)
    say("Probe: tracker sort " .. (#tiers > 0 and table.concat(tiers, ", ") or "off")
        .. (trackerInstalled and " (installed)." or " (not installed)."))
```

- [ ] **Step 6: Run tests, luacheck and lua-language-server**

Expected: `118 passed, 0 failed`; both linters clean.

- [ ] **Step 7: Update the checklist**

In `docs/manual-test-checklist.md`, replace the line `- [ ] The window shows five gold headers (Quests, Vendors, Social, Camera, Cinematics), eight rows, the` and its continuation line with:

```markdown
- [ ] **Full client restart** first (TrackerSort.lua is new in the TOC).
- [ ] The window shows five tabs (Quests, Vendors, Social, Camera, Cinematics); the open one is gold.
      Each tab shows only its rows; the window keeps the same height on every tab; the "Show
      minimap button" check and "Hold Shift at an NPC or vendor to skip." stay under every tab.
- [ ] Close and reopen, and `/reload`: the window opens on the tab last used.
- [ ] The Quests tab: two checks, a gold "Tracker sort" sub-header, rows 1st / 2nd / 3rd each
      reading None | Level | Finished | This zone with every word fully visible, and the dim note
      "All None = Blizzard's order (fully after /reload)". Nothing overlaps.
```

Add a section after `## Quests`:

```markdown
## Tracker sort

- [ ] With all three on None, `/gt probe` says "tracker sort off (not installed)" and the tracker is
      in Blizzard's order.
- [ ] 1st: Level alone: tracked quests run lowest level to highest.
- [ ] 1st: Finished alone: finished quests (the "?" ones) on top.
- [ ] 1st: This zone alone: quests in your zone on top; ride into another zone and the order follows.
      Also step indoors or into a sub-zone and back.
- [ ] 1st: This zone, 2nd: Finished, 3rd: Level: this zone's finished quests, then this zone's open
      quests lowest level first, then other zones the same way.
- [ ] No repeats: with 1st on Level, pick Level for 2nd: 1st goes back to None.
- [ ] Set any tier, then all three back to None: the tracker goes back to Blizzard's order now, and
      `/gt probe` says "off (not installed)". `/reload`: still Blizzard's order.
- [ ] `/reload` with a tier set: the tracker comes up already sorted.
- [ ] With a tier set, through accepting, finishing, turning in and abandoning quests, the tracker
      never goes blank or drops a quest, and `/gt probe` shows no "Tracker sort threw" line (a sort
      that errors or loses quests falls back to Blizzard's list and records why there).
- [ ] **Release gate:** `/console taintLog 1`, `/reload`, set a tier, track a quest with a usable
      item. Use it from the tracker out of combat, then in combat: no "blocked" or "AddOn tried to
      call a protected function". Then `/console taintLog 0`. If blocked, send the end of
      `Logs\taint.log`; the feature does not ship as built.
```

- [ ] **Step 8: Update README and CLAUDE.md**

In `README.md`, add this row to the switch table after the "Auto turn-in quests" row:

```markdown
| Tracker sort | Orders the quest tracker by up to three tiers: Level (lowest first), Finished first, This zone first | Off |
```

and change the first line under the title's tagline to:

```markdown
Small goblin conveniences for **WoW Forever** (interface 16001), set once in one tabbed window and forgotten.
```

In `CLAUDE.md`:
- Replace `Eight quality-of-life switches in one Goblin-look window: auto accept and turn in quests, auto sell` and the two lines after it (through `Spec: ...design.md`.) with:

```markdown
Quality-of-life switches in one tabbed Goblin-look window: auto accept and turn in quests, a tiered
quest tracker sort, auto sell junk, auto repair, decline duels, decline guild invites, camera
distance past Blizzard's 2.0, and skipping cinematics. Specs:
`docs/superpowers/specs/2026-10-13-goblin-things-design.md` and
`docs/superpowers/specs/2026-10-13-tracker-sort-and-tabs-design.md` (its Tabs replace the first's Window).
```

- Replace the TOC order line with:

```markdown
TOC load order is `API, Features, Hands, Vendor, Camera, Cinematics, Decline, TrackerSort, Look, Options, Window, MinimapButton, Core`.
```

- Replace item 1 of "How it fits together" with:

```markdown
1. `Features.LIST` is every switch as data: key, label, section (its tab), optional group (a
   sub-header), control (`check`, `slider`, `choice`) and default; `Features.NOTES` gives a tab its
   dim note. The window builds its tabs and rows from it; `Options.Init` stores every feature with a
   default. The camera has none: the game's own CVar is its store.
```

- Add an item 5:

```markdown
5. The tracker sort (`TrackerSort`, pure) wraps `QuestObjectiveTracker.BuildQuestWatchInfos` via
   `API.SetTrackerSort` only while a tier is set; all None removes the wrapper, and a player who
   never sorts never has the tracker touched.
```

- [ ] **Step 9: Commit**

```bash
git add GoblinThings/Core.lua docs/manual-test-checklist.md README.md CLAUDE.md
git commit -m "Core: tiered tracker sort with no repeats, zone redraws and the remembered tab; checklist and docs

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 10: Hand over**

Tell the owner: **full client restart** (TrackerSort.lua is new in the TOC), then walk the checklist's window and Tracker sort sections, release gate included.
