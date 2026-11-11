# Kills to Level Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A ghosted number in a screen corner showing how many more kills, like the last ten, it takes to level.

**Architecture:** The map readout's shape. `Kills.lua` is pure arithmetic (sample ring, kills left, corner anchor, kill-line pattern); `API.lua` gains the XP reads; `KillsReadout.lua` draws one FontString and decides nothing; `Core.lua` routes four events and redraws on setting changes. Seven rows in `Features.LIST` make the XP tab.

**Tech Stack:** Lua 5.1 (WoW Forever, interface 16001), no libraries. Tests through `lupa` with `test/harness.lua`.

**Spec:** `docs/superpowers/specs/2026-11-11-kills-to-level-design.md`. Read it and `CLAUDE.md` first.

## Global Constraints

- Blizzard source of truth is `D:\wow-api\1.60.1.70291\Interface\AddOns`. Never guess an API, event or template name.
- `API.lua` is the only file that calls Blizzard game APIs, each through `attempt()` / `call()`.
- Pure modules touch no Blizzard global at file load; `test/run.lua`'s two hand-kept lists (modules in TOC order, suites) must gain every new module and suite or it silently does not run.
- No Blizzard frame templates; colours only from `Look.COLOUR`.
- An unknown answer from the game means show nothing.
- Blizzard's XP bar is never touched.
- luacheck and lua-language-server stay at zero warnings; a new WoW global goes in both `.luacheckrc` and `.luarc.json`.
- Every UI or behaviour change adds unticked entries to `docs/manual-test-checklist.md`. Only the owner ticks them.
- Commit after each task: `Area: plain sentence`, ending with `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`. Do not push. Do not bump the TOC version.
- Run the whole suite (there is no filter):

```
python -c "import lupa.lua51 as L; lua=L.LuaRuntime(unpack_returned_tuples=True); print(lua.execute(open('test/run.lua').read().replace('os.exit(harness.run())','return harness.run()')))"
```

## Review Focus

