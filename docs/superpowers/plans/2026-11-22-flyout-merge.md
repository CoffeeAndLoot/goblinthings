# Goblin Flyout folded into Goblin Things: implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Goblin Things carries every Goblin Flyout feature behind a Flyout tab, so Flyout can retire.

**Architecture:** Flyout's pure modules (`Kinds`, `Professions`, `Items`, `Travel`) and its
`Macro` and `Bar` come over as they are; its game calls join `API.lua`; `Features.LIST` grows one
`flyout` row per kind, built from `Kinds.LIST`; the window gets a `flyout` row control (icon plus
the existing choice switch); `Core` gains Flyout's setup, events and slash words, yielding to a
still-enabled Flyout.

**Tech Stack:** Lua 5.1 (WoW Forever, interface 16001); tests through `lupa`; luacheck and
lua-language-server.

**Spec:** `docs/superpowers/specs/2026-11-22-flyout-merge-design.md`. Source addon: `D:\GoblinFlyout`.

## Global constraints

- `API.lua` is the only file calling Blizzard game APIs, each through `call()`/`attempt()`.
- Pure modules touch no Blizzard global at file load; every new module goes in both of
  `test/run.lua`'s hand-kept lists, every new `test/test_*.lua` in the suites list.
- No Blizzard templates or art in the window; colours only from `Look.COLOUR`. **Exception:** the
  bars (`Bar.lua`) keep `ActionButtonTemplate, SecureActionButtonTemplate`,
  `SecureHandlerBaseTemplate` and `SecureHandlerClickTemplate`.
- `Bar.TOGGLE_SNIPPET`, `Bar.CLOSE_PRE`, `Bar.CLOSE_POST` contain no `{`, `}` or `function`.
- Frame names `GoblinFlyout<Label>`, `GoblinFlyout<Label>Bar`, macro names and bodies: unchanged.
- Nothing secure is created, changed or shown by insecure code in combat.
- Suite, luacheck and lua-language-server at zero; commit after each task as `Area: plain sentence`;
  no push, no tag. A TOC change needs a full client restart: say so in docs and checklist.

Commands (from the repo root, CLAUDE.md):

```
python -c "import lupa.lua51 as L; lua=L.LuaRuntime(unpack_returned_tuples=True); print(lua.execute(open('test/run.lua').read().replace('os.exit(harness.run())','return harness.run()')))"
```

```
$env:PATH = "$HOME\AppData\Local\Programs\Lua\bin;$env:PATH"
$env:LUA_PATH = "$HOME\.luarocks\share\lua\5.4\?.lua;$HOME\.luarocks\share\lua\5.4\?\init.lua;;"
lua "$HOME\.luarocks\share\lua\5.4\luacheck\main.lua" GoblinThings test --no-color --no-cache
lua-language-server --check D:\GoblinThings --checklevel=Warning --check_out_path=$env:TEMP\gt-luals.json
```

## Review focus

- Goblin Flyout still enabled beside Goblin Things: no toggle, bar or `/gf` of ours is made, one
  chat line says to disable it, and the Flyout tab's icons still pick up the (shared) macros.
  Pinned in Task 6 by reading the setup code path (no unit test reaches `C_AddOns`).
