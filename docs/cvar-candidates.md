# Console-only settings: candidates for Goblin Things

Researched 2026-11-15. A list to choose from, not a plan: nothing here is built.

## How the list was made

1. **The name is in the client.** Every name below is a string inside the live
   `_forever_\Wow.exe` (dated 2026-11-12), and the quoted description is the help text the exe
   keeps beside it. That proves the name exists on this client, not what it does here.
2. **Forever's Options has no row for it.** The UI source (`D:\wow-api\1.60.1.70291`) was swept for
   every `GetCVar`/`SetCVar` name and every Settings registration, then read by flavour: Forever
   loads the `Mainline` settings files and then `Camelot` ones that replace or blank parts of them.
3. **Nothing is verified in game.** No default, no effect, and no "an addon may write it" has been
   seen. Some CVars refuse an addon's write (in combat, or always). Each one built needs its
   checklist entry, and step one should be a `/gt probe` line printing `GetCVar` and
   `GetCVarDefault` for the names picked, so a dead name is caught before a switch is drawn.

Two of the owner's three examples are **not CVars**: bag direction is a pair of `C_Container`
functions, which is why `/console` has nothing for them and players paste `/run` lines instead.

## Seen in game (2026-11-15, the owner's `/gt probe`)

- All eleven first-pick CVars answer, with a default. Only `showInGameNavigation` was off its
  default: it read 1 against a default of **0**. So Forever ships the quest diamond off, whatever
  the exe's help text says, and the switch would be one most players have never seen on.
- At default 1 (the switch would turn them off): `alwaysCompareItems`, `mapFade`,
  `AutoPushSpellToActionBar`, `autoStand`, `autoDismount`, `autoUnshift`, `showTargetCastbar`.
  At default 0: `stopAutoAttackOnTargetChange`, `assistAttack`, `minimapTrackingShowAll`.
- Both bag functions answer: sort right to left true, new items left to right false.
- `ConsoleGetAllCommands()` gave an addon 1878 entries, so the full list can be dumped.
- Still unseen: whether an addon's write to any of these takes, and what each does here.

## Built (2026-11-15, unseen in game)

- Quest diamond on screen (`showInGameNavigation`), on the Quests tab.
- New items fill bags left to right and Sort bags right to left, on the Loot tab. A feature
  with `bag = "insert"` or `"sort"` is stored by the game through `API.BagDirection` /
  `API.SetBagDirection`, as one with `cvar` is stored by its CVar.

## What it costs

- A **check** on a CVar is one row in `Features.LIST` with `cvar = "..."` (as Guild login alerts).
- A **slider or choice** on a CVar needs `Core.Get`/`Core.Set` to stop special-casing the camera:
  small, once.
- The **bag pair** needs two `API.lua` wrappers each (get and set); the game stores the value.

## First picks

Plain quality of life, a clear on/off, and no Forever UI.

| Setting | Name | The client says | Why it has no UI in Forever |
|---|---|---|---|
| Quest diamond and its distance on screen | `showInGameNavigation` | "0: Disable IGN, 1: Enable IGN (Default)." | Retail's checkbox is blanked: `Camelot/InterfaceOverrides.lua:2` |
| Sort bags right to left | `C_Container.SetSortBagsRightToLeft` (function) | "Usage:" string in the exe | No file in the source calls it |
| New items fill from the left bag | `C_Container.SetInsertItemsLeftToRight` (function) | "Usage:" string in the exe | No file in the source calls it |
| Compare gear without holding Shift | `alwaysCompareItems` | read at `SharedXMLGame/Tooltip/TooltipUtil.lua:5` | Read only, never registered |
| World map fades while you walk | `mapFade` | read at `Blizzard_WorldMap.lua:401` | Read only, never registered |
| New spells land on the action bar | `AutoPushSpellToActionBar` | "Determines if spells are automatically pushed to the Action Bar. 0: No, 1: Yes (default)." | Only the new-player tutorial touches it |
| Stop attacking on target change | `stopAutoAttackOnTargetChange` | "Whether to stop attacking when changing targets" | Not in the UI source at all |
| Attack after /assist | `assistAttack` | "Whether to start attacking after an assist" | Not in the UI source at all |
| Auto stand, dismount, unshift | `autoStand`, `autoDismount`, `autoUnshift` | "Automatically dismount when needed", "Automatically leave shapeshift form when needed" | Not in the UI source; Forever also blanks Retail's flying dismount row (`Camelot/ControlsOverrides.lua:27`) |
| Target's cast bar | `showTargetCastbar` | "Show the spell your current target is casting" | Read at `SharedXML/GameRulesUtil.lua:51`, never registered; a game rule can still veto it |
| Every tracking type in the minimap menu | `minimapTrackingShowAll` | "If enabled, show dropdown for configuring all possible minimap tracking options." | Read at `Minimap/Mainline/Minimap.lua:648`, never registered |

Bag sort direction only matters where something sorts: the Forever bag files have no sort button
(no `SortBags` call in `UIPanels_Game/Camelot` or the bag bar), so check in game whether
`C_Container.SortBags()` does anything before building that one. The loot direction stands alone.

## Second picks

Useful to fewer players, or a slider rather than a check.

