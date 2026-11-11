# Kills to level

2026-11-11. The owner asked for "the amount of kills left to level", first on the XP bar, then
changed his mind: "this really faint font number up in the upper left-hand corner of the screen ...
just barely ghosted". Choices marked **(owner)** are his words; the rest are Claude's calls, stated
so he can overturn them.

## What it does

While grinding, one bare number sits ghosted in a screen corner: how many more kills like the recent
ones it takes to level.

```
kills left = ceil( (XP for this level - XP so far) / average XP of the last 10 kills )
```

- **The number alone** (`37`): no label, no frame, no tooltip, and the mouse passes through it.
- **The last 10 kills, this session.** The owner said "a rolling 5 minutes or something like that";
  Claude proposed last-N kills instead (a time window forgets everything during a vendor run) and
  the owner did not object. The samples are not saved: after a login or /reload the number is hidden
  until the first kill.
- **Only kills feed the average.** Quest and exploration XP lower "XP so far" (the number drops) but
  never count as a kill.
- **Rested XP is not modelled.** A rested kill's sample is what it actually paid, bonus and all, so
  the count jumps a little when rested runs out. Accepted.
- **Hidden when there is nothing to say**: the switch off, no kill sampled yet, the player at max
  level or with XP turned off, or any game answer missing. An unknown answer from the game means
  show nothing.
- It redraws when XP changes, on a level-up and after a loading screen. No per-frame work.

## Settings: a new **XP** tab

Every row uses a control the window already has. The owner asked for a font dropdown, then agreed
to the button row the tracker sort uses, so no new control is built.

| Key | Row | Control | Values | Default |
|---|---|---|---|---|
| `killsLeft` | Kills to level | check | | off |
| `killsCorner` | Corner **(owner)** | choice | Top left, Top right, Bottom left, Bottom right | Top left **(owner)** |
| `killsX` | Offset across **(owner: "offset")** | slider | 0-400, step 5 | 20 |
| `killsY` | Offset down / up | slider | 0-400, step 5 | 20 |
| `killsAlpha` | Faintness **(owner)** | slider | 5-100 %, step 5 | 30 |
| `killsSize` | Size **(owner)** | slider | 8-48, step 1 | 18 |
| `killsFont` | Font **(owner)** | choice | Friz, Arial, Morpheus | Friz |

- Off by default: it puts something new on the screen.
- Both offsets push **in** from the chosen corner, so one pair of numbers suits all four corners.
  Two sliders, not one: clearing the player portrait takes a different nudge across than down.
- The slider is labelled Faintness but stores opacity (30 = 30 % visible), so higher is easier to
  see. If that reads backwards in game, rename the row, not the number.
- **Fonts** are Blizzard's own files only, the ones this build's source names: `Fonts\FRIZQT__.TTF`,
  `Fonts\ARIALN.TTF` (only seen in `GlueFonts.xml`, the login screen's), `Fonts\MORPHEUS.ttf`
  (`Blizzard_Fonts_Shared/Shared/Fonts.xml`). Skurri is not named anywhere in 1.60.1.70291, so it is
  left out. Should a face fail to load, fall back to Friz. No addon or shared-media fonts.
- **Live preview**: every setting redraws the number at once. While the Goblin Things window is
  open on the XP tab with the switch on and no estimate yet, the number shows a sample (`37`) so
  there is something to tune against.
- An eighth tab: widen the window so the tabs keep their 82 px (`Window.WIDTH` 600 to about 684).
- No outline on the text: an outline defeats a ghosted number. White, from a new `Look.COLOUR` key.

## How it fits (the map readout's shape)

- `Features.LIST`: the seven rows above; `Features.NOTES.XP`: a dim line such as "Kills like your
  last ten; hidden until your first kill".
- `Kills.lua` (pure, tested, in `test/run.lua`'s lists): the sample ring (`Add(samples, xp)`, capped
  at 10), `Left(xp, xpMax, samples)` returning the count or nil, the kill rule (below), and the
  corner arithmetic (`Anchor(corner, x, y)` returning a point and signed offsets).
- `API.lua`: `API.PlayerXP()` returning current and max (`UnitXP`, `UnitXPMax`, both documented in
  `UnitDocumentation.lua`), and whether the player can still earn XP
  (`GameRulesUtil.IsPlayerAtEffectiveMaxLevel`, `IsXPUserDisabled`: both used by Blizzard's
  `Shared/ExpBar.lua`). Each through `attempt()`.
- `KillsReadout.lua` (draws, decides nothing): one FontString on a mouse-off frame parented to
  `UIParent` (so it hides with the UI) at a low strata, under every window. No Blizzard template.
- `Core.lua`: routes `CHAT_MSG_COMBAT_XP_GAIN`, `PLAYER_XP_UPDATE`, `PLAYER_LEVEL_UP` and
  `PLAYER_ENTERING_WORLD` behind `guard("Kills", ...)`; `Core.Set` redraws the readout when a
  `kills*` key changes; the events are ignored while the switch is off.
- New files in the TOC (after `MapReadout`): a full client restart, not `/reload`.
- Blizzard's XP bar is never touched.

## Open fact: what a kill looks like (settle in game first)

The source says `CHAT_MSG_COMBAT_XP_GAIN` exists (`ChatInfoDocumentation.lua:1458`) and that its
`text` is not marked `NeverSecret`. It does not say which XP gains fire it, what the text reads, or
whether the text can arrive secret. The global strings that format it are not in the source export,
so no string name may be assumed.

**Build step one is a probe, before any rule is written.** Record the last five
`CHAT_MSG_COMBAT_XP_GAIN` texts (or "secret" when `issecretvalue(text)` says so) beside the `UnitXP`
change that followed, and print them from `/gt probe`. The owner then kills a mob (rested and not),
turns in a quest, discovers an area, and reports the lines. The probe records only while the
`killsLeft` switch is on, like everything else here; the checklist entry says to tick it first.

**Other languages (Claude's call)**: the addon is public, so the rule should not be an English
pattern if the game offers better. The same probe therefore also prints whether the format globals
Classic used for these lines exist on this build and what they hold (`COMBATLOG_XPGAIN_FIRSTPERSON`,
`COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED`, `COMBATLOG_XPGAIN_EXHAUSTION1`; looked up by name in `_G`,
so a missing one reads nil and nothing is assumed). If they exist, the kill pattern is derived from
them at run time and works in any language. If they do not, the rule is written from the owner's
English lines, other languages show nothing (never a wrong number), and the checklist and README
say so.

**The rule Claude expects to write, if the probe agrees**: the event fires for kills with a line
naming the dead mob and the XP gained; quest and exploration XP arrive elsewhere or in a different
shape. A kill's sample is the XP figure in that line. If instead the text is secret or kills cannot
be told apart, stop and bring the probe's lines back to the owner: the fallback (every XP gain made
in combat counts as a kill, sized by the `UnitXP` change) changes what the number means.

## In-game checks (go in `docs/manual-test-checklist.md`)

The probe above; the number appears after the first kill and drops by about one a kill; a quest
turn-in lowers it without adding a sample; it hides at /reload until a kill; each corner, both
offsets, faintness, size and each of the three fonts; the mouse clicks through it; it hides with
Alt-Z; switch off removes it; level-up recomputes.

## Not doing

Putting anything on Blizzard's XP bar (the owner's first idea, dropped for the corner). A time-based
window, kills per hour, time to level. Saving samples across sessions. Modelling rested XP. A
dropdown control. Free dragging (corner and offsets do it). Colours, outlines, a label.
