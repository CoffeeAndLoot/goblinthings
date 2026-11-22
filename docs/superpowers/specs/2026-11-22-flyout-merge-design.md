# Goblin Flyout folded into Goblin Things — Design

Date: 2026-11-22
Client: WoW Forever, interface 16001. Source reference: `D:\wow-api\1.60.1.70291\Interface\AddOns`.
Source addon: `D:\GoblinFlyout` (spec `docs/superpowers/specs/2026-10-12-goblin-flyout-design.md` there;
its Nomenclature names kind, button, bar, entry, host, toggle, plain/secure).

## Intent

The owner keeps two WoW Forever addons and wants one. Goblin Flyout's nine macro buttons (each
flying out a bar of Blizzard action buttons above its slot: professions, food, drink, food & drink,
potions, elixirs, bandages, scrolls, travel; potions, elixirs, bandages and scrolls working in
combat) move into Goblin Things, so one window, one minimap button and one release pipeline carry
everything, and Goblin Flyout can be retired.

## Goals

- Every Flyout behaviour works from Goblin Things exactly as it did from Flyout.
- A player who already has Flyout's buttons on their bars keeps them working with no action but
  installing Goblin Things and disabling Flyout.
- Goblin Things' rules hold: `API.lua` the only Blizzard caller, pure modules under test, the
  game's own look, one `Features.LIST` row per switch, docs and checklist kept.

## Non-goals

- Changing how a bar looks or behaves. The bars stay Blizzard action buttons (see Constraints).
- Migrating Flyout's SavedVariable. It holds nine Horizontal/Vertical picks plus the minimap and
  window spots, and once Flyout is disabled the game never loads it, so Goblin Things cannot read
  it. The player picks a layout again if they ever changed one. Nothing else is lost.
- Flyout's own art (the GF disc, its gallery cards). Goblin Things' goblin is the one icon.
- Touching `D:\GoblinFlyout`. What happens to that repo and its listings is the owner's call; the
  hand-over note proposes a course (below, "After the merge").

## Anti-goals

- A placed button going dead. The toggle frame names (`GoblinFlyoutPotions` …) are the bodies of
  macros players already have (`/click GoblinFlyoutPotions`); they are kept as they are.
- Two addons fighting over the same frame names and `/gf` while both are enabled.

## Constraints

- **The bars keep Blizzard's templates.** Every entry is an `ActionButtonTemplate,
  SecureActionButtonTemplate` button, every bar a `SecureHandlerBaseTemplate` frame, every secure
  toggle a `SecureHandlerClickTemplate` button. The combat behaviour rests on this, and the bars
  must match the stock bar they open from. This is the second written exception to the
  no-Blizzard-templates rule (after the map atlases), written into CLAUDE.md. It is the look rule
  that is excepted, not the API rule: `API.lua` still makes every game call.
- Flyout's snippet-text rule carries over: `Bar.TOGGLE_SNIPPET`, `Bar.CLOSE_PRE`, `Bar.CLOSE_POST`
  may not contain `{`, `}` or the word `function`.
- Nothing secure is created, changed or shown by insecure code in combat.
- No libraries; an unknown answer from the game means do nothing.

## Approaches considered

Where the nine kinds land in the Goblin Things window:

1. **A "Flyout" tab, each row an icon to drag plus a Horizontal | Vertical switch** (chosen; the
   owner's "yes", 2026-11-22). Flyout's window becomes one page. Nothing a Flyout user has today
   is lost: drag-to-place, the right-click icon picker, the layout switch. Cost: one new row
   control and a tenth tab.
2. A "Flyout" tab of plain Horizontal | Vertical choice rows, placing a button only by
   `/gt <kind>`. Reuses the existing choice control, no new window code, but drag-to-place and the
   icon picker are gone.
3. Spreading the kinds across existing tabs. Dropped: Potions and Travel have no natural home.

## Design

### Files

New in `GoblinThings/`, ported from Flyout with the namespace and paths changed and nothing else
unless noted:

| File | From Flyout | Notes |
|---|---|---|
| `Kinds.lua` (pure) | `Kinds.lua` | adds `kind.feature`, the `Features.LIST` key (below) |
| `Professions.lua` (pure) | `Professions.lua` | unchanged |
| `Items.lua` (pure) | `Items.lua` | unchanged |
| `Travel.lua` (pure) | `Travel.lua` | unchanged |
| `Macro.lua` | `Macro.lua` | unchanged; calls `ns.API` only when called |
| `Bar.lua` | `Bar.lua` | unchanged; the "Put the X button on an action bar" message says `/gt` |

Changed: `API.lua` (Flyout's calls added), `Features.lua`, `Options.lua`, `Window.lua`, `Core.lua`,
the TOC, `test/run.lua`, `.luacheckrc`, `.luarc.json`, README, CLAUDE.md, the checklist.

TOC order becomes `API, Kinds, Features, Hands, Vendor, Trainer, Camera, Cinematics, Decline,
Accept, Loot, TrackerSort, MapData, MapInfo, MapPins, Kills, QuestPlates, Professions, Items,
Travel, Macro, Bar, Look, Options, Window, MinimapButton, MapReadout, MapEntrances, KillsReadout,
PlateMarks, Core`. `Kinds` precedes `Features` because `Features.LIST` is built from it. Six new
files in the TOC: a **full client restart**, not `/reload`.

### Features

`Features.LIST` gains one row per kind, appended after the XP rows, generated from `Kinds.LIST`:

```
{ key = kind.feature, label = kind.label, section = "Flyout", control = "flyout", kind = kind.key,
  default = "horizontal", choices = { "horizontal", "vertical" },
  labels = { horizontal = "Horizontal", vertical = "Vertical" } }
