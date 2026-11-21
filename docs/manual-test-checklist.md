# Manual test checklist

In-game checks for what unit tests cannot reach. Only the owner runs the client.
Mark each with the build and date when walked; `[-]` is skipped by choice, with the reason.

## Install

- [x] After the junction and a **full client restart**, Goblin Things is listed and enabled in the
      AddOns list with its round GT icon; no Lua error on login.
- [ ] `/gt probe` lists every setting (autoAccept true ... acceptSummons false, cinematics
      repeats, cameraDistance a number), the CVar, the seen counts, a cinematic key like
      `Scourge:1420`, "none this session", and no "threw:".

## Window and minimap

- [x] Art (2026-10-15, **full client restart**: header.tga is new, icon.tga changed): the minimap
      button is the round goblin portrait with its bronze rim, clean-edged at 31 px, no square
      backdrop; Esc > Options > AddOns shows the same goblin beside "Goblin Things".
- [x] Art: the window's header is the plaque banner (goblin, wrench, "Goblin Things / Time is
      money, friend.") on the window's own colour: no box, no edge, no shade step anywhere round
      it (look hard at the corners and under the desk); the X clears the pipe end; no stub of a
      divider line at the right under the X (seen 2026-10-16, rule removed); dragging the banner
      moves the window. At 3840x2160 and your UI scale it reads sharp,
      not grainy, and nothing is cut off at the right (tell Claude the UI scale if it is).
- [ ] A round minimap button sits on the rim, clear of Goblin Flyout's.
      Hover: "Goblin Things / Click for options, drag to move. / Time is money, friend."
- [ ] Dragging it slides it round the rim; `/reload`: it stays where it was put.
- [x] Click, `/gt` and `/gt options` open the window; Escape or the X closes it.
- [ ] Esc > Options > AddOns lists "Goblin Things" with a gold "Open Goblin Things" button that opens the window.
- [ ] **Full client restart** first (TrackerSort.lua is new in the TOC).
- [ ] The window shows seven tabs (Quests, Vendors, Loot, Social, Camera, Cinematics, Map); the open one is gold.
      Each tab shows only its rows; the window keeps the same height on every tab; the "Show
      minimap button" check and "Hold Shift at an NPC or vendor to skip." stay under every tab.
- [ ] 600 wide for seven tabs (was 520 for six, seen 2026-10-15), rows 40 high: every tab name and
      every row label is fully visible, no "..." ("Cinematics", "Accept invites from friends",
      "Zone levels and fishing on the map"); the X still clears the banner; the window fits on screen.
- [ ] Close and reopen, and `/reload`: the window opens on the tab last used.
- [x] The Quests tab: three checks (auto accept, auto turn-in, auto-track), a gold "Quest tracker" sub-header, an "Only this zone" check,
      a "Hide quests above me" slider reading "Off", rows 1st / 2nd / 3rd each reading None | Level | Finished | This zone with every word fully
      visible, and the dim note "Off and all None = Blizzard's tracker (fully after /reload)".
      Nothing overlaps.
- [ ] Each check flips on click and stays flipped after `/reload`.
- [ ] Off | Repeats only | All: all three words fully visible (no "..."), each button snug to its
      word; the chosen one is gold; it stays after `/reload`.
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
- [ ] A vendor, trainer or innkeeper who also offers a PvP or 5-player quest: talking to them shows
      their own menu, not that quest (at most once per session for a 5-player quest).
- [ ] Shift held while talking to the NPC: nothing is accepted or turned in that visit.
- [ ] Each switch off on its own: only the other thing happens.

## Auto-track new quests

- [ ] Ticked: `/gt probe` says "autoQuestWatch reads 1", also after `/reload` and after a loading
      screen. Accept a new quest: it shows in the tracker (and in the tracked-quests list).
- [ ] With the addon that turned it off still installed (e.g. Questie): after logging in and a
      loading screen, still "reads 1".
- [ ] Unticked by clicking: "autoQuestWatch reads 0"; a newly accepted quest is not tracked.
- [ ] Never ticked on a fresh install: Goblin Things leaves `autoQuestWatch` as it was.

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
- [ ] Set any tier, then all three back to None: the tracker goes back to Blizzard's order now and
      **keeps drawing and updating** (accept or progress a quest); achievement and profession
      trackers below it still update; `/gt probe` says "off (pass-through until /reload)".
      `/reload`: Blizzard's order, probe "off (not installed)".
- [ ] `/dump rawget(QuestObjectiveTracker, "BuildQuestWatchInfos") ~= nil` prints true before any
      tier is set (the frame owns a copy of the method; tell Claude if false).