- A `/reload` in combat: setup waits for `PLAYER_REGEN_ENABLED`; nothing secure is touched first
  (Task 6, as Flyout's `trySetup`).
- A saved layout that is junk (`"diagonal"`) resets to `horizontal` (Task 2's Options test).
- A command word and a kind key spelt the same: the command wins (Task 6's slash parser order).
- The window with ten tabs: every tab name fits at 82 px (`Window.WIDTH` 843; Task 5's test and a
  checklist line).

---

### Task 1: the pure kinds, professions, items and travel

**Files:**
- Create: `GoblinThings/Kinds.lua`, `GoblinThings/Professions.lua`, `GoblinThings/Items.lua`,
  `GoblinThings/Travel.lua` (from `D:\GoblinFlyout\GoblinFlyout\<same>.lua`)
- Create: `test/test_kinds.lua`, `test/test_professions.lua`, `test/test_items.lua`,
  `test/test_travel.lua` (from `D:\GoblinFlyout\test\<same>.lua`)
- Modify: `GoblinThings/GoblinThings.toc`, `test/run.lua`

**Interfaces:**
- Produces: `Kinds.LIST`, `Kinds.KEYS`, `Kinds.ByKey(key)`, `Kinds.Matching(item, names)`,
  `Kinds.CONSUMABLE`; each kind row gains `feature` (`"flyout" .. key:sub(1,1):upper() .. key:sub(2)`,
  so `flyoutPotions`, `flyoutFooddrink`) beside Flyout's `toggle` and `empty`.
  `Professions.Entries(raws)`, `Items.Entries(raws, kind, names)`, `Travel.Entries(known, carried)`,
  `Travel.SpellIDs()`, `Travel.ItemIDs()`: Flyout's, unchanged.

- [ ] **Step 1: Copy the four modules and four suites**, changing only the module header comments
  that name Flyout's spec to name this spec, and the `loadfile` paths in `test/run.lua`.
- [ ] **Step 2: Add the `feature` key in `Kinds.lua`'s derivation loop** and a `test_kinds` case:
  `Kinds.ByKey("potions").feature == "flyoutPotions"`, `Kinds.ByKey("fooddrink").feature ==
  "flyoutFooddrink"`, every `feature` unique.
- [ ] **Step 3: TOC**: `Kinds.lua` after `API.lua`; `Professions.lua, Items.lua, Travel.lua` after
  `QuestPlates.lua`. `test/run.lua`: the same four in `modules` (Kinds first), the four suites.
- [ ] **Step 4: Run the suite.** Expected: the previous count plus Flyout's cases, 0 failed.
- [ ] **Step 5: Commit** `Flyout: the kinds, professions, items and travel modules come over as pure data`.

### Task 2: one Features row per kind

**Files:**
- Modify: `GoblinThings/Features.lua`, `GoblinThings/Options.lua` (the 225 comment),
  `test/test_features.lua`, `test/test_options.lua`

**Interfaces:**
- Consumes: `ns.Kinds.LIST` (Task 1).
- Produces: rows `{ key = kind.feature, label = kind.label, section = "Flyout", control = "flyout",
  kind = kind.key, default = "horizontal", choices = Features.LAYOUTS, labels = Features.LAYOUT_LABELS }`
  appended after the XP rows; `Features.LAYOUTS = { "horizontal", "vertical" }`,
  `Features.LAYOUT_LABELS = { horizontal = "Horizontal", vertical = "Vertical" }`;
  `Features.Valid` accepts `flyout` as `choice`; `Features.NOTES.Flyout`.

- [ ] **Step 1: Tests.** `test_features`: the key string gains
  `" flyoutProfessions flyoutFood flyoutDrink flyoutFooddrink flyoutPotions flyoutElixirs flyoutBandages flyoutScrolls flyoutTravel"`;
  sections `"... Map XP Flyout"`, counts `"... 8 7 9"`; a case: `Features.ByKey("flyoutPotions")`
  has `control "flyout"`, `kind "potions"`, `label "Potions"`, `default "horizontal"`,
  `Valid(f, "vertical")` true, `Valid(f, "diagonal")` false; `sections[10].note ==
  "Drag an icon onto an action bar to place its button; right-click it to change the icon."`.
  `test_options`: `Options.Init(nil).features.flyoutPotions == "horizontal"`;
  `Options.Init({ features = { flyoutPotions = "vertical", flyoutFood = "diagonal" } })` keeps
  `vertical`, resets `flyoutFood` to `horizontal`.
- [ ] **Step 2: Run; expected FAIL** on the key list and the new cases.
- [ ] **Step 3: Implement** in `Features.lua`: the two constants, a `for _, kind in ipairs(ns.Kinds.LIST)`
  append after the literal LIST, `Valid`'s `choice` branch also for `"flyout"`, the note. In
  `Options.lua` the `DEFAULT_ANGLE` comment reads `-- degrees round the minimap: bottom-left-ish`.
- [ ] **Step 4: Run; expected PASS.**
- [ ] **Step 5: Commit** `Flyout: one Features row per kind on a Flyout tab, its layout the switch`.

### Task 3: the game calls

**Files:**
- Modify: `GoblinThings/API.lua` (a section `-- ---- flyout bars (from Goblin Flyout's API.lua) ----`
  before the screen section), `.luacheckrc`, `.luarc.json`

**Interfaces:**
- Produces: `API.InCombat()`, `API.RawProfessions()`, `API.MacroButtons(macroIndex)`,
  `API.FindMacro(test)`, `API.AccountMacrosFull()`, `API.CreateMacro(name, icon, body)`,
  `API.PickupMacro(index)`, `API.MacroName(index)`, `API.MacroIcon(index)`,
  `API.OpenMacroEditor(index)`, `API.RenameMacro(index, name)`, `API.BagItems()`,
  `API.FoodDrinkNames()`, `API.ItemCount(itemID)`, `API.ItemCooldown(itemID)`,
  `API.SpellCooldown(spellID)`, `API.KnownSpells(ids)`, `API.Carried(ids)`, `API.SnippetsWork()`:
  Flyout's bodies, `call()` where Flyout checked `if not Fn then`. New
  `API.AddOnLoaded(name) -> boolean`: `call("IsAddOnLoaded", C_AddOns and C_AddOns.IsAddOnLoaded, name) == true`.

- [ ] **Step 1: Port the functions**; `RawProfessions` calls `ns.Professions.Indices`.
- [ ] **Step 2: Globals** in both lint files: `InCombatLockdown, GetProfessions, GetProfessionInfo,
  C_SpellBook, C_TradeSkillUI, ActionButtonUtil, GetActionInfo, GetNumMacros, GetMacroInfo,
  Constants, CreateMacro, PickupMacro, EditMacro, ShowMacroFrame, MacroFrame, MacroEditButton_OnClick,
  MacroEditButton, SecureHandlerExecute, C_AddOns` (and `_G` if luacheck flags it; it is std).
- [ ] **Step 3: luacheck and lua-language-server: zero.** (No unit test reaches API.)
- [ ] **Step 4: Commit** `API: Goblin Flyout's calls for professions, macros, bags, spells and snippets`.

### Task 4: macros and the bar engine

**Files:**
- Create: `GoblinThings/Macro.lua`, `GoblinThings/Bar.lua` (from Flyout), `test/test_macro.lua`,
  `test/test_bar.lua` (from Flyout)
- Modify: `GoblinThings/GoblinThings.toc`, `test/run.lua`, `.luacheckrc`, `.luarc.json`

**Interfaces:**
- Consumes: `ns.API` (Task 3), `ns.Kinds`, `ns.Items`, `ns.Professions`, `ns.Travel` (Task 1).
- Produces: Flyout's `Macro.*` and `Bar.*` unchanged, except `Bar`'s "Put the … button on an
  action bar (/gt <key>)." message. `Bar.TogglePlain(kind, layout)`,
  `Bar.BeforeSecureClick(kind, layout)`, `Bar.EnterCombat(layoutOf)`, `Bar.LeaveCombat(layoutOf)`,
  `Bar.MakePlainToggle(kind, onClick)`, `Bar.MakeSecureToggle(kind, onPreClick)`, `Bar.LinkSecure()`,
  `Bar.SetEscape(on)`, `Bar.Close(kind)`, `Bar.CloseAll()`, `Bar.CloseUnlessMouseOver()`, `Bar.Refresh()`.

- [ ] **Step 1: Copy both files and both suites**; spec references and the `/gf` → `/gt` in the
  message; `test_bar` has no path to change; `test_macro` fakes `ns.API` and needs none.
- [ ] **Step 2: TOC** `Macro.lua, Bar.lua` after `Travel.lua`; `test/run.lua` both lists. Globals:
  `SecureHandlerWrapScript` (and any luacheck names).
- [ ] **Step 3: Run the suite; expected PASS.** luacheck and lua-language-server: zero.
- [ ] **Step 4: Commit** `Flyout: the macro and bar engine come over, the bars keeping Blizzard's action buttons`.

### Task 5: the Flyout tab's row

**Files:**
- Modify: `GoblinThings/Window.lua`, `test/test_window.lua`

**Interfaces:**
- Consumes: `core.PickUp(kind)`, `core.EditIcon(kind)`, `core.Icon(kind)` (Task 6),
  `ns.Kinds.ByKey`.
- Produces: `Window.WIDTH = 843`; `L.ICON = 30`; a `flyoutControl(core, r, feature)` maker in
  `MAKERS.flyout` returning `{ icon = texture, buttons = choiceControl(...).buttons }`;
  `Window.Refresh` sets `c.icon:SetTexture(core.Icon(ns.Kinds.ByKey(c.feature.kind)))` when `c.icon`.

- [ ] **Step 1: Test.** `test_window`: the WIDTH case reads
  `math.floor((Window.WIDTH - 2 * L.PAD + 9) / 10) == 82` ("ten tabs at 82 px").
- [ ] **Step 2: Run; expected FAIL** (766 gives 74).
- [ ] **Step 3: Implement.** `WIDTH = 843` and its comment. `flyoutControl`: a `Button` of `L.ICON`
  at `("LEFT", r, "LEFT", 4, 0)`; texture inset 1 px, `SetTexCoord(0.08, 0.92, 0.08, 0.92)`;
  `Look.Outline(icon, Look.COLOUR.line)`; a `HIGHLIGHT` `Look.Texture(..., Look.COLOUR.gold, 0.25)`
  over the art; `RegisterForClicks("LeftButtonUp", "RightButtonUp")`, `RegisterForDrag("LeftButton")`;
  `OnDragStart` and left `OnClick` → `core.PickUp(kind)`, right → `core.EditIcon(kind)`; tooltip
  `kind.label` / "Drag to an action bar." / "Right-click to change its icon."; then the choice
  buttons from `choiceControl`. Refresh draws the icon before the `c.buttons` branch (the control
  has both).
- [ ] **Step 4: Run; expected PASS.** Lints zero.
- [ ] **Step 5: Commit** `Window: a Flyout tab row, its icon to drag and its Horizontal | Vertical switch`.

### Task 6: Core wires it up

**Files:**
- Modify: `GoblinThings/Core.lua`, `.luacheckrc`, `.luarc.json` (`SLASH_GOBLINFLYOUT1`, `SLASH_GOBLINFLYOUT2`)

**Interfaces:**
- Consumes: Tasks 1 to 5.
- Produces: `Core.Layout(kindKey)`, `Core.PickUp(kind) -> boolean`, `Core.EditIcon(kind)`,
  `Core.Icon(kind)`; `Core.Set` on a `flyout` feature saves then `Bar.Close(kind)`; the slash
  parser `word, rest`; commands `layout`, each kind key (after the fixed words, only when no
  command has that name); `/gt probe`'s Flyout lines; `setup()` and `trySetup` as Flyout's, plus the
  yield; `/gf` and `/goblinflyout` registered in `setup` when not yielding.

- [ ] **Step 1: Implement**, following Flyout's `Core.lua` for the bodies:
  - `Core.Layout(key)`: `Core.Get(Kinds.ByKey(key).feature)`.
  - `Core.Set`: `elseif feature.control == "flyout" then db().features[key] = value;
    Bar.Close(Kinds.ByKey(feature.kind))` before the generic branch.
  - `Core.PickUp`, `Core.EditIcon`, `Core.Icon`: Flyout's.
  - `slash(msg)`: `local word, rest = string.match(msg or "", "^%s*(%S*)%s*(.-)%s*$")`;
    `command(string.lower(rest or ""))`.
  - `commands.layout(rest)`: Flyout's, flipping through `Features.LAYOUTS` (the other of the two)
    via `Core.Set(kind.feature, other)`, saying `kind.label .. " layout: " .. label .. "."`.
  - Kind commands: `for _, kind in ipairs(Kinds.LIST) do if not commands[kind.key] then … end end`.
  - `HELP`: "Commands: /gt, /gt <kind>, /gt layout <kind>, /gt minimap, /gt probe. Kinds: …".
  - Probe: Flyout's profession, food/drink, consumable, macro, snippet and travel lines, placed
    after the bag-direction lines; `snippets` is the setup's result (nil until setup).
  - `setup()`: if `API.AddOnLoaded("GoblinFlyout")` then `say("Goblin Flyout is still enabled;
    its buttons now live in Goblin Things. Disable Goblin Flyout and /reload.")` and return;
    else Flyout's body (snippets, Tidy, toggles, LinkSecure, SetEscape, the snippets-fail line)
    and then `SLASH_GOBLINFLYOUT1 = "/gf"; SLASH_GOBLINFLYOUT2 = "/goblinflyout";
    SlashCmdList.GOBLINFLYOUT = SlashCmdList.GOBLINTHINGS`.
  - `trySetup` on `PLAYER_LOGIN` and `PLAYER_REGEN_ENABLED`, once, out of combat (Flyout's).
  - Events: `GLOBAL_MOUSE_DOWN` → `Bar.CloseUnlessMouseOver`; `ACTIONBAR_PAGE_CHANGED` →
    `Bar.CloseAll`; `PLAYER_REGEN_DISABLED` → `Bar.EnterCombat(Core.Layout)`;
    `PLAYER_REGEN_ENABLED` → `Bar.LeaveCombat(Core.Layout)`; `UPDATE_MACROS` → `Window.Refresh(Core)`;
    `BAG_UPDATE_DELAYED, BAG_UPDATE_COOLDOWN, SPELL_UPDATE_COOLDOWN` → `Bar.Refresh`. Labels
    "Close on click", "Close", "Combat", "Window", "Counts".
- [ ] **Step 2: Suite, luacheck, lua-language-server: zero.**
- [ ] **Step 3: Commit** `Core: the flyout buttons, their bars, /gt <kind> and the yield to a still-enabled Goblin Flyout`.

### Task 7: docs and the checklist

**Files:**
- Modify: `README.md`, `CLAUDE.md`, `docs/manual-test-checklist.md`, `GoblinThings/GoblinThings.toc` (Notes)
- Create: `images/flyout-meals.png`, `images/flyout-professions.png` (copies of
  `D:\GoblinFlyout\images\gallery\2-food-and-drink.png` and `3-professions.png`)

- [ ] **Step 1: README.** Nine `Flyout` rows in the table (Starts: Horizontal), each "What it does"
  from Flyout's "The buttons" table with its combat note; a "Flyout buttons" section (getting
  started, the window row, in combat, good to know) condensed from Flyout's README; the two images
  with raw `master` URLs; `/gt <kind>` and `/gt layout <kind>` in the commands table and `/gf` as an
  alias.
- [ ] **Step 2: CLAUDE.md.** Intro: Flyout folded in 2026-11-22, this spec listed. Rules: the bars'
  template exception, the snippet-text rule, the kept frame and macro names. How it fits together:
  the new TOC order; items for `Kinds.LIST`/the Flyout rows, macros by body, plain and secure
  bars, rebuild moments, the yield and `/gf`. Client facts: Flyout's (secure snippets work,
  consumable subclasses, profession facts, `/gf probe` → `/gt probe`). Deploy: the Flyout junction
  must go once Flyout is disabled.
- [ ] **Step 3: Checklist.** Section "Goblin Flyout folded in (2026-11-22)": full client restart
  (six new TOC files); ten tabs fit; the Flyout tab's nine rows, icons, tooltips, drag, right-click,
  switch; Flyout's plain, Travel, secure and combat checks rewritten for `/gt`; the yield line and
  working icons with Flyout still enabled; a Flyout-era button opening its bar with Flyout disabled;
  `/gf` and `/gt layout potions`; `/gt probe`'s new lines. All unticked.
- [ ] **Step 4: TOC Notes** gain the flyout clause.
- [ ] **Step 5: Commit** `Docs: the Flyout tab in the README, CLAUDE.md and the checklist`.

### Task 8: the whole

- [ ] **Step 1:** suite, luacheck and lua-language-server once more; `git status` clean.
- [ ] **Step 2:** the hand-over note to the owner in the shared notes folder: what needs an
  in-game check (the checklist section), and the proposal for the Flyout repo and listings.