| Setting | Name | The client says |
|---|---|---|
| Spell queue window (ms) | `SpellQueueWindow` | "Sets how early you can pre-activate/queue a spell/ability. (In Milliseconds)" |
| Damage number size | `WorldTextScale_v2` | (no help text found beside it) |
| Damage numbers fly straight up | `floatingCombatTextCombatDamageDirectionalScale_v2` | "Directional damage numbers movement scale (0 = no directional numbers)" |
| Grey screen while dead | `ffxDeath` | "full screen death desat effect" |
| Full-screen glow | `ffxGlow` | "full screen glow effect" |
| Class-coloured names in chat | `colorChatNamesByClass`, `chatClassColorOverride` | "If enabled, the name of a player speaking in chat will be colored according to his class." |
| Mouse wheel scrolls chat | `chatMouseScroll` | "Whether the user can use the mouse wheel to scroll through chat" |
| Numeric threat on target frame | `threatShowNumeric` | "Whether or not to show numeric threat on the target and focus frames" |
| Threat sounds | `threatPlaySounds` | "Whether or not to sounds when certain threat transitions occur" |
| Guild names and titles over heads | `UnitNamePlayerGuild`, `UnitNamePlayerPVPTitle`, `UnitNameGuildTitle` | names only; Options > Nameplates has rows for player, NPC and minion names but not these |
| Pet names over heads | `UnitNameFriendlyPetName`, `UnitNameEnemyPetName` | names only |
| Screenshot quality and format | `screenshotQuality`, `screenshotFormat` | "Set the quality of screenshots (1 - 10)", "Set the format of screenshots" |
| Commas in large numbers | `breakUpLargeNumbers` | "Toggles using commas in large numbers" |
| Pets in the party frames | `showPartyPets` | "Whether to show pets in the party UI" |
| Buff durations | `buffDurations` | "Whether to show buff durations" |
| All buffs and debuffs on the target | `noBuffDebuffFilterOnTarget` | "Do not filter buffs or debuffs at all on targets" |
| Combo points on target or self | `comboPointLocation` | "Location of combo points in UI. 1=target, 2=self" |
| Double-click aura protection | `secureAbilityToggle` | "Whether you should be protected against accidentally double-clicking an aura" |
| Red error text flashes on repeats | `flashErrorMessageRepeats` | "Flashes the center screen red error text if the same message is fired." |
| Spell IDs in aura tooltips | `tooltipShowAuraSpellIDs` | "Show spell IDs in tooltips for unit auras." |
| Lua errors on screen | `scriptErrors` | "Whether or not the UI shows Lua errors" |

## Long shots

Named in the client, but likelier to be refused, restricted or useless here. In-game proof first.

- **Nameplates:** `nameplateMaxDistance` ("The max distance to show nameplates."),
  `nameplateOverlapV`, `nameplateOverlapH` (stacking spacing). Forever's own nameplate override says
  distance is a Classic-only setting (`Camelot/NameplatesOverrides.lua:33`), and nameplate CVars are
  the ones Blizzard has locked from addons before.
- **Targeting:** `TargetNearestUseNew` ("Set to 0 for 6.x style tab targeting"),
  `TargetPriorityCombatLock`.
- **Action camera:** `test_cameraOverShoulder`, `test_cameraDynamicPitch` and their kin. On Retail
  the game nags about "experimental" camera settings at login; unseen here.
- **Camera through walls:** `cameraIndirectVisibility`, `cameraIndirectOffset` (no help text found).
- **Fast loot's own knob:** `autoLootRate` ("Rate in milliseconds to tick auto loot"). Faster loot
  already loots the slots itself, so this would be a second road to the same place: YAGNI unless
  the switch proves slow.
- **Object outline:** `Outline`. Forever blanks Retail's dropdown
  (`Camelot/InterfaceOverrides.lua:5`), but the word is too common in the exe to count as proof the
  CVar exists; Options > Graphics already has `graphicsOutlineMode`.
- **Odds and ends:** `violenceLevel`, `showfootprintparticles`, `rawMouseEnable`,
  `worldPreloadNonCritical`, `dontShowEquipmentSetsOnItems`, `screenEdgeFlash`.

## Ruled out

Already in Forever's Options, so a switch would only repeat Blizzard's own:
auto loot, loot under mouse, auto self cast, sticky targeting, interact on left click, clear AFK,
camera style and speeds, terrain tilt, head bob, smart pivot, water collision, field of view,
target of target, low-health flash, loss of control, floating combat text on/off, find yourself,
chat timestamps, whisper mode, profanity filter, block trades and channel invites, friend toasts,
loading tips, instant quest text, free bag slots, combined bags, UI scale, cooldown numbers,
status text, map and minimap coordinates, and Guild login alerts and camera distance (already ours).

Not in this client at all (Retail or Classic Era names the exe does not hold):
`showQuestTrackingTooltips`, `trackQuestSorting`, `displayQuestID`, `removeChatDelay`,
`ShowClassColorInNameplate`, `nameplateOtherTopInset`, `nameplateLargeTopInset`,
`nameplateGlobalScale`, `nameplateMotion`, `predictedHealth`, `fullSizeFocusFrame`, and the
un-suffixed `floatingCombatText*` and `WorldTextScale` (this client's end in `_v2`).

## A better source than this list

The game can list every console command and CVar it has: `ConsoleGetAllCommands()`
(`ConsoleDocumentation.lua:59`; Blizzard's own console calls it at
`Blizzard_Console_AutoComplete.lua:369`). A one-off `/gt probe` dump of it into SavedVariables
would replace steps 1 and 2 above with the client's own answer, if the game lets an addon call it
(unseen). Worth doing before a second
round of picks; not needed to build the first ones.
