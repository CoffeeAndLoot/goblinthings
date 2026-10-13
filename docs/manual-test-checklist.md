# Manual test checklist

In-game checks for what unit tests cannot reach. Only the owner runs the client.
Mark each with the build and date when walked; `[-]` is skipped by choice, with the reason.

## Install

- [ ] After the junction and a **full client restart**, Goblin Things is listed and enabled in the
      AddOns list with its round GT icon; no Lua error on login.
- [ ] `/gt probe` lists the eight settings (autoAccept true ... declineDuels false, cinematics
      repeats, cameraDistance a number), the CVar, the seen counts, a cinematic key like
      `Scourge:1420`, "none this session", and no "threw:".

## Window and minimap

- [ ] A round minimap button sits on the rim, clear of Goblin Flyout's: gold "GT" on a teal disc.
      Hover: "Goblin Things / Click for options, drag to move. / Time is money, friend."
- [ ] Dragging it slides it round the rim; `/reload`: it stays where it was put.
- [ ] Click, `/gt` and `/gt options` open the window; Escape or the X closes it.
- [ ] Esc > Options > AddOns lists "Goblin Things" with a gold "Open Goblin Things" button that opens the window.
- [ ] **Full client restart** first (TrackerSort.lua is new in the TOC).
- [ ] The window shows five tabs (Quests, Vendors, Social, Camera, Cinematics); the open one is gold.
      Each tab shows only its rows; the window keeps the same height on every tab; the "Show
      minimap button" check and "Hold Shift at an NPC or vendor to skip." stay under every tab.
- [ ] Close and reopen, and `/reload`: the window opens on the tab last used.
- [ ] The Quests tab: two checks, a gold "Quest tracker" sub-header, an "Only this zone" check,
      rows 1st / 2nd / 3rd each reading None | Level | Finished | This zone with every word fully
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
- [ ] Only this zone: a finished quest whose turn-in NPC is in another zone (e.g. Ziz Fizziks,
      Windshear Crag, seen from the Barrens) is hidden until you get there. Tell Claude if it shows.
- [ ] Only this zone plus 1st: Level: this zone's quests only, lowest level first.
- [ ] Only this zone off again (tiers None): every tracked quest is back; probe says
      "off (pass-through until /reload)".
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

## Social

- [ ] Decline duels on: a friend's duel request is refused, "Declined a duel from <name>." is said,
      and **no duel popup lingers** (open fact 2).
- [ ] Decline duels off: the duel popup appears as normal.
- [ ] Decline guild invites on: an invite is refused with "Declined a guild invite from <name>
      (<guild>)." and **no invite window lingers** (open fact 2).
- [ ] Decline guild invites off: the invite window appears as normal.

## Cinematics

- [ ] New character, Skip cinematics on Repeats only: the race intro plays. Then `/gt probe`: the
      last cinematic summary line shows what the game said (open fact 1; tell Claude what it was).
- [ ] Same race, another new character in the same zone: the intro is skipped.
- [ ] Mode All: an intro you have never seen is skipped.
- [ ] Mode Off: the intro plays.
- [ ] A flight path or any vehicle ride plays normally in every mode (it is not a cinematic).
