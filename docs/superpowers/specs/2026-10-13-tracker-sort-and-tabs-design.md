# Goblin Things: tracker sort and tabs

Date: 2026-10-13. Status: approved in conversation, awaiting review of this file.
Builds on `2026-10-13-goblin-things-design.md`; its Window section is replaced by the Tabs section here.

## Purpose

The built-in quest tracker lists quests in an order the player cannot change: no dragging, and
re-adding a watch does not move it (verified in game, CLAUDE.md "Client facts"). Goblin Things
lets the player pick the order as up to three tiers, each a step down from the last: sort by the
1st, break ties with the 2nd, then the 3rd. The window gets tabs, because more features are coming.

Success: with "1st: This zone, 2nd: Finished, 3rd: Level", the tracker shows this zone's finished
quests first, then this zone's open quests lowest level first, then every other zone's quests in
the same way; with all three on None the addon does not touch the tracker.

## Tracker sort

### Settings

Three new features in `Features.LIST`, section `Quests`, group `Quest tracker`, control `choice`:

| Key | Label | Choices | Default |
|---|---|---|---|
| `sortFirst` | 1st | none, level, finished, zone | none |
| `sortSecond` | 2nd | none, level, finished, zone | none |
| `sortThird` | 3rd | none, level, finished, zone | none |

Choice labels: None, Level, Finished, This zone. Stored in `GoblinThingsDB.features` like every
other choice; `Options.Init` resets junk to `none`.

**No repeats:** setting a slot to a key another slot holds sets that other slot to `none`. `none`
may repeat.

### The rule (`TrackerSort.lua`, pure)

Each tracked quest is compared as `{ level, finished, onMap, index }`, where `index` is its place
in Blizzard's own sorted list. For each active tier in order:

- `level`: lower first. A quest whose level is unknown (nil) sorts after every known level.
- `finished`: finished (`true`) first; nil counts as not finished.
- `zone`: on the current map (`true`, as Only this zone decides it) first; nil counts as not on the map.

If every active tier ties, the lower `index` wins, so leftover ties keep Blizzard's order. The sort
is stable by construction.

### Hooking the tracker (`API.lua`)

- **The order source**, from `Blizzard_ObjectiveTracker/Blizzard_QuestObjectiveTracker.lua:168-196`:
  `QuestObjectiveTrackerMixin:BuildQuestWatchInfos()` returns `{ { quest, index } ... }`, sorted
  by Blizzard (callings and `overridesSortOrder` quests first, then watch index), and
  `LayoutContents` draws it in that order. The comparison is a file `local`: unreachable.
- **On:** set `QuestObjectiveTracker.BuildQuestWatchInfos` (the module frame from
  `Blizzard_QuestObjectiveTracker.xml:26`) to a wrapper that calls
  `QuestObjectiveTrackerMixin.BuildQuestWatchInfos(self)`, so Blizzard's filtering stays, then
  reorders a copy of the result with the rule and returns it. If anything in the reorder errors,
  the wrapper returns Blizzard's list untouched: a bug here never empties the tracker.
- **Off:** the wrapper stays in and passes Blizzard's list through untouched. XML `mixin=` copies
  the mixin's methods onto the frame, with no `__index` back to the mixin, so setting the field to
  nil would delete the tracker's own method (found in final review, 2026-10-13). The wrapper and its
  taint last until `/reload`; the window says so. A player who never sets a tier never has it put in.
- **Facts per quest:** only the quest's ID is read from the tracker's quest object
  (`quest:GetID()`; the object comes from `Blizzard_ObjectAPI/Mainline/Quest.lua`, which the TOC
  marks mainline though it works on camelot). Level from
  `C_QuestLog.GetInfo(C_QuestLog.GetLogIndexForQuestID(id)).level`, finished from
  `C_QuestLog.IsComplete(id)`, on this map from `C_QuestLog.IsOnMap(id)` (first return). Every call
  through `attempt()`; a missing answer is nil.
- **Redraw:** `QuestObjectiveTracker:MarkDirty()` when any sort setting changes and, while the sort
  is on, on `ZONE_CHANGED`, `ZONE_CHANGED_NEW_AREA` and `ZONE_CHANGED_INDOORS` (after Blizzard's own
  handler, via `API.Later`), so "This zone" follows the player.