```

`kind.feature` is `"flyout"` plus the kind key with its first letter upper-cased
(`flyoutPotions`, `flyoutFooddrink`). `Features.Valid` treats `flyout` as it treats `choice`.
`Features.NOTES.Flyout` is "Drag an icon onto an action bar to place its button; right-click it to
change the icon." The row's stored value is the layout, so the layout switch is the row's switch:
a kind has no on/off, as in Flyout, because a kind costs nothing until its button is on a bar.

### Options

Nothing new: the flyout rows have defaults, so `Options.Init` stores them like any choice.
`Options.DEFAULT_ANGLE` stays 195 (the comment about clearing Flyout's 225 goes).

### Window

- Width: ten tabs at 82 px, `Window.WIDTH = 843` (the test's formula with `n = 10`).
- A fourth control maker, `flyout`: a 30 px icon button at the row's left where a check would sit
  (`LEFT + 4`), then the existing `choiceControl` at the right for Horizontal | Vertical. The icon:
  a texture inset 1 px with `SetTexCoord(0.08, 0.92, 0.08, 0.92)`, a `Look.Outline` in `line`, a gold
  25% hover texture; left-click and drag call `core.PickUp(kind)`, right-click `core.EditIcon(kind)`;
  tooltip "<Label> / Drag to an action bar. / Right-click to change its icon." `controls[key].icon`
  keeps the texture; `Window.Refresh` sets it from `core.Icon(kind)` so a picked icon shows, and
  the control's `buttons` are lit as a choice's are. Every other consumer of `Features.LIST`
  (`Options.Init` through `Features.Valid`, `Core.Get` reading `db.features`, `Window.PageHeight`
  counting rows) already handles a row with a default and a value.
- Flyout's gold bracket joining Food & Drink to Food and Drink is dropped (builder's call: there
  is no gutter beside the icon in this row layout, and the row order already tells the story).

### Core

- `Core.Layout(kindKey)`: `Core.Get(kind.feature)`. `Core.Set` on a `flyout` feature saves the
  value then `Bar.Close(kind)` (a layout change closes that kind's bar, out of combat).
- `Core.PickUp(kind)`, `Core.EditIcon(kind)`, `Core.Icon(kind)`: Flyout's, verbatim.
- Setup (Flyout's `setup`): waits until out of combat (`PLAYER_LOGIN`, then `PLAYER_REGEN_ENABLED`
  until it has run), checks `API.SnippetsWork()`, `Macro.Tidy` per kind, makes each toggle (secure
  where `kind.secure` and snippets work, else plain), `Bar.LinkSecure()`, `Bar.SetEscape(true)`,
  says once when snippets fail.
- **Yielding to a still-enabled Goblin Flyout**: at setup, if `API.AddOnLoaded("GoblinFlyout")`
  (`C_AddOns.IsAddOnLoaded`, AddOnsDocumentation.lua), the whole of setup is skipped (no toggles,
  bars, `Macro.Tidy`, `LinkSecure`, `SetEscape`, snippet check or `/gf` alias) and one line says
  "Goblin Flyout is still enabled; its buttons now live in Goblin Things. Disable Goblin Flyout
  and /reload." The Flyout tab still shows; its icons and `/gt <kind>` still work, since the
  macros are the same macros and `Macro` finds them by body. The bar events stay registered and
  do nothing: `Bar` has no bars. Without this both addons would own the same global frame names
  and the same `/gf`.
- A layout changed while a bar is open in combat is saved at once and applies at the bar's next
  rebuild (`Bar.Close` does nothing in combat), as in Flyout.
- Events, as Flyout's: `GLOBAL_MOUSE_DOWN` → `Bar.CloseUnlessMouseOver`; `ACTIONBAR_PAGE_CHANGED` →
  `Bar.CloseAll`; `PLAYER_REGEN_DISABLED` → `Bar.EnterCombat(Core.Layout)`; `PLAYER_REGEN_ENABLED` →
  `Bar.LeaveCombat(Core.Layout)`; `UPDATE_MACROS` → `Window.Refresh`; `BAG_UPDATE_DELAYED`,
  `BAG_UPDATE_COOLDOWN`, `SPELL_UPDATE_COOLDOWN` → `Bar.Refresh`. Each behind `guard`.
- Slash: `/gt <kind>` puts that button on the cursor; `/gt layout <kind>` flips its layout and
  says so. The slash parser takes a `rest` word; a command word wins over a kind key of the same
  spelling (none collide today). `HELP` lists them and the kind keys. `/gf` and `/goblinflyout`
  become aliases of `/gt` (`SLASH_GOBLINFLYOUT1/2` and `SlashCmdList.GOBLINFLYOUT`, registered at
  setup and **only when Goblin Flyout is not loaded**: the chat frame re-imports `SlashCmdList`
  on every command sent (ChatFrameEditBox.lua `ImportAllListsToHash`), so a late registration
  takes, and two owners of one slash word would be settled by hash order).
- `/gt probe` gains Flyout's lines: professions with their spells and pick, food and drink spell
  names, every bag consumable with subclass, spell and kinds, each kind's macro and visible slot
  count, whether snippets work, the travel entries.

### API

Added from Flyout's `API.lua`, each through `attempt()`/`call()`, under a section
"flyout bars (from Goblin Flyout's API.lua)": `InCombat`, `RawProfessions`, `MacroButtons`,
`FindMacro`, `AccountMacrosFull`, `CreateMacro`, `PickupMacro`, `MacroName`, `MacroIcon`,
`OpenMacroEditor`, `RenameMacro`, `BagItems`, `FoodDrinkNames`, `ItemCount`, `ItemCooldown`,
`SpellCooldown`, `KnownSpells`, `Carried`, `SnippetsWork`; and new `AddOnLoaded(name)`.
`ScreenPixelsPerUnit`, `CursorPosition` and `OnEvents` are already there. New WoW globals go in
`.luacheckrc` and `.luarc.json`.

### Names kept from Flyout

Toggle frames `GoblinFlyout<Label>`, bar frames `GoblinFlyout<Label>Bar`, entry buttons
`…Entry<n>`, the `goblinflyout` scratch attribute in `SnippetsWork`, macro names
(Prof, Food, Drink, Meals, Potion, Elixir, Aid, Scroll, Travel) and bodies. These are what a
player's existing macros and keybinds point at.

### Tests

Ported, paths changed: `test_kinds`, `test_items`, `test_professions`, `test_travel`,
`test_macro`, `test_bar`. `test_kinds` adds the `feature` keys. `test_features` grows the key list,
the section names ("… XP Flyout"), counts ("… 7 9") and the Flyout note; `test_window` reads ten
tabs; `test_options` checks a flyout default and a junk layout resetting. Flyout's `test_options`
(Options.Init on `layouts`, `Options.Other`) and `test_look` have nothing to port.

### Docs

- README: a "Flyout" block in the table, one row per kind (Starts: Horizontal), a short section
  on the buttons and combat from Flyout's README, `/gt <kind>` and `/gt layout <kind>` in the
  commands table, and Flyout's two bar screenshots copied in as `images/flyout-meals.png` and
  `images/flyout-professions.png` (the bars look the same; its window shot does not).
- CLAUDE.md: the templates exception and snippet rule in Rules, the merged TOC order, new "How it
  fits together" items for the kinds, macros, bars and the yield, Flyout's Client facts merged in,
  and the sibling line rewritten (Flyout folded in 2026-11-22).
- Checklist: a section "Goblin Flyout folded in (2026-11-22)" with Flyout's in-game checks
  rewritten for Goblin Things, all unticked (what the owner saw in Flyout is Flyout's record), plus
  the new ones: the Flyout tab, ten tabs fitting, the yield line with Flyout still enabled, a
  placed Flyout-era button still opening its bar, `/gf` opening the window.
- The TOC's Notes gain "action bar buttons that fly out your professions, food, drink, potions
  and ways home".

## After the merge (proposal to the owner, not built here)

A last Goblin Flyout release whose login line says it has moved into Goblin Things, then the
repo archived and the Wago and CurseForge listings marked as moved. Goblin Things' listings need
their hand-edited descriptions updated (CLAUDE.md's release rule). The owner decides.

## Open to the builder

- Exact row geometry of the flyout control (icon size and offsets), within the 40 px row.
- Where Flyout's probe lines sit inside `/gt probe`.
