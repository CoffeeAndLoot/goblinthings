# Quest marks on nameplates: implementation plan

**Goal:** a mark above a quest mob's nameplate with the smallest number of that mob still to go.

**Architecture:** `QuestPlates` (pure) turns a unit's typed tooltip lines into one number;
`API` reads the plate frame and the lines; `PlateMarks` draws one child frame per plate;
`Core` routes the nameplate and quest-log events and the switch.

**Spec:** `docs/superpowers/specs/2026-11-21-quest-marks-on-nameplates-design.md`. Built in this
session, task by task, the owner having said "go ahead".

## Global constraints

- `API.lua` is the only file calling Blizzard game APIs, each through `call()`/`attempt()`.
- Pure modules touch no Blizzard global at file load; both new files go in `test/run.lua`'s lists.
- No Blizzard templates or art; colours only from `Look.COLOUR`. Never a guessed API or enum
  value: the line kinds come from `Enum.TooltipDataLineType` at call time.
- An unknown answer from the game means do nothing.
- Suite, luacheck and lua-language-server at zero; commit after each task.

## Review focus

- A plate the game recycles for another unit: the old mark must not linger (Core hides on
  `NAME_PLATE_UNIT_REMOVED`; PlateMarks keys by plate frame, so the next `Show` overwrites).
- The switch off mid-fight: every mark gone at once, and no tooltip reads while off.
- A quest-log burst (ten `QUEST_LOG_UPDATE`s in one frame): one re-mark, not ten.
- A forbidden plate or a missing `C_NamePlate`: nothing drawn, no error.
- Secret or odd tooltip text: the line counts as no figures; `1` only when not completed.

## Task 1: `QuestPlates.lua` (pure) and `test/test_questplates.lua`

- `QuestPlates.Remaining(lines) -> number | nil`, lines `{ { kind, text, completed } ... }`.
  Pattern `(%d+)%s*/%s*(%d+)`, first match; `b - a` when `> 0`; a `"objective"` line with no
  match and `completed ~= true` is `1`; min over lines; nil when none counts or `lines` is not a
  table.
- Tests: "4/10" is 6; two objectives 4/10 and 7/8 is 1; a completed 10/10 counts for nothing;
  an incomplete objective with no figures is 1, a completed one nothing; title and other lines
  never count; nil text, a non-table line and a non-table `lines` give nil or are skipped.
- TOC after `Kills.lua`; `test/run.lua` both lists.

## Task 2: `API.NamePlate`, `API.UnitQuestLines`, `test/test_api_plates.lua`

- `API.NamePlate(unit) -> frame | nil` via `C_NamePlate.GetNamePlateForUnit(unit)`; a table or nil.
- `API.UnitQuestLines(unit) -> lines | nil`: `C_QuestLog.UnitIsRelatedToActiveQuest(unit)` false
  -> nil; `C_TooltipInfo.GetUnit(unit)` with `.lines` a table -> each
  `{ kind, text = API.Readable(line.leftText), completed = line.completed == true }`, kind
  `"title"` / `"objective"` / `"other"` by `Enum.TooltipDataLineType.QuestTitle` /
  `.QuestObjective`; else nil.
- Tests against stand-in globals: related false gives nil; related true with two typed lines
  gives the kinds and texts; no `C_TooltipInfo` gives nil; a missing Enum makes every line other.
- `C_NamePlate`, `C_TooltipInfo` in `.luacheckrc` and `.luarc.json`.

## Task 3: `PlateMarks.lua`, the switch, `Core.lua`, the probe

- `Features.LIST`: `{ key = "questPlates", label = "Quest marks on nameplates", section = "Quests",
  control = "check", default = true }` after `questDiamond`. `test_features` row counts if any.
- `PlateMarks.Show(plate, n)`, `PlateMarks.Hide(plate)`, `PlateMarks.HideAll()`, `PlateMarks.Count()`
  (marks shown, for the probe). Mark: frame parented to the plate, mouse off, anchored
  `BOTTOM` to plate `TOP` with a 2-unit gap; a 10-unit gold square (`Look.COLOUR.gold` or the
  closest the palette has, `Look.Outline` in the dark rim colour) and `Look.Text(..., 12, "text",
  "OUTLINE")` 3 units to its right; sized to fit. Kept per plate in a weak-keyed table.
- `Core`: `plates[unit]`; `markUnit(unit)`; `remarkAll()` through `API.Later` with a pending
  flag; events `NAME_PLATE_UNIT_ADDED`, `NAME_PLATE_UNIT_REMOVED`, `QUEST_LOG_UPDATE`,
  `UNIT_QUEST_LOG_CHANGED`; `Core.Set` on `questPlates` -> `HideAll` or `remarkAll`. Guard label
  "Quest marks".
- Probe lines as the spec says, reading `"target"` through `API.UnitQuestLines`.
- TOC after `KillsReadout.lua`; `run.lua` module list.

## Task 4: Docs

- README row under Quests after the quest diamond; TOC `## Notes` gets "mark quest mobs' nameplates".
- Checklist section "Quest marks on nameplates (2026-11-21)" with the spec's list, full restart first.
- CLAUDE.md: load order, a point 9 in How it fits together, the spec in Docs.