- [ ] `/reload` with a tier set: the tracker comes up already sorted.
- [ ] With a tier set, through accepting, finishing, turning in and abandoning quests, the tracker
      never goes blank or drops a quest, and `/gt probe` shows no "Tracker sort threw" line (a sort
      that errors or shows a quest Blizzard did not give falls back to Blizzard's list).
- [ ] Gaps bug (seen 2026-10-17: blank space between tracked quests after turning in and picking
      up quests; changing a sort or the level slider clears it). While the gaps show, run
      `/gt probe` **before touching any setting** and send Claude the "tracker blocks" line (each
      block's quest ID, top, height, alpha, and whether it is cached, hidden or unchained), plus
      any Lua error seen with `/console scriptErrors 1`.
- [ ] Only this zone on (all tiers None): only quests on your current map show; `/gt probe` says
      "tracker sort off, only this zone (installed)".
- [ ] Only this zone: ride into another zone, then into a sub-zone and indoors: the list follows.
- [ ] Only this zone in a zone with none of your tracked quests (a city): the tracker is empty.
- [ ] Only this zone in the Crossroads: Barrens quests show; Stonetalon quests (Letter to Jin'Zil,
      Deepmoss Spider Eggs, Ziz Fizziks) do not. Open the world map on Stonetalon and close it: no change.
- [ ] Only this zone inside a cave or other sub-map: note whether the zone's quests hide (the check
      uses the map you are on; tell Claude if that is unwanted).
- [ ] Only this zone: a finished quest whose turn-in NPC is in another zone (e.g. Ziz Fizziks,
      Windshear Crag, seen from the Barrens) is hidden until you get there. Tell Claude if it shows.
- [ ] Only this zone plus 1st: Level: this zone's quests only, lowest level first.
- [ ] Only this zone off again (tiers None): every tracked quest is back; probe says
      "off (pass-through until /reload)".
- [x] Hide quests above me (2026-10-15): drag the slider; its number steps Off, +1 ... +20 in
      whole levels and stays after `/reload`. At +3 (tiers None, Only this zone off): a tracked quest
      more than 3 levels above you leaves the tracker at once; one exactly 3 above stays. The quest
      log still lists it. Probe: "hideAbove = 3" and "(installed)".
- [ ] Hide quests above me: ding a level with a hidden quest one level over the cap: it comes back
      on the tracker by itself (tell Claude if it needs a second level-up or a `/reload`).
- [ ] Hide quests above me with Only this zone and 1st: Level: both filters apply, lowest first.
- [ ] Hide quests above me back to Off (tiers None, zone off): every tracked quest is back; probe
      says "off (pass-through until /reload)".
- [ ] **Release gate:** `/console taintLog 1`, `/reload`, set a tier, track a quest with a usable
      item. Out of combat and then in combat: use the item from the tracker; left-click a quest
      title (the map opens); right-click a title and super-track it; click a quest's POI button.
      After combat: open and close the spellbook and the bags. No "blocked" or "AddOn tried to call
      a protected function" anywhere, and no GoblinThings "blocked" line in `Logs\taint.log`. Then
      `/console taintLog 0`. If anything is blocked, send the end of `Logs\taint.log`; the feature
      does not ship as built.

## Vendors

- [ ] A vendor with grays (one a stack) and damaged gear: grays sold, gear repaired, one chat line,
      Buyback shows the grays.
- [ ] A vendor that cannot repair: grays sold, no repair, no complaint.
- [ ] Short of gold for the repair: "Not enough gold to repair (costs ...)", nothing repaired, grays still sold.
- [ ] Shift held while opening the vendor: nothing sold, nothing repaired, no line.
- [ ] Open a vendor, close, reopen: it acts again on the reopen, once.
- [ ] Each switch off on its own: only the other thing happens.

## Trainers

- [x] Auto train on, Vendors tab shows it (off by default); full client restart for the new file first.
- [x] Class trainer with several green rows: all trained one after another (Druid, level 22, 2026-10-16:
      Moonfire, Rejuvenation, Soothe Animal, Wrath).
- [x] Closing the trainer says "Trained N for ..." with the gold spent, counting only what the addon bought,
      with the trainer's Used filter off (Snang: "Trained 1 for 25c." after Tailoring by hand, 2026-10-16).
- [-] Short of gold for the whole list: trains in list order until it cannot afford the next, then stops,
      no error spam in chat; the line counts only what was learned.
      Skipped 2026-10-16: no chance to test before 2026.10.16.2; logic covered by test_trainer.lua.
- [x] Profession trainer for a craft you have: recipes are trained (Tarn, Light Leather Pants at 71 skill,
      56s 41c to 52s 81c, 2026-10-16).
- [-] The same for the next rank (Journeyman etc.) when it comes due.
      Skipped 2026-10-16: no chance to test before 2026.10.16.2; logic covered by test_trainer.lua.
- [x] Taking up a profession by hand at its trainer: the recipes that turn green are then trained in the same
      visit (Snang, Apprentice Tailoring by hand, then White Linen Shirt, 2026-10-16).
- [x] Profession trainer for a craft you do not have: nothing trained, no profession slot taken
      (Enchanting trainer, both slots full with Skinning and Leatherworking, 2026-10-16).
- [x] The same with a free profession slot: still nothing trained (an alt with only Enchanting at Snang,
      Apprentice Tailoring 10c left green and untrained, 2026-10-16).
- [x] Shift held while talking to the trainer: nothing trained, no line (Tarn, Leatherworking, 2026-10-16).
- [-] Switch off: the trainer window is left as it is.
      Skipped 2026-10-16: no chance to test before 2026.10.16.2; logic covered by test_trainer.lua.
- [-] Hunter pet trainer (if a hunter is handy): nothing trained.
      Skipped 2026-10-16: no chance to test before 2026.10.16.2; logic covered by test_trainer.lua.
- [x] A trainer whose chat page holds only "Train me." (Tarn): the trainer list opens straight away and
      trains (2026-10-16).
- [-] The same with Shift held: the chat page stays and nothing is trained.
      Skipped 2026-10-16: no chance to test before 2026.10.16.2; logic covered by test_trainer.lua.
- [-] A trainer with a second option ("unlearn talents", a quest): the chat page stays as it is.
      Skipped 2026-10-16: no chance to test before 2026.10.16.2; logic covered by test_trainer.lua.

## Loot

- [x] After a **full client restart** (Loot.lua is a new file): every tab name fully visible
      ("Cinematics" too); the Loot tab shows "Fast loot", on.
- [ ] Blizzard's Auto Loot on, Fast loot on: kill and loot a mob with several drops and coin; all of
      it lands at once, the loot window at most flickers. Same for a chest, a herb or a fishing catch.
- [ ] Same, holding Shift (Blizzard's auto-loot toggle): the loot window stays open, nothing taken.
- [ ] Blizzard's Auto Loot off: the window opens as normal; Shift-loot takes it all at once.
- [ ] Fast loot off, Auto Loot on: Blizzard's own pace, nothing else changes.
- [ ] Bags full: what fits is taken, the rest stays in the open loot window ("Inventory is full" may say so more than once).
- [ ] A bind-on-pickup drop: Blizzard's bind popup asks; nothing is confirmed for you.
- [ ] In a group with a loot threshold: an item up for roll stays for the roll; the rest is taken.

## Social

- [ ] Decline duels on: a friend's duel request is refused, "Declined a duel from <name>." is said,
      and **no duel popup lingers** (open fact 2).
- [ ] Decline duels off: the duel popup appears as normal.
- [ ] Decline guild invites on: an invite is refused with "Declined a guild invite from <name>
      (<guild>)." and **no invite window lingers** (open fact 2).
- [ ] Decline guild invites off: the invite window appears as normal.
- [ ] After a **full client restart** (Accept.lua is a new file): the Social tab shows five checks,
      "Accept invites from guild", "Accept invites from friends" and "Accept summons" under the
      declines, each off, every label fully visible. `/gt probe` says "accept calls missing: none"
      (tell Claude any it names).
- [x] Accept invites from guild on, a guildie invites you (party, then a raid): you join, "Accepted
      a group invite from <name> (guild)." is said, and **no invite popup lingers**. You stay in
      the group a minute later (the popup's close must not decline it).
- [ ] Accept invites from friends on: the same from a character friend, then a Battle.net friend,
      with "(friend)".
- [ ] Each check alone: an invite from the other list, or from a stranger, shows the normal popup.
- [ ] Queued for a battleground (or any queue), a guildie invites: the normal popup, with Blizzard's
      "will remove you from the queue" line; nothing accepted.
- [ ] Accept summons on, out of combat: a warlock's ritual or a meeting stone summon is taken at
      once, "Accepted a summon from <name> to <place>." is said, no popup lingers, you arrive.
- [ ] Accept summons on, in combat when the summon comes: the popup stays (its Accept greyed, as
      Blizzard does); accept it yourself after combat.
- [ ] Accept summons off: the summon popup appears as normal.
- [x] Guild login alerts (2026-10-15): the Social tab's sixth check, ticked when Blizzard's
      Options > Social > Guild Member Alert is; `/gt probe` says "guildAlerts = true".
- [x] Untick it: a guildie logging in makes **no ding**. Note whether the "<name> has come online" (2026-10-16: no ding; whether the chat line went too was not noted)
      chat line still shows (the engine owns both; tell Claude if the line went too). Blizzard's
      Guild Member Alert box now reads unticked; tick it there and our box follows on reopen.
- [ ] Never clicked on a fresh install: `/dump GetCVar("guildMemberNotify")` is unchanged by opening
      the window.
- [ ] Taint: with `/console taintLog 1`, after an auto-accepted invite, a later popup (delete an
      item, a duel request) works; no "blocked" line naming GoblinThings in `Logs\taint.log`.

## Cinematics

- [ ] New character, Skip cinematics on Repeats only: the race intro plays. Then `/gt probe`: the
      last cinematic summary line shows what the game said (open fact 1; tell Claude what it was).
- [ ] Same race, another new character in the same zone: the intro is skipped.
- [ ] Mode All: an intro you have never seen is skipped.
- [ ] Mode Off: the intro plays.
- [ ] A flight path or any vehicle ride plays normally in every mode (it is not a cinematic).

## World map zone readout

Spec `docs/superpowers/specs/2026-11-10-map-zone-readout-design.md`. Built 2026-11-10 on 1.60.1.70862,
verified in source only.

- [ ] **Full client restart** first (MapInfo.lua and MapReadout.lua are new in the TOC). No Lua
      error on login; the Map tab shows one check, "Zone levels and fishing on the map", ticked, and
      the dim note "Hover a zone on the world map; read it bottom right".
- [ ] Open the world map on Kalimdor and hover The Barrens: at the map's bottom right, three
      right-aligned lines in outlined map lettering: "The Barrens" (pale gold), "Levels 10-25" and
      "Fishing 1 (no getaways at 75)" (white). Move to Ashenvale: it changes to "Levels 18-30",
      "Fishing 55 (no getaways at 150)". Over the sea, or with the cursor off the map: nothing.
- [ ] Hovering a flight point or quest pin inside a zone keeps that zone's lines up.
- [ ] The lines clear the quest-log toggle in the corner (if this build shows one) and every map
      control; nothing overlaps; long names ("Stranglethorn Vale", "Fishing 330 (no getaways at
      425)") are not cut. Readable on the parchment at your UI scale (tell Claude the sizes to change).
- [ ] Eastern Kingdoms: Badlands shows its name and "Levels 35-45" only (no fishing data);
      Riverglades shows "Levels 35-45" only (Herbs and Ore lines too, since 2026-11-14).
- [ ] Open a zone's own map (Durotar): its lines show without hovering. Hover Orgrimmar on it:
      "Orgrimmar" and its fishing line, no levels. Kalimdor's own continent view with the cursor
      away: nothing. Shen'dralas: nothing.
- [ ] Untick the switch with the map open: the lines vanish; tick it: they return on the next hover.
- [x] `/gt probe` after hovering a few zones: "map readout built; map hover asked N times, M
      answered with a map" with M above 0. If it says **NO answers**, the hover API is silent on this
      build: tell Claude. (seen 2026-11-14, the owner's `/gt probe` and screenshots)
- [ ] Forever's fishing: in one zone you know, does the game's "need more skill" message or catch
      rate match the line (Classic values, unverified on Forever)? Tell Claude what differs.
- [ ] Level ranges: compare a few zones with the game's own idea (quest levels, mob levels); the
      ranges are Classic's, copied from GoblinPS.

## The game's own look ("back to roots")

Built 2026-11-14, verified in source only. The window, options page and the map readout's lists
were restyled to the colours of the game's own Statistics and Professions windows; the plaque banner
is gone. This section replaces what "Window and minimap" above says of the banner and the gold tab.
`/reload` is enough (no new file; `header.tga` was removed).

- [ ] `/gt`: no Lua error. The window is warm brown, not grey-black, inside a bronze edge with a thin
      dark rim; no banner art. Hold it beside the game's Professions window: do the browns, the
      bronze and the gold sit together, or does ours read too flat, too red or too yellow?
      Seen 2026-11-14 (the owner's screenshots): the window is warm brown in a bronze edge, no banner. Not yet said: whether an error showed, and
      how it sits beside the game's own windows.
- [ ] A title bar across the top: "Goblin Things" centred in bright gold, a bronze line under it, a
      red square close button with a gold X at its right. The X closes the window; Escape too.
      Seen 2026-11-14 (the owner's screenshots): the bar, the gold name, the bronze line and the red button with its X. Not yet said: that the X
      and Escape close it.
- [x] Dragging by the title bar moves the window and it stays put after `/reload`.
      Seen 2026-11-15 (the owner: "dragging the window works fine, no issues"); whether the
      `/reload` half was tried was not said.
- [x] Tabs: the open one is a lighter brown with gold words and a pale gold line along its top; the
      others are dark with tan words. All eight names fit. (seen 2026-11-14, the owner's screenshots)
- [x] Rows: check boxes are now at the **left** of each row, a dark square in a bronze outline, a
      gold square inside when on. Words are white. Sliders and choices stay at the right; the
      picked choice has gold words and the pale top line. (seen 2026-11-14, the owner's screenshots)
- [x] Quests tab: "Quest tracker" sits in a brown header bar across the page, gold words. (seen 2026-11-14, the owner's screenshots)
- [x] The dim notes and "Hold Shift at an NPC or vendor to skip." are light tan and readable. (seen 2026-11-14, the owner's screenshots)
- [ ] The window is shorter than before (the banner's 126 px became a 30 px bar) and still fits.
- [x] Esc > Options > AddOns > Goblin Things: its button reads in the same look.
      Seen 2026-11-15 (the owner's screenshots): "Open Goblin Things" in the brown and bronze, lit along its top.
- [x] World map, a zone's own map: a list opened from an icon is brown in the bronze edge, gold
      title, white names, tan numbers; an icon's outline turns gold while hovered. (seen 2026-11-14, the owner's screenshots)
- [ ] Anything that now looks wrong or unfinished next to the game's own windows: tell Claude what.

## Herbs, ore and fish on the map

Spec `docs/superpowers/specs/2026-11-14-map-gathering-lists-design.md`. Built 2026-11-14, verified in
source only. The lists are Wowhead's Forever figures where it has them, Classic Era's (footnoted)
where it does not. This section replaces
what the section above says of the Map tab's rows and note, and Badlands now has Herbs and Ore lines.

- [ ] **Full client restart** first (MapData.lua is new in the TOC). No Lua error on login. The Map
      tab shows four checks, all ticked: "Zone levels and fishing on the map", "Herbs on the map",
      "Ore on the map", "Fish list on the map", and the dim note "Read a zone at the world map's
      bottom right; open the zone for its lists", not cut off at the window's edge.
- [x] Open the Barrens' own map: five lines bottom right: "The Barrens", "Levels 10-25", "Fishing 1
      (no getaways at 75)", "Herbs 1-125", "Ore 1-75". The last three each end in a small square
      icon, right edges in a line, nothing overlapping the quest-log toggle or the map's controls.
      Seen 2026-11-15 (the owner's screenshots): the Barrens' card with those lines and a sixth, Skins, each list line ending in its icon.
- [x] The three icons are the game's Fishing, Herbalism and Mining icons (not some other spell's, and
      not the letters F, H, O). `/gt probe` says "profession icons from the game: herbs yes, ore yes,
      fish yes". A NO there, or a wrong picture, tell Claude: the spell IDs are from memory.
      Seen 2026-11-14 (the owner's screenshots): on Riverglades' map the three are pictures, not letters (a hook, a herb, a pick). `/gt probe`
      not yet pasted. (seen 2026-11-14, the owner's `/gt probe` and screenshots)
- [x] Hover the Herbs icon: its edge turns gold and a dark list opens above the corner, titled
      "Herbalism" in gold, ten rows from "Peacebloom 1" to "Kingsblood 125", names left, skills right
      and dim. Move off: it closes. The list stays put while the cursor rests on the icon (no flicker).
      Seen 2026-11-15 (the owner's screenshots): the Herbalism list, ten rows from Peacebloom 1 to Kingsblood 125, the icon's edge gold.
- [ ] Hover the Ore icon: "Mining", Copper Vein 1, Tin Vein 65, Silver Vein 75. Hover the Fishing
      icon: "Fishing", seven rows from "Raw Rainbow Fin Albacore 22%" down, no footnote. No list is
      cut by the top or right of the map.
      Seen 2026-11-15 (the owner's screenshots): not the Barrens' Mining or Fishing lists, but Mulgore's Fishing list opened the same way (Raw
      Brilliant Smallfish 59%, Raw Longjaw Mud Snapper 38%, no footnote).
- [ ] Felwood's own map: the Fishing list ends in the dim footnote "Classic figures, not checked on
      Forever" (too few catches recorded on Forever yet); its Herbalism and Mining lists have none.
      Winterspring and Silithus likewise.
- [x] Kalimdor, hovering the Barrens: the same five lines, **no icons**. Hovering across zones swaps
      the Herbs and Ore lines with the rest.
      Seen 2026-11-14 (the owner's screenshot) on Eastern Kingdoms instead, hovering Riverglades: its
      six lines and no icons.
- [ ] Durotar's own map, hovering Orgrimmar: the city's lines, no icons; off the city: Durotar's
      lines with icons again.
- [ ] Moonglade's own map: no Herbs or Ore lines, no gap, a Fishing icon. Teldrassil: "Ore 1" (Chunk
      of Amber, Large Chunk of Amber) and Durotar "Poor Copper Vein": are those real veins on Forever?
      Un'Goro Crater: no fish icon (too few catches recorded).
      Seen 2026-11-15 (the owner's screenshots): Teldrassil reads "Ore 1" and Mulgore "Ore 1"; whether those veins are real on Forever was not
      said. Moonglade and Un'Goro not yet seen. 
- [ ] Untick "Herbs on the map" with the map open: the Herbs line goes and Ore closes up. Untick "Ore
      on the map": likewise. Untick "Fish list on the map": the Fishing line stays, its icon goes.
      Untick "Zone levels and fishing on the map": everything goes, whatever the other three say.
- [ ] Clicking through an icon: note whether a click on an icon is swallowed (it sits over the map)
      and whether that is a bother; tell Claude.
- [ ] Mount Hyjal: "Herbs 270-300" (Demonsage 300) and "Ore 275-300" (Heavy Thorium Vein 300).
      The Hinterlands lists Star Lotus 250 and Starsilver Vein 245: real nodes on Forever?
      Seen 2026-11-14 (the owner's screenshot): Mount Hyjal reads Level 60, Herbs 270-300, Ore 275-300,
      Skins: Rugged, with Fel Leather 28% and Fel Hide 2% in its list. The Hinterlands not yet seen.
- [ ] Forever's new zones (2026-11-14, Wowhead's Forever figures). Riverglades now reads "Levels
      36-44" (was 35-45), then a bare "Fishing" line with an icon (its catch is known, its skill is
      not: tell Claude the skill if the game shows one), "Herbs 85-185", "Ore 65-230". Zephras Isle:
      "Levels 1-12", bare "Fishing" with an icon (Brilliant Smallfish, Longjaw Mud Snapper), "Herbs
      1-50", "Ore 1". Shen'dralas (no level range known): its name, "Herbs 100-120", "Ore 125-175".
      Seen 2026-11-14 (the owner's screenshots): Riverglades exactly as written, six lines clear of the map's frame, and its Skinning list (Heavy
      Leather 68%, Thick Leather 26%, Heavy Hide 3%, Pristine Hide 1%, then Worn Dragonscale, Thick
      Wolfhide and Turtle Scale under 1%). Zephras Isle and Shen'dralas not yet seen.
- [ ] With "Fish list on the map" off, Riverglades and Zephras Isle lose the Fishing line whole.
      With Herbs and Ore both off, Shen'dralas shows nothing at all (no bare name), on its own map
      and hovered on Kalimdor.
- [ ] Are Riverglades' 36-44 and Zephras Isle's 1-12 right by the game's quests and mobs?
- [ ] No fish icon, by design (too few catches recorded): Un'Goro Crater, Eastern Plaguelands,
      Burning Steppes, Deadwind Pass.
- [ ] Against the game: in one zone you gather in, do the herbs, the veins and the catch match
      the lists? Tell Claude what is missing or should not be there (the Barrens lists Grave Moss; a
      rare node reads the same as a common one).
      Seen 2026-11-15 (the owner's screenshots): cards for Mulgore (Herbs 1-15, Skins: Ruined, Light), Teldrassil (Herbs 1-50) and Azshara (Fishing
      205, Herbs 85-280, Ore 155-275, Skins: Thick, Rugged) drew as the data has them. Whether they
      match what grows there is still the owner's to say.

### Skins (2026-11-14)

Wowhead's Forever figures, from each leather's skinned-from list. Verified in source only.

- [x] `/reload` is enough if MapData.lua was already loaded by a restart since 2026-11-14; else a
      **full client restart**. The Map tab shows five checks, the new one "Skins on the map", ticked. (seen 2026-11-14, the owner's screenshots)
- [x] The Barrens' own map: a sixth line, "Skins: Ruined, Light, Medium", ending in an icon; all six
      lines fit above the corner and clear the map's controls.
      Seen 2026-11-15 (the owner's screenshots): as written, on the card.
- [x] The icon is the game's Skinning icon (else the letter S); `/gt probe` lists "skins yes".
      Seen 2026-11-14 (the owner's screenshots): a picture, not the letter S, its outline gold while hovered. `/gt probe` not yet pasted. (seen 2026-11-14, the owner's `/gt probe` and screenshots)
- [ ] Hover it: "Skinning", then Light Leather 61%, Ruined Leather Scraps 20%, Medium Leather 11%,
      Light Hide 5%, Pristine Leather 1%, Deviate Scale <1%, Perfect Deviate Scale <1%.
- [ ] Pristine Leather, Pristine Hide and Pristine Scale show in most zones' lists at a percent or
      two: are they a rare extra skin off ordinary beasts on Forever, as Wowhead has them?
- [ ] Un'Goro Crater: "Skins: Thick, Rugged", and the list has Devilsaur Leather 4%. Winterspring:
      Warbear Leather and Frostsaber Leather in the list. Redridge: Black Whelp Scale. Silithus: a
      bare "Skins" line (Silithid Chitin, then Light and Heavy Silithid Carapace).
- [x] Kalimdor, hovering the Barrens: the Skins line shows, no icon.
      Seen 2026-11-14 on Eastern Kingdoms, hovering Riverglades: "Skins: Heavy, Thick", no icon.
- [ ] Untick "Skins on the map": the line goes. Moonglade and Deadwind Pass have no Skins line.
- [x] The readout sits on a card (2026-11-14, the owner: letters on the parchment "washed out
      easily"): solid brown in the bronze edge, the zone's name in gold, the lines in white, no
      outline round the letters. The card hugs the lines showing: small for a city, tall for six
      lines; nothing showing, no card. It stands clear of the map frame's corner and the
      quest-log toggle. The icons still take the mouse and a list opens just above the card.
      Seen 2026-11-14 (the owner's screenshots of Stranglethorn Vale and Eastern Plaguelands).
- [x] A neighbour at the edge of a zone's own map (2026-11-14, the owner: Winterspring on Mount
      Hyjal's map took the card over and Hyjal's icons could not be reached): with Mount Hyjal's
      map open, move the cursor over Winterspring's edge: the card stays Mount Hyjal's, icons and
      all, and each icon can be reached and hovered. On Durotar's map, hovering Orgrimmar still
      shows the city. On Kalimdor the card still follows the cursor from zone to zone.
      Seen 2026-11-14 (the owner: "the mt hyjal fix worked", with Hyjal's Skinning list open).
      Orgrimmar on Durotar's map and the continent not rechecked since the fix.
- [ ] On a continent the card follows the hovered zone, resizing without a flicker, and goes over
      the sea. Does it hide anything on the map you want to see? Tell Claude.
- [x] A city's own map (2026-11-15, the owner: with Orgrimmar's map up, Durotar showed when the
      cursor reached the edge): with Orgrimmar's map open, move the cursor to where Durotar is
      drawn round it: the card stays Orgrimmar's. On Durotar's own map, hovering Orgrimmar still
      shows the city (not said either way yet).
      Seen 2026-11-15 (the owner's screenshots): the owner, "orgrimmar fix works".
- [ ] As a skinner: in a zone you work, is anything missing or wrong? A beast that roams several
      zones counts only for the first zone Wowhead lists it in, so a list can miss a type its
      neighbour claims; tell Claude which.

## Kills to level

- [ ] With a count showing, untick Kills to level and tick it again: no number until the next kill, and `/gt probe` reads 0 kill sample(s) before it.

- [ ] **Full client restart** first (Kills.lua and KillsReadout.lua are new in the TOC). No Lua
      error on login; nothing new on screen (the switch is off by default).
- [ ] (Superseded 2026-11-15: 766 wide and nine tabs, see "The rest of the first picks".)
      The window is 684 wide and shows eight tabs, XP last; every tab name is fully visible
      ("Cinematics"), the X still clears the banner, and the window fits on screen.
- [ ] The XP tab: a "Kills to level" check, Corner (Top left | Top right | Bottom left | Bottom
      right, every word visible), Offset across, Offset down / up, Faintness (reads "30%"), Size,
      Font (Friz | Arial | Morpheus), and the dim note "Kills like your last ten; hidden until your
      first kill". Nothing overlaps; "100%" fits beside the Faintness slider.
- [ ] Tick the switch on the XP tab: a ghosted `37` appears in the top left, with no outline, no
      frame and no label.
- [ ] Each Corner button moves it to that corner at once; on the right-hand corners it hugs the
      right edge.
- [ ] Offset across and Offset down / up each push it in from the chosen corner as you drag; at 0
      and 0 it sits in the very corner.
- [ ] Faintness: 5% is barely there, 100% is solid white. If the name reads backwards for a slider
      where right is easier to see, tell Claude.
- [ ] Size changes it as you drag, 8 to 48.
- [ ] Friz, Arial and Morpheus each draw a visibly different face. A face that will not load must
      still show the number (in Friz): tell Claude which one, if any, looks the same as Friz.
- [ ] The number has no drop shadow: plain ghosted white, no dark edge down and to the right.
- [ ] The mouse clicks through it: with it over the player portrait, a click still targets you.
- [ ] It sits under the character pane and the bags, never over them; Alt-Z hides it with the UI.
- [ ] Leave the XP tab, or close the window (the X, Escape, `/gt`): the sample `37` goes. Back on
      the XP tab it returns. Untick the switch: it goes and stays gone.
- [ ] `/reload`: corner, offsets, faintness, size and font are as you left them.
- [x] The probe (yours to tick; your 2026-11-11 screenshot, in a party, showed it): the XP lines are
      readable, the three "COMBATLOG_" format strings exist, and a kill reads "<mob> dies, you gain
      N experience." with N the whole gain. Not in that screenshot: a quest turn-in or a discovery
      (its twelve lines were all kills). (seen 2026-11-14, the owner's `/gt probe` and screenshots)
- [x] The count (a `/reload` is enough): with the switch on, the number appears after your first
      kill and drops by about one a kill on like mobs.
      Seen so far (2026-11-14, the owner's screenshot, hunting Plains Buzzards): a ghosted `59` in
      the top left, no frame or label, the world plain to see through and around it. Not yet
      confirmed: that it drops by about one a kill.
      Seen 2026-11-14: the owner, "kill count works fine", with a second screenshot reading `29`.
- [ ] Turn in a quest and discover an area: the number drops and `/gt probe`'s "kill sample(s)"
      count does not rise. Send Claude those two "XP line" msg lines (never yet seen).
- [ ] An unnamed gain ("You gain N experience.", seen once in a party) lowers the number and adds
      no sample. Tell Claude if those are common enough that the count feels wrong.
- [ ] `/reload`: the number is hidden until the next kill.
- [ ] A level-up recomputes it against the new level. At max level, or with XP turned off, it
      never shows.
- [ ] Solo and rested, then unrested: the count jumps when rested runs out and settles within ten kills.

## The rest of the first picks (2026-11-15)

A `/reload` is enough (no new file). Ten more checks, each stored by the game's own CVar. By the
probe all sit at the game's default: seven on, three off.

- [ ] The window is 766 wide and shows nine tabs, Combat between Social and Camera; every tab
      name is fully visible ("Cinematics") and the window fits on screen.
- [ ] Each new check opens showing the game's value. On: Always compare gear (Loot); Auto stand,
      Auto dismount, Auto leave shapeshift form, Target's cast bar, New spells go on the action
      bar (Combat); World map fades while moving (Map). Off: Stop attacking on target change,
      Attack after /assist (Combat); Every tracking type on the minimap (Map).
- [ ] Flip each and run `/gt probe`: its CVar follows, 1 to 0 or 0 to 1.
- [ ] Always compare gear off: hovering gear in a bag shows no worn item beside it until Shift is
      held. On: it shows without Shift.
- [ ] Stop attacking on target change on: mid-fight, target another mob; auto-attack stops. Off:
      it carries on at the new target.
- [ ] Attack after /assist on: `/assist` a fighting party member; you start attacking.
- [ ] Auto stand off: sit, then cast or attack; the game refuses ("You must be standing"). On: you
      stand and it goes.
- [ ] Auto dismount off: mounted, cast a spell; the game refuses. On: you dismount and cast.
- [ ] Auto leave shapeshift form (a druid, or skip with the reason): off, a caster spell in form
      is refused; on, the form drops.
- [ ] Target's cast bar off: a casting mob shows no bar under the target frame. On: it does.
- [ ] New spells go on the action bar off: train a new spell; no bar slot fills. On: one does.
- [ ] World map fades while moving off: walk with the map open; it stays solid. On: it fades.
- [ ] Every tracking type on the minimap on: the minimap's tracking menu lists more than before.
      Say what it lists; if nothing changes on this client, the switch comes out.
- [ ] Each keeps its value through a `/reload` and a relog.

## Bag directions kept through a reload (2026-11-15)

The owner saw "New items fill bags left to right" tick itself off at `/reload`: the game does not
keep it. Goblin Things now saves a bag direction once it is chosen in the window and sets it again
on every login and reload. A `/reload` is enough.

Second try: the owner ticked it, reloaded, and it was off again, so setting it as the world loads
does not stick. It is now also checked at every bag change (`BAG_UPDATE_DELAYED`) and set where
the game's differs. If it still comes up unticked, run `/gt probe` and send the "bags" line: it
shows the game's value beside the saved choice.

- [ ] Tick New items fill bags left to right, `/reload`: still ticked, and new loot still lands
      at that end.
- [ ] The same through a full relog, and on another character (the choice is account-wide).
- [ ] Sort bags right to left: untick it, `/reload`: still unticked.
- [ ] No "action blocked" popup at login or on a `/reload` in combat.

Third try: ticked, then probed, the owner's bags line read game false and saved **false**. A
saved false needs a click made while the box read on, so the likeliest story is that the game's
read lags its write: the tick did not show, and a second click undid it. A bag check now shows
the saved choice once there is one, not the game's read.

- [x] Click New items fill bags left to right once: it ticks at once and stays ticked.
      (2026-11-15, the owner: "it stays ticked now".)
- [x] `/gt probe` with it ticked reads saved fill true; say what the game's value reads beside
      it, straight away and again after looting something.
      (2026-11-15, the owner's screenshot: game true, saved true. So the game does take the write.)
- [x] Loot or buy an item with it ticked: it lands at the other end of the bags from unticked.
      (2026-11-15, the owner: "items coming in are working".)

## Quest diamond and bag directions (2026-11-15)

A `/reload` is enough (no new file). The game stores all three; Goblin Things keeps no copy.

- [ ] The window is one row taller and nothing is cut off: the Quests tab shows "Quest diamond on
      screen" under Auto-track new quests, above the Quest tracker header; the Loot tab shows Fast
      loot, "New items fill bags left to right" and "Sort bags right to left".
- [ ] Each opens showing the game's own value (2026-11-15's probe: diamond on, fill left to right
      off, sort right to left on).
- [x] Untick Quest diamond with a quest tracked: the diamond and its distance go at once. Tick it:
      they come back. `/gt probe` reads showInGameNavigation 0, then 1.
- [x] Tick New items fill bags left to right, loot or buy an item: it lands at the other end of
      your bags from before. Untick: back to the first end. The probe's bags line follows.
- [x] Sort bags right to left: tick and untick it, and say whether anything in Forever sorts bags
      at all (no sort button was found in its files). If nothing does, this switch comes out.
      (2026-11-15, the owner: "all three work", so the switch stays.)
- [ ] Each switch keeps its value through a `/reload` and a relog, and on another character.
- [ ] In combat, each switch still takes, or the game refuses it quietly: no error, no
      "action blocked" popup. Tell Claude which.

## Console-only candidates (the probe, 2026-11-15)

Nothing is switched here: `/gt probe` only reads. A `/reload` is enough. The list is `docs/cvar-candidates.md`.

- [x] `/gt probe` prints one "candidate CVars" line: each of the eleven names with its value and
      default, or "missing". Paste the line to Claude; a missing name comes off the list.
      Seen 2026-11-15: all eleven answered, none missing. showInGameNavigation 1 (default 0); every
      other at its default: alwaysCompareItems, mapFade, AutoPushSpellToActionBar, autoStand,
      autoDismount, autoUnshift and showTargetCastbar 1; stopAutoAttackOnTargetChange, assistAttack
      and minimapTrackingShowAll 0. (seen 2026-11-15, the owner's `/gt probe` screenshot)
- [x] The "bags sort right to left ... new items left to right ..." line reads true or false for
      both, not nil. Paste it.
      Seen 2026-11-15: sort right to left true, new items left to right false. (seen 2026-11-15, the owner's `/gt probe` screenshot)
- [x] The "console lists N command(s)" line gives a number, not nil. Paste it.
      Seen 2026-11-15: 1878. (seen 2026-11-15, the owner's `/gt probe` screenshot)
- [x] No "threw:" line names GetCVarDefault, GetSortBagsRightToLeft, GetInsertItemsLeftToRight or
      ConsoleGetAllCommands.
      Seen 2026-11-15: the chat ends at "accept calls missing: none.", with no threw line after it. (seen 2026-11-15, the owner's `/gt probe` screenshot)

## Dungeon and raid entrances on the map (2026-11-19)

Spec `docs/superpowers/specs/2026-11-19-map-entrance-pins-design.md`. Verified in source only.

- [x] The game's own pins cannot do this: `showDungeonEntrancesOnMap` reads 1 and
      `C_EncounterJournal.GetDungeonEntrancesForMap(1413)` gives 0 entrances.
      (seen 2026-11-19, the owner's `/run` lines: "1,0")
- [x] `C_Texture.GetAtlasInfo` answers for "Dungeon" and "Raid".
      (seen 2026-11-19, the owner's `/run` line: "true true")
- [ ] **Full client restart** first (MapPins.lua and MapEntrances.lua are new in the TOC). No Lua
      error on login; the Map tab shows eight checks, the sixth the new "Dungeon and raid entrances on the map",
      ticked, and the window still fits its rows.
- [ ] The Barrens' own map: a blue swirl at Wailing Caverns (45.5, 35.5), Razorfen Kraul
      (42.6, 88.5) and Razorfen Downs (50.0, 92.0), each on its door. Say if one is a square, not a
      swirl, or sits off its door.
- [ ] Hover a swirl: a small brown card beside it, the dungeon's name in gold and its levels
      ("Wailing Caverns  15-25"). It goes when the cursor leaves.
- [ ] Searing Gorge's map: one swirl at Blackrock Mountain; its card lists Blackrock Depths,
      Lower and Upper Blackrock Spire with their levels.
- [ ] A city: Orgrimmar's map shows Ragefire Chasm's swirl, Stormwind's The Stockade's.
- [ ] The swirls are big enough to find at a glance (32 units since 2026-11-19; they read small
      at 22, the owner). Say if they now crowd the map.
- [ ] The doors taken from other sites' guides (2026-11-19), each on its door or say how far off:
      The Hall of Thanes (Ironforge 43.5, 52.0), Ruins of Lordaeron (Undercity 71.6, 11.4 and
      Tirisfal Glades 61.9, 64.7), City of Dalaran (Alterac Mountains 8.8, 59.6), The Drowned City
      (Stranglethorn Vale 21.4, 27.9, underwater), Krol'dok Stronghold (Riverglades 37.5, 37.5),
      Alcaz Prison (Dustwallow Marsh 75.3, 14.1), Blackmaw Hold (Azshara 38.7, 33.4, the tunnel's
      mouth), Shaper's Terrace (Un'Goro Crater 48.1, 6.1).
- [ ] Dustwallow Marsh's map: a green swirl (not blue) at Onyxia's Lair, 52.3, 76.1, its card
      "Onyxia's Lair  Raid". On its way in, or say how far off.
- [ ] No swirl for a raid Blizzard has not announced: none at Zul'Gurub in Stranglethorn Vale,
      none at Naxxramas in the Eastern Plaguelands.
- [ ] Kalimdor's and Eastern Kingdoms' maps show no swirl; nor does a zone with no dungeon (Durotar).
- [ ] Zoom the map with the mouse wheel, if this build zooms: the swirls stay on their doors and
      keep their size.
- [ ] Right-click with the cursor over a swirl: the map still zooms out to the continent.
- [ ] A swirl near the map's right or top edge (Tirisfal's Scarlet Monastery, Badlands' Uldaman):
      its card opens inwards and is not cut off.
- [ ] The swirls and the corner card do not hide each other where it matters, and a quest or
      flight pin near a door can still be hovered.
- [ ] Untick the switch with the map open: every swirl goes at once. Tick it: they come back.
- [ ] `/gt probe` prints "entrance icons from the game: dungeon yes, raid yes; entrance pins built"
      and "you stand at X, Y on map N". Paste both.
- [ ] Standing at a door the table lacks, `/gt probe`'s "you stand at" line, pasted to Claude with
      the door's name, for each of: Excavation Site (the guides give Wetlands 48.1, 56.5 and
      53.4, 65.3 and disagree which is the door), and from 2026-12-09 Barrow Deeps and Hyjal
      Summit.

## Quest marks on nameplates (2026-11-21)

Spec `docs/superpowers/specs/2026-11-21-quest-marks-on-nameplates-design.md`. The count comes from
the mob's tooltip data; Forever has not yet been seen to type those lines, so the probe comes first.

- [ ] **Full client restart** first (QuestPlates.lua and PlateMarks.lua are new in the TOC). No Lua
      error on login; the Quests tab shows "Quest marks on nameplates" under the quest diamond,
      ticked, and the window still fits its rows.
- [ ] Target a mob one of your quests wants, then `/gt probe`: paste the "quest marks" line. It
      should read "target lines: [title] <quest name>; [objective] <...>: 4/10". Say if the
      objective line reads "[other]" (the game does not type them) or "(secret)" (its text is
      unreadable): either means the mark cannot work and the switch comes out.
- [x] With nameplates on (V), a quest mob's plate wears a mark above its name and a number.
      (seen 2026-11-21, the owner's screenshot: a Gordunni Mage-Lord, "1"; the square is now a gold "!")
- [ ] The number matches the mob's tooltip "x/y" (10 - 4 = 6), not always 1. If every mark reads 1,
      paste the probe's "quest marks" line: the text may be secret.
- [x] The mark sat a good way above the name (the plate frame is taller than its bar); the owner
      asked for closer (2026-11-21).
- [ ] The Quests tab shows a "Mark size" slider (8-32, at 12) under the switch; dragging it resizes
      every shown mark at once, the "!" staying a touch bigger than the number.
- [ ] After that: the mark sits just over the mob's name, and stays there when the plate is
      recycled for another mob (walk through a camp).
- [ ] Kill one: every shown mark of that mob drops by one within a moment.
- [ ] Finish the objective: the marks go.
- [ ] A mob of no quest of yours, a friendly NPC and another player: no mark.
- [ ] A mob that drops a quest item (a "Linen Scraps: 2/8" tooltip line): marked with 6.
- [ ] A mob two quests want: one mark, the smaller number.
- [ ] A named mob to slay with no figures on its tooltip line: marked with 1.
- [ ] The mark scales and fades with its plate (walk away, turn the camera).
- [ ] Untick the switch mid-fight: every mark goes at once. Tick it: they come back.
- [ ] `/gt probe` prints "quest marks: N plate(s) known, M marked" with sensible counts and no
      "threw:" for GetNamePlateForUnit, UnitIsRelatedToActiveQuest or C_TooltipInfo.GetUnit.