- **Setup:** at `PLAYER_LOGIN`, install the wrapper when any tier is set. If `QuestObjectiveTracker`
  or the mixin method is missing, do nothing and keep the reason for `/gt probe`.

### The release gate

Replacing the method taints the tracker's layout and every value it writes (block IDs, the
item button's attributes, POI state), so later clicks on them run tainted. The quest-item button
calls `UseQuestLogSpecialItem` (`Blizzard_ObjectiveTrackerShared.lua:94-104`), whose protection is
not in Forever's docs; a title click opens the map panel. Before release, with `taintLog 1`, out
of combat and in combat: using a quest item, clicking a title, super-tracking from the right-click
menu and clicking a POI button must not be blocked, and the spellbook and bags must open cleanly
after combat. If any is blocked, the feature does not ship as designed.

### Only this zone (added 2026-10-13)

A check, `zoneOnly`, label "Only this zone", group `Quest tracker`, default off. On, the tracker
shows only quests whose map marker is on the player's map: `C_QuestLog.GetQuestsOnMap(map)`
entries with `mapID == map` (in-game 2026-10-13: it also lists a neighbouring zone's quests with
that zone's `mapID`, and `IsOnMap` says yes to them, so `IsOnMap` is not used; no answer keeps a quest), then sorts them by the tiers. A zone with none of your tracked quests shows an
empty tracker (the owner's choice). The wrapper goes in when any tier is set **or** this is on.
The wrapper's safety net accepts a shorter list: it falls back to Blizzard's list only when the
sorter errors or shows a quest Blizzard did not give, or one twice.

### Auto-track new quests (added 2026-10-13)

A check, `autoTrack`, label "Auto-track new quests", in the Quests tab's top rows, default off.
On Forever the only thing that tracks a newly accepted quest is Blizzard's tracker, and only while
the `autoQuestWatch` CVar is "1" (`Blizzard_ObjectiveTracker.lua:35`); another addon had set it to
"0". Ticked, Goblin Things sets that CVar to "1" at every `PLAYER_ENTERING_WORLD` and when ticked;
unticked by a click, to "0"; never ticked, never touched. It does not call `AddQuestWatch` itself:
Blizzard's own handler tracks the quest, so no taint is added to the tracker.

## Tabs

- **Tabs are sections.** `Features.Sections()` gives the tabs in `LIST` order: Quests, Vendors,
  Social, Camera, Cinematics. A feature naming a new section makes a new tab.
- **Groups.** A feature's optional `group` draws a small gold sub-header inside its tab, once,
  above the first row of that group.
- **The strip.** Under the header, one Look button per tab, equal widths across the window, the
  open tab gold and the rest quiet (the style of Goblin Flyout's Horizontal | Vertical switch).
- **One height.** The window is as tall as its tallest tab, so switching tabs never resizes it.
- **The last tab** is remembered account-wide as `GoblinThingsDB.tab`; `Options.Init` keeps it only
  when it names a tab, else the first.
- **Quests tab layout:**
  ```
   Auto accept quests                       [■]
   Auto turn-in quests                      [■]
   Quest tracker
     Only this zone                         [■]
     1st   None | Level | Finished | This zone
     2nd   None | Level | Finished | This zone
     3rd   None | Level | Finished | This zone
     Off and all None = Blizzard's tracker (fully after /reload)
  ```
  The last line is a dim note, shown on the Quests tab only.
- **Footer** (minimap check, Shift hint) stays below the tabs, on every tab.

## Out of scope (YAGNI)

Sorting by name or distance, highest level first, per-character settings, sorting the quest log
itself, and any change to which quests are tracked.

## Testing

- **Unit (lupa):** the comparison per tier, nil handling, ties back to `index`, three tiers
  stacked; no repeats; the three features and their junk reset; `Options.Init` keeping or dropping
  `tab`; the window's height as the tallest tab with group headers.
- **Lint:** luacheck and lua-language-server at zero warnings; new globals (`QuestObjectiveTracker`,
  `QuestObjectiveTrackerMixin`) in both configs.
- **In game (`docs/manual-test-checklist.md`):** each tab draws with nothing overlapping and the
  four sort words fully visible; the window keeps its height across tabs and reopens on the last
  tab; each tier alone and three stacked order the tracker as the rule says; no repeats in the
  window; "This zone" follows a zone change; all None plus `/reload` gives Blizzard's order; and the
  release gate.
