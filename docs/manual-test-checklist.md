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
- [x] The window shows six tabs (Quests, Vendors, Loot, Social, Camera, Cinematics); the open one is gold.
      Each tab shows only its rows; the window keeps the same height on every tab; the "Show
      minimap button" check and "Hold Shift at an NPC or vendor to skip." stay under every tab.
- [x] Wider and taller (520 wide, rows 40 high, 2026-10-15): every tab name and every row label is
      fully visible, no "..." ("Cinematics", "Accept invites from friends"); rows are not cramped
      and the window still fits on screen.
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

- [ ] Auto train on, Vendors tab shows it (off by default); full client restart for the new file first.
- [ ] Class trainer with several green rows: all trained one after another, gold drops by the total, the
      rows turn gray, and closing says "Trained N for ...". Nothing in red is touched.
- [ ] Short of gold for the whole list: trains in list order until it cannot afford the next, then stops,
      no error spam in chat; the line counts only what was learned.
- [ ] Profession trainer for a craft you have: the next rank (Journeyman etc.) and recipes are trained.
- [ ] Profession trainer for a craft you do not have: nothing trained, no profession slot taken.
- [ ] Shift held while talking to the trainer: nothing trained, no line.
- [ ] Switch off: the trainer window is left as it is.
- [ ] Hunter pet trainer (if a hunter is handy): nothing trained.

## Loot

- [x] After a **full client restart** (Loot.lua is a new file): six tabs, every name fully visible
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