1. **XP text the addon may not read** (secret, nil, not a string): no sample, no error, number unchanged. Tests in Task 3 (`API.Readable`) and Task 6 (`Kills.Sample`).
2. **A mob whose name holds digits or pattern characters** ("Unit 7", "Mok'thar (Elite)"): the sample is the XP figure, not the first number in the line. Test in Task 6.
3. **Level-up and odd XP readings** (XP at or past the level's max, max of 0, a nil): hidden, never 0, negative or `inf`. Test in Task 2.
4. **A hand-edited or stale SavedVariable** (`killsCorner = "middle"`, `killsSize = 500`, `killsFont = "skurri"`): each falls back to its default. Test in Task 1.
5. **A font file that will not load**: the number still shows, in Friz. `Kills.Font` test in Task 2; the `SetFont` fallback is an in-game check in Task 4.

---

## File Structure

| File | Change | Responsibility |
|---|---|---|
| `GoblinThings/Features.lua` | modify | the seven `kills*` rows, the XP note |
| `GoblinThings/Look.lua` | modify | `COLOUR.ghost` |
| `GoblinThings/Window.lua` | modify | `WIDTH` 684, `Window.Shown()`, tell core when it hides |
| `GoblinThings/Kills.lua` | create | pure: ring, kills left, anchor, font, kill-line pattern |
| `GoblinThings/API.lua` | modify | `PlayerXP`, `CanEarnXP`, `Readable`, `GlobalText` |
| `GoblinThings/KillsReadout.lua` | create | the FontString; draws what it is given |
| `GoblinThings/Core.lua` | modify | events, redraw, probe lines, samples |
| `GoblinThings/GoblinThings.toc` | modify | `Kills.lua` after `MapInfo.lua`; `KillsReadout.lua` after `MapReadout.lua` |
| `test/test_kills.lua`, `test/test_api_xp.lua` | create | suites |
| `test/run.lua`, `test/test_features.lua`, `test/test_options.lua`, `test/test_window.lua` | modify | lists and pinned values |
| `README.md`, `CLAUDE.md`, `docs/manual-test-checklist.md` | modify | the switch's row, the load order, the checks |

---

### Task 1: The XP tab's rows

**Files:**
- Modify: `GoblinThings/Features.lua`, `GoblinThings/Look.lua`, `GoblinThings/Window.lua:15`
- Test: `test/test_features.lua`, `test/test_options.lua`, `test/test_window.lua`

**Interfaces:**
- Produces: feature keys `killsLeft` (check, default `false`), `killsCorner` (choice: `topLeft`, `topRight`, `bottomLeft`, `bottomRight`; labels "Top left", "Top right", "Bottom left", "Bottom right"; default `topLeft`), `killsX` and `killsY` (slider 0-400 step 5, default 20, format `"%d"`), `killsAlpha` (slider 5-100 step 5, default 30, format `"%d%%"`), `killsSize` (slider 8-48 step 1, default 18, format `"%d"`), `killsFont` (choice: `friz`, `arial`, `morpheus`; labels "Friz", "Arial", "Morpheus"; default `friz`). All `section = "XP"`, appended to `Features.LIST` in that order with labels "Kills to level", "Corner", "Offset across", "Offset down / up", "Faintness", "Size", "Font".
- Produces: `Features.NOTES.XP = "Kills like your last ten; hidden until your first kill"`; `Look.COLOUR.ghost` (white, `hex(0xFF, 0xFF, 0xFF)`); `Window.WIDTH = 684`.

- [ ] **Step 1: Write the failing tests**

In `test/test_features.lua`: extend the pinned key list (line 10) with the seven keys in order; change the sections assertions to

```lua
h.eq(table.concat(names, " "), "Quests Vendors Loot Social Camera Cinematics Map XP")
h.eq(table.concat(counts, " "), "8 3 1 6 1 1 1 7")
```

and add

```lua
h.it("Kills to level is off by default, top left, 30% and Friz", function()
    h.eq(Features.ByKey("killsLeft").default, false)
    h.eq(Features.ByKey("killsCorner").default, "topLeft")
    h.eq(Features.ByKey("killsAlpha").default, 30)
    h.eq(Features.ByKey("killsFont").default, "friz")
    h.eq(Features.SliderText(Features.ByKey("killsAlpha"), 30), "30%")
    h.eq(Features.SliderText(Features.ByKey("killsX"), 0), "0")
end)
```

In `test/test_options.lua`:

```lua
h.it("a kills setting the window could not have written falls back to its default", function()
    local f = Options.Init({ features = { killsCorner = "middle", killsSize = 500, killsFont = "skurri",
        killsAlpha = 0, killsX = 40 } }).features
    h.eq(f.killsCorner, "topLeft")
    h.eq(f.killsSize, 18)
    h.eq(f.killsFont, "friz")
    h.eq(f.killsAlpha, 30)
    h.eq(f.killsX, 40)
end)
```

In `test/test_window.lua`:

```lua
h.it("is wide enough for eight tabs at 82 px", function()
    h.eq(math.floor((Window.WIDTH - 2 * L.PAD + 7) / 8), 82)
end)
```

- [ ] **Step 2: Run the suite; expect these to fail** (key list, section names, nil feature, width 72).
- [ ] **Step 3: Add the rows, the note, `COLOUR.ghost` and the width.** Update `Window.WIDTH`'s comment to eight tabs.
- [ ] **Step 4: Run the suite; expect all pass.** `Window.Height` must be unchanged (the XP page, 7 rows and a note, is shorter than Quests).
- [ ] **Step 5: Run luacheck and lua-language-server (commands in `CLAUDE.md`); zero warnings.**
- [ ] **Step 6: Commit** `Kills: the XP tab's seven rows, and a window wide enough for eight tabs`

---

### Task 2: Kills.lua, the arithmetic

**Files:**
- Create: `GoblinThings/Kills.lua`, `test/test_kills.lua`
- Modify: `test/run.lua` (module after `MapInfo`, suite after `test_mapinfo.lua`), `GoblinThings/GoblinThings.toc` (after `MapInfo.lua`)

**Interfaces:**
- Produces:
  - `Kills.MAX = 10`, `Kills.SAMPLE = 37`
  - `Kills.Keep(list, item, max) -> list`: appends, then drops from the front until `#list <= max`. Same table returned.
  - `Kills.Add(samples, xp) -> samples`: `Keep(samples, xp, Kills.MAX)` when `xp` is a number above 0 (and not NaN); otherwise unchanged.
  - `Kills.Left(xp, xpMax, samples) -> integer | nil`: `ceil((xpMax - xp) / mean(samples))`; nil when either is not a number, `xpMax <= 0`, `xp >= xpMax`, `xp < 0` or `samples` is empty.
  - `Kills.Anchor(corner, x, y) -> point, dx, dy`: `topLeft -> "TOPLEFT", x, -y`; `topRight -> "TOPRIGHT", -x, -y`; `bottomLeft -> "BOTTOMLEFT", x, y`; `bottomRight -> "BOTTOMRIGHT", -x, y`; anything else as `topLeft`.
  - `Kills.FONTS = { friz = "Fonts\\FRIZQT__.TTF", arial = "Fonts\\ARIALN.TTF", morpheus = "Fonts\\MORPHEUS.ttf" }`; `Kills.Font(key) -> path` (unknown key gives the Friz path).
  - `Kills.Text(left, preview) -> string | nil`: `tostring(left)` when `left` is a number; else `"37"` when `preview`; else nil.

- [ ] **Step 1: Write `test/test_kills.lua`** (shape of `test/test_mapinfo.lua`: `return function(h, loaded) local Kills = loaded.Kills ...`):

```lua
h.describe("Kills.Add", function()
    h.it("keeps the last ten", function()
        local s = {}
        for i = 1, 12 do Kills.Add(s, i) end
        h.eq(#s, 10); h.eq(s[1], 3); h.eq(s[10], 12)
    end)
    h.it("ignores what is not XP", function()
        local s = { 50 }
        Kills.Add(s, 0); Kills.Add(s, -5); Kills.Add(s, "80"); Kills.Add(s, nil); Kills.Add(s, 0 / 0)
        h.eq(#s, 1)
    end)
end)
h.describe("Kills.Left", function()
    h.it("is XP still needed over the average kill, rounded up", function()
        h.eq(Kills.Left(1000, 2000, { 100, 120, 80 }), 10)
        h.eq(Kills.Left(1000, 2000, { 300 }), 4)
        h.eq(Kills.Left(1999, 2000, { 500 }), 1)
    end)
    h.it("is nothing without a kill or a sane XP reading", function()
        h.eq(Kills.Left(1000, 2000, {}), nil)
        h.eq(Kills.Left(nil, 2000, { 100 }), nil)
        h.eq(Kills.Left(1000, nil, { 100 }), nil)
        h.eq(Kills.Left(0, 0, { 100 }), nil)
        h.eq(Kills.Left(2000, 2000, { 100 }), nil)
        h.eq(Kills.Left(2500, 2000, { 100 }), nil)
        h.eq(Kills.Left(-1, 2000, { 100 }), nil)
    end)
end)
h.describe("Kills.Anchor", function()
    h.it("pushes in from each corner", function()
        local function a(c) return table.concat({ Kills.Anchor(c, 20, 30) }, " ") end
        h.eq(a("topLeft"), "TOPLEFT 20 -30")
        h.eq(a("topRight"), "TOPRIGHT -20 -30")
        h.eq(a("bottomLeft"), "BOTTOMLEFT 20 30")
        h.eq(a("bottomRight"), "BOTTOMRIGHT -20 30")
        h.eq(a("middle"), "TOPLEFT 20 -30")
    end)
end)
h.describe("Kills.Font and Kills.Text", function()
    h.it("an unknown face is Friz", function()
        h.eq(Kills.Font("morpheus"), "Fonts\\MORPHEUS.ttf")
        h.eq(Kills.Font("skurri"), "Fonts\\FRIZQT__.TTF")
        h.eq(Kills.Font(nil), "Fonts\\FRIZQT__.TTF")
    end)
    h.it("the count, a sample while tuning, or nothing", function()
        h.eq(Kills.Text(12, false), "12")
        h.eq(Kills.Text(12, true), "12")
        h.eq(Kills.Text(nil, true), "37")
        h.eq(Kills.Text(nil, false), nil)
    end)
    h.it("every font choice in Features has a file", function()
        for _, key in ipairs(loaded.Features.ByKey("killsFont").choices) do
            h.truthy(Kills.FONTS[key], key)
        end
    end)
end)
```

- [ ] **Step 2: Add the module and suite to `test/run.lua`; run; expect a hard failure (file missing).**
- [ ] **Step 3: Write `Kills.lua`** (header comment naming the spec, `local _, ns = ...`, `ns.Kills = Kills`, `return Kills`; no Blizzard global).
- [ ] **Step 4: Run the suite; expect all pass. Add `Kills.lua` to the TOC after `MapInfo.lua`. luacheck and LuaLS at zero.**
- [ ] **Step 5: Commit** `Kills: the sample ring, kills left and the corner arithmetic`

---

### Task 3: The game reads

**Files:**
- Modify: `GoblinThings/API.lua` (a new `---- experience ----` section before `---- screen ----`), `.luacheckrc`, `.luarc.json` (new globals: `UnitXP`, `UnitXPMax`, `IsXPUserDisabled`, `GameRulesUtil`, `issecretvalue`), `test/run.lua`
- Create: `test/test_api_xp.lua`

**Interfaces:**
- Produces:
  - `API.PlayerXP() -> xp, xpMax | nil`: `UnitXP("player")`, `UnitXPMax("player")` (`UnitDocumentation.lua:3474`, `:3489`); nil unless both are numbers.
  - `API.CanEarnXP() -> boolean`: false when `IsXPUserDisabled()` or `GameRulesUtil.IsPlayerAtEffectiveMaxLevel()` answers true (both used in `Blizzard_StatusTrackingBar/Shared/ExpBar.lua:135`); a missing or throwing call does not disqualify.
  - `API.Readable(text) -> string | nil`: nil when `issecretvalue(text)` is true (`Blizzard_SharedXMLBase/SecureTypes.lua`) or `text` is not a string. Ask `issecretvalue` first: a secret value must not be passed to `type` comparisons that branch on its content. A client without `issecretvalue` reads every string.
  - `API.GlobalText(name) -> string | nil`: `_G[name]` when it is a string.

- [ ] **Step 1: Write `test/test_api_xp.lua`** in the shape of `test/test_api_map.lua` (`fresh()` sets the stand-in globals then loads `API.lua` into a new `ns`; nil every global at the end):

```lua
h.it("PlayerXP is the two numbers, or nothing", function()
    UnitXP, UnitXPMax = function(u) h.eq(u, "player"); return 450 end, function() return 2000 end
    local xp, max = fresh().PlayerXP()
    h.eq(xp .. " " .. max, "450 2000")
    UnitXPMax = function() return nil end
    h.eq(fresh().PlayerXP(), nil)
    UnitXP = nil
    h.eq(fresh().PlayerXP(), nil)
end)
h.it("CanEarnXP is false at max level or with XP off, true when the game says neither", function()
    IsXPUserDisabled, GameRulesUtil = nil, nil
    h.eq(fresh().CanEarnXP(), true)
    IsXPUserDisabled = function() return true end
    h.eq(fresh().CanEarnXP(), false)
    IsXPUserDisabled = function() return false end
    GameRulesUtil = { IsPlayerAtEffectiveMaxLevel = function() return true end }
    h.eq(fresh().CanEarnXP(), false)
    GameRulesUtil = { IsPlayerAtEffectiveMaxLevel = function() error("boom") end }
    h.eq(fresh().CanEarnXP(), true)
end)
h.it("Readable gives a plain string and nothing for a secret or a non-string", function()
    issecretvalue = function(v) return v == "hidden" end
    local API = fresh()
    h.eq(API.Readable("Boar dies, you gain 45 experience."), "Boar dies, you gain 45 experience.")
    h.eq(API.Readable("hidden"), nil)
    h.eq(API.Readable(45), nil)
    h.eq(API.Readable(nil), nil)
    issecretvalue = nil
    h.eq(fresh().Readable("hidden"), "hidden")
end)
h.it("GlobalText is a global string by name, nil when missing or not a string", function()
    GT_TEST_FORMAT = "%s dies."
    local API = fresh()
    h.eq(API.GlobalText("GT_TEST_FORMAT"), "%s dies.")
    h.eq(API.GlobalText("GT_NO_SUCH"), nil)
    GT_TEST_FORMAT = 5
    h.eq(API.GlobalText("GT_TEST_FORMAT"), nil)
    GT_TEST_FORMAT = nil
end)
```

- [ ] **Step 2: Add the suite to `test/run.lua`; run; expect failures (nil functions).**
- [ ] **Step 3: Implement the four functions with `call()`.**
- [ ] **Step 4: Run the suite; all pass. Add the globals to `.luacheckrc` and `.luarc.json`; both linters at zero.**
- [ ] **Step 5: Commit** `API: the player's XP, whether more can be earned, and readable chat text`

---

### Task 4: The number on the screen

**Files:**
- Create: `GoblinThings/KillsReadout.lua`
- Modify: `GoblinThings/Core.lua`, `GoblinThings/Window.lua`, `GoblinThings/GoblinThings.toc` (after `MapReadout.lua`), `test/run.lua` (module after `MapReadout`), `docs/manual-test-checklist.md`

**Interfaces:**
- Consumes: `Kills.Left`, `Kills.Anchor`, `Kills.Font`, `Kills.Text`, `API.PlayerXP`, `API.CanEarnXP`, the `kills*` keys, `Look.Text`, `Look.COLOUR.ghost`.
- Produces:
  - `KillsReadout.Draw(text, s)`: `text` nil hides. Otherwise builds on first use (a frame on `UIParent`, strata `BACKGROUND`, `EnableMouse(false)`, one `Look.Text(frame, face, size, "ghost")`, no outline), then applies `s = { corner, x, y, alpha, size, font }`: `SetFont(Kills.Font(s.font), s.size, "")` falling back to `Look.WORDS` when it returns false; `SetAlpha(s.alpha / 100)`; anchored by `Kills.Anchor(s.corner, s.x, s.y)` to `UIParent`'s same point; justified `LEFT` or `RIGHT` to match the corner's side. Touches no Blizzard global at file load.
  - `KillsReadout.Built() -> boolean`.
  - `Window.Shown() -> boolean` (the frame exists and is shown). The window's frame gets an `OnHide` script calling `core.WindowHidden()`.
  - In `Core.lua`: `local samples = {}`; `local function drawKills()` computes `left` (nil unless `killsLeft` is on and `API.CanEarnXP()`; else `Kills.Left(xp, xpMax, samples)`), `preview = killsLeft on and Window.Shown() and Core.Tab() == "XP"`, and calls `KillsReadout.Draw(Kills.Text(left, preview), settings)`; with the switch off it draws nil. `Core.WindowHidden()` and every call site run it behind `guard("Kills", drawKills)`.
  - `drawKills` is called from: `Core.Set` when the key starts with `kills`; `Core.SetTab`; `Core.ToggleWindow`; `Core.WindowHidden`; and `API.OnEvents({ "PLAYER_XP_UPDATE", "PLAYER_LEVEL_UP", "PLAYER_ENTERING_WORLD" }, ...)` (the first two are registered by Blizzard's own `ExpBar.lua`).

- [ ] **Step 1: Write `KillsReadout.lua`; add it to `test/run.lua`'s modules** (it loads, proving it touches no global at load) **and to the TOC.**
- [ ] **Step 2: Add `Window.Shown` and the `OnHide` script; wire `Core.lua` as above** (add `Kills` and `KillsReadout` to the locals taken from `ns`).
- [ ] **Step 3: Run the suite, luacheck and LuaLS; all pass, zero warnings.**
- [ ] **Step 4: Add a "Kills to level" section to `docs/manual-test-checklist.md`**, unticked, opening with "Full client restart first (two new files in the TOC)": the XP tab shows seven rows and the note, and all eight tab names fit; ticking the switch on the XP tab shows a ghosted `37`; it follows each of the four corners; each offset moves it in from the corner; Faintness 5 is barely there and 100 is solid; Size changes it; each of Friz, Arial, Morpheus draws (a face that will not load still shows the number); the mouse clicks through it onto the player portrait; it sits under the character pane and bags; Alt-Z hides it with the UI; closing the window (button, Escape, `/gt`) or leaving the XP tab removes the sample; switch off removes it; `/gt probe` lists the seven keys.
- [ ] **Step 5: Commit** `Kills: the ghosted number, drawn in its corner with a sample while tuning`

---

### Task 5: The probe

**Files:**
- Modify: `GoblinThings/Core.lua`, `docs/manual-test-checklist.md`

**Interfaces:**
- Consumes: `Kills.Keep`, `API.Readable`, `API.GlobalText`, `API.PlayerXP`.
- Produces in `Core.lua`: `local xpLog = {}` (strings, `Kills.Keep(xpLog, line, 12)`) and `local lastXP`. Recorded only while `killsLeft` is on:
  - `CHAT_MSG_COMBAT_XP_GAIN` (`ChatInfoDocumentation.lua:1458`; payload starts with `text`): `'msg "<text>"'`, or `"msg SECRET"` when `API.Readable(text)` is nil.
  - `PLAYER_XP_UPDATE`: `"xp +<gain> (<before> to <now> of <max>)"` from `lastXP` and `API.PlayerXP()`; `"xp <now> of <max>"` when there is no `lastXP` or the level changed (`now < lastXP`). Always update `lastXP`.
- `commands.probe` prints, after the map line: `Probe: XP line N: <line>` for each, or `Probe: no XP lines yet (tick Kills to level, then kill something).`; then one line per name in `COMBATLOG_XPGAIN_FIRSTPERSON`, `COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED`, `COMBATLOG_XPGAIN_EXHAUSTION1`: `Probe: <name> = "<value>"` or `= missing`. These names are candidates being checked, not facts; nothing else may read them yet.

- [ ] **Step 1: Implement the two recorders (behind `guard("Kills", ...)`) and the probe lines.**
- [ ] **Step 2: Run the suite, luacheck and LuaLS.**
- [ ] **Step 3: Add to the checklist's "Kills to level" section**: "With the switch on: kill a mob while rested, kill one unrested, turn in a quest, discover an area, then `/gt probe` and send Claude every `XP line` and the three `COMBATLOG_` lines."
- [ ] **Step 4: Commit** `Kills: /gt probe shows the XP lines the game sends and its format strings`

---

### GATE: the owner runs the client

Stop here. Tell the owner: full client restart, then the checklist's "Kills to level" section, and send back the probe's lines. Task 6 is written from what the game said:

- **The format globals exist and the `msg` lines are readable** (expected): Task 6 as written.
- **Readable lines, no globals**: Task 6 with `Kills.Pattern` given the format reconstructed from the owner's English line; add "English clients only; other languages show nothing" to the checklist and the README row.
- **`msg SECRET`, or kill lines cannot be told from quest or exploration lines**: do not build Task 6. Bring the lines to the owner; the spec's fallback changes what the number means and is his call.

---

### Task 6: The kill rule

**Files:**
- Modify: `GoblinThings/Kills.lua`, `GoblinThings/Core.lua`, `test/test_kills.lua`, `docs/manual-test-checklist.md`

**Interfaces:**
- Produces:
  - `Kills.Pattern(format) -> pattern | nil, index`: turns a kill-line format into a Lua pattern anchored at the start only (rested and group variants append to it). Every magic character is escaped; `%s` and `%N$s` become `(.-)`; `%d` and `%N$d` become `(%d+)`. `index` is which capture is the number. Nil when `format` is not a string or holds no `%d`.
  - `Kills.Sample(text, pattern, index) -> number | nil`: the XP figure when `text` is a string matching `pattern`; else nil.
  - In `Core.lua`: the pattern is built once, lazily, from `API.GlobalText(<the name the probe confirmed>)`. On `CHAT_MSG_COMBAT_XP_GAIN` with the switch on: `Kills.Add(samples, Kills.Sample(API.Readable(text), pattern, index))`, then `drawKills()`.

- [ ] **Step 1: Write the failing tests.** The formats below are test fixtures in the shape Classic used; replace the first with the exact value the probe printed, and add one test per real line the owner sent (kill rested, kill unrested must give their XP; quest and discovery lines must give nil).

```lua
h.describe("Kills.Sample", function()
    local p, i = Kills.Pattern("%s dies, you gain %d experience.")
    h.it("is the XP of a kill line, whatever follows it", function()
        h.eq(Kills.Sample("Mottled Boar dies, you gain 45 experience.", p, i), 45)
        h.eq(Kills.Sample("Mottled Boar dies, you gain 90 experience. (+45 exp Rested bonus)", p, i), 90)
    end)
    h.it("takes the XP, not a number in the mob's name", function()
        h.eq(Kills.Sample("Unit 7 dies, you gain 45 experience.", p, i), 45)
        h.eq(Kills.Sample("Mok'thar (Elite) dies, you gain 120 experience.", p, i), 120)
    end)
    h.it("is nothing for any other line or no line", function()
        h.eq(Kills.Sample("You gain 450 experience.", p, i), nil)
        h.eq(Kills.Sample(nil, p, i), nil)
        h.eq(Kills.Sample("Mottled Boar dies, you gain 45 experience.", nil, nil), nil)
    end)
    h.it("follows a format whose words come in another order", function()
        local q, j = Kills.Pattern("Vous gagnez %2$d points d'experience (%1$s).")
        h.eq(Kills.Sample("Vous gagnez 45 points d'experience (Sanglier).", q, j), 45)
    end)
    h.it("no format, no pattern", function()
        h.eq(Kills.Pattern(nil), nil)
        h.eq(Kills.Pattern("You feel rested."), nil)
    end)
end)
```

- [ ] **Step 2: Run; expect failures (nil functions).**
- [ ] **Step 3: Implement `Kills.Pattern` and `Kills.Sample`; wire the sample into `Core.lua`'s chat handler.**
- [ ] **Step 4: Run the suite, luacheck and LuaLS; all pass, zero warnings.**
- [ ] **Step 5: Add to the checklist** (a `/reload` is enough): the number appears after the first kill; it drops by about one a kill on like mobs; a quest turn-in lowers it and adds no sample; discovering an area the same; after `/reload` it is hidden until a kill; a level-up recomputes it; at max level or with XP turned off it never shows.
- [ ] **Step 6: Commit** `Kills: a kill's XP is read from the game's own line and feeds the count`

---

### Task 7: The docs

**Files:**
- Modify: `README.md`, `CLAUDE.md`

- [ ] **Step 1: README**: one row in the switches table, in its style, for "Kills to level" (XP tab; off by default; what the number means; its five look settings). Note the language limit if the gate chose that branch.
- [ ] **Step 2: `CLAUDE.md`**: add the spec to the docs list; add `Kills` after `MapInfo` and `KillsReadout` after `MapReadout` in the TOC load order line; add `Kills` to item 2's pure modules; add an item 7 describing the readout (pure `Kills`, drawn by `KillsReadout` from `Core`'s `drawKills`, samples session-only, the kill rule and where its format string comes from); record what the probe showed under "Client facts (verified in game)" with the date.
- [ ] **Step 3: Remind the owner** that the Wago description is hand-edited when a switch is added (see `CLAUDE.md`, the release rule). Do not release.
- [ ] **Step 4: Commit** `Docs: kills to level in the README and CLAUDE.md`
