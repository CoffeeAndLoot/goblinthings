# Quest marks on nameplates

2026-11-21. Short design: one switch, one pure module, one drawing file, two API reads.

## Intent

The owner wants to pick targets without hovering each one: a mob that counts toward one of
their quests wears a small mark above its nameplate and the number of that mob still to go.

## What the game gives (verified in source, `D:\wow-api\1.60.1.70291`, not yet in game)

- Blizzard's Forever nameplates (`Blizzard_NamePlates`) carry no quest marker of their own:
  Retail dropped it in Shadowlands. Nothing to switch on.
- `NAME_PLATE_UNIT_ADDED` / `NAME_PLATE_UNIT_REMOVED` hand over the unit token
  (`nameplate1`...), and `C_NamePlate.GetNamePlateForUnit(unit)` gives that unit's plate frame, a
  plain frame an addon may parent a child to. The forbidden plates (other players in some
  content) are not returned to an addon; nothing is drawn for them.
- `C_QuestLog.UnitIsRelatedToActiveQuest(unit)` answers yes or no only.
- The count lives in the unit's tooltip data: `C_TooltipInfo.GetUnit(unit)` returns lines typed
  `Enum.TooltipDataLineType.QuestTitle` (17) and `QuestObjective` (8); an objective line has
  `leftText` ("Kobold Vermin slain: 4/10") and `completed`. Blizzard's own tooltip rule
  (`TooltipDataRules.QuestObjective`) reads `completed` to pick its tick icon. The figures come
  out of the text.
- `QUEST_LOG_UPDATE` and `UNIT_QUEST_LOG_CHANGED` fire when progress changes.

**Unverified in game:** whether Forever's server sends typed quest lines for mobs (Classic shows
them on hover, so the data is there; the typing is the question), and whether their text is
readable rather than secret. The probe prints the target's lines so the owner can settle both.

## Goals

- A mark above the nameplate of every shown mob with an unfinished objective in the player's
  quest log, kill or item alike, with the smallest number still to go across its objectives.
- The mark follows progress: a kill or a pickup updates every shown mark.
- One switch on the Quests tab, `questPlates`, "Quest marks on nameplates", default on.

## Non-goals

- Friendly quest NPCs (the game marks turn-ins already), players, pets.
- Which quest it is: one mark, one number, no title.
- Anything on the tooltip, the map or the tracker.

## Approaches

1. **A child frame per nameplate, fed by the unit's tooltip data (chosen).** The frame is the
   addon's own look; the count is the game's own figure from the data it already builds for
   the unit. This is how every nameplate addon does it.
2. **Count from the quest log alone.** `C_QuestLog.GetQuestObjectives` gives each objective's
   `numFulfilled` / `numRequired`, but nothing ties a unit to an objective; the tooltip is the only
   link. Rejected.
3. **A line per objective, stacked.** The owner chose one mark and the smallest number:
   nameplates are small and the question is "is this one worth hitting".

## Design

- **`QuestPlates.lua` (pure, new, before `Look` in the TOC; full client restart).**
  `QuestPlates.Remaining(lines)` takes `{ { kind = "title" | "objective" | "other", text =,
  completed = } ... }` and answers the smallest kills left among objective lines: `b - a` from the
  first `a/b` in the text when positive; `1` for an objective line with no figures that is not
  completed (a "slay the named one" objective); completed lines and lines with `a >= b` count for
  nothing. `nil` when no line counts, when `lines` is not a table, or when every line is finished.
  A malformed line is skipped, never an error.
- **`API.NamePlate(unit)`**: the plate frame from `C_NamePlate.GetNamePlateForUnit`, or nil.
  **`API.UnitQuestLines(unit)`**: nil when `C_QuestLog.UnitIsRelatedToActiveQuest` answers false;
  otherwise the tooltip's lines as `QuestPlates.Remaining` wants them, kinds mapped from
  `Enum.TooltipDataLineType` (a missing enum means every line is `"other"`), text through
  `API.Readable` (a secret text is nil, so that line counts as having no figures). nil when
  the game gives no data. Both through `call()`.
- **`PlateMarks.lua` (draws, decides nothing; new, after `KillsReadout`).** One small mouse-off
  frame per plate frame, built on first use and kept (the game recycles plate frames), anchored
  `BOTTOM` to the plate's `TOP`: a gold square (`Look.COLOUR`, a dark outline) and the number in
  white with an outline beside it, size 12, so it reads on any ground. `PlateMarks.Show(plate, n)`,
  `PlateMarks.Hide(plate)`, `PlateMarks.HideAll()`. The plate's own scale carries the mark with it.
- **`Core`**: keeps `plates[unit] = frame` from the two nameplate events; marks a unit on add and
  re-marks every known unit on `QUEST_LOG_UPDATE` / `UNIT_QUEST_LOG_CHANGED`, once per frame
  through `API.Later` (the log event comes in bursts). Switch off: `HideAll` and no reads; back
  on: re-mark. Everything behind `guard("Quest marks", ...)`.
- **The probe**: "quest marks: N plate(s) known, M marked; target related yes/no; target lines:
  [objective] Kobold Vermin slain: 4/10 (completed false); ..." so the owner can paste what
  Forever sends.

## Checklist (added to `docs/manual-test-checklist.md`)

Full restart first (two new files). A quest mob's plate shows the mark and the right number; a
kill lowers every shown mark; a finished objective drops the mark; a mob of no quest, a friendly
NPC and a player show nothing; two quests on one mob show the smaller number; untick clears at
once, tick brings them back; the probe's lines pasted.
