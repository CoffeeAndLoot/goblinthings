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
- [ ] The window shows five gold headers (Quests, Vendors, Social, Camera, Cinematics), eight rows, the
      "Show minimap button" check and "Hold Shift at an NPC or vendor to skip." Nothing overlaps.
- [ ] Each check flips on click and stays flipped after `/reload`.
- [ ] Off | Repeats only | All: the chosen one is gold; it stays after `/reload`.
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
- [ ] Shift held while talking to the NPC: nothing is accepted or turned in that visit.
- [ ] Each switch off on its own: only the other thing happens.

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
