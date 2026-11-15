"""Writes GoblinThings/MapData.lua from tools/gathering/wowhead-classic.json.

    python tools/make_gathering.py

Spec: docs/superpowers/specs/2026-11-14-map-gathering-lists-design.md. The
source is read out of Wowhead's Classic zone pages in a browser (Wowhead
refuses a plain script); this turns it into the lists the map's corner shows.
MapData.lua is never hand-edited: change the source or the rules here and run
this again. It writes nothing unless every check passes.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "tools" / "gathering" / "wowhead-classic.json"
OUT = ROOT / "GoblinThings" / "MapData.lua"

# UiMap ID -> (Wowhead area ID, the zone's name as the page titles it): every
# zone in MapInfo.LEVELS that Wowhead Classic has (Mount Hyjal and Riverglades
# are Forever's own).
ZONES = {
    1411: (14, "Durotar"), 1412: (215, "Mulgore"), 1438: (141, "Teldrassil"),
    1413: (17, "The Barrens"), 1439: (148, "Darkshore"), 1442: (406, "Stonetalon Mountains"),
    1440: (331, "Ashenvale"), 1441: (400, "Thousand Needles"), 1443: (405, "Desolace"),
    1445: (15, "Dustwallow Marsh"), 1444: (357, "Feralas"), 1446: (440, "Tanaris"),
    1447: (16, "Azshara"), 1448: (361, "Felwood"), 1449: (490, "Un'Goro Crater"),
    1452: (618, "Winterspring"), 1450: (493, "Moonglade"), 1451: (1377, "Silithus"),
    1420: (85, "Tirisfal Glades"), 1426: (1, "Dun Morogh"), 1429: (12, "Elwynn Forest"),
    1421: (130, "Silverpine Forest"), 1436: (40, "Westfall"), 1432: (38, "Loch Modan"),
    1433: (44, "Redridge Mountains"), 1431: (10, "Duskwood"), 1424: (267, "Hillsbrad Foothills"),
    1437: (11, "Wetlands"), 1416: (36, "Alterac Mountains"), 1417: (45, "Arathi Highlands"),
    1434: (33, "Stranglethorn Vale"), 1418: (3, "Badlands"), 1435: (8, "Swamp of Sorrows"),
    1425: (47, "The Hinterlands"), 1427: (51, "Searing Gorge"), 1419: (4, "Blasted Lands"),
    1428: (46, "Burning Steppes"), 1422: (28, "Western Plaguelands"),
    1423: (139, "Eastern Plaguelands"), 1430: (41, "Deadwind Pass"),
}

# Not read yet: Wowhead asked for human verification after 32 pages on
# 2026-11-14. These get no lists until their pages are in the source; empty
# this set then.
PENDING = {1435, 1425, 1427, 1419, 1428, 1422, 1423, 1430}

# Zones with a Fishing line (MapInfo.FISHING): only these can show a fish list.
NO_FISHING_LINE = {1418, 1427, 1419}

# Wowhead types quest objects as herbs and veins too (Darkshore's "Beached Sea
# Creature"), and its Classic pages carry other seasons' nodes, so a name must
# be a Classic one to be kept. Every name dropped is printed.
HERBS = {
    "Peacebloom", "Silverleaf", "Earthroot", "Mageroyal", "Briarthorn", "Stranglekelp", "Bruiseweed",
    "Wild Steelbloom", "Grave Moss", "Kingsblood", "Liferoot", "Fadeleaf", "Goldthorn",
    "Khadgar's Whisker", "Wintersbite", "Firebloom", "Purple Lotus", "Arthas' Tears", "Sungrass",
    "Blindweed", "Ghost Mushroom", "Gromsblood", "Golden Sansam", "Dreamfoil", "Mountain Silversage",
    "Plaguebloom", "Icecap", "Black Lotus",
}
ORE = {
    "Copper Vein", "Tin Vein", "Silver Vein", "Iron Deposit", "Gold Vein", "Mithril Deposit",
    "Truesilver Deposit", "Dark Iron Deposit", "Small Thorium Vein", "Rich Thorium Vein",
    "Incendicite Mineral Vein", "Lesser Bloodstone Deposit", "Indurium Mineral Vein",
    "Small Obsidian Chunk", "Large Obsidian Chunk",
}
# An ooze-covered vein is its plain vein to a miner.
ORE_ALIAS = {"Thorium Vein": "Small Thorium Vein"}

# Wowhead item class.subclass of a catch worth listing: meat (the raw fish),
# herbs (Stranglekelp), clams, reagents (Oily Blackmouth, Firefin Snapper, the
# eels) and food and drink (Deviate Fish, Winter Squid). Gear, potions, trunks
# and quest items are not.
FISH_CLASSES = {"7.8", "7.9", "7.11", "15.1", "0.5"}
FISH_SHARE = 3    # percent of the zone's whole catch
FISH_ROWS = 8
FISH_CASTS = 100  # fewer catches than this is too few to trust
FLOORS = {"HERBS": 25, "ORE": 25, "FISH": 20}  # zones that must yield a list


def fail(message):
    sys.exit("make_gathering: " + message + " (nothing written)")


def nodes(rows, allowed, dropped):
    best = {}
    for name, skill in rows:
        if name.startswith("Ooze Covered "):
            name = name[len("Ooze Covered "):]
        name = ORE_ALIAS.get(name, name)
        if name not in allowed:
            dropped.add(name)
        elif name not in best or skill < best[name]:
            best[name] = skill
    return sorted(best.items(), key=lambda row: (row[1], row[0]))


def catches(rows, total):
    if total < FISH_CASTS:
        return []
    kept = []
    for _item, name, count, kind in rows:
        share = round(count * 100 / total)
        if kind in FISH_CLASSES and count * 100 >= FISH_SHARE * total:
            kept.append((name, share))
    kept.sort(key=lambda row: (-row[1], row[0]))
    return kept[:FISH_ROWS]


def lua_table(name, lists, fmt):
    out = ["    %s = {" % name]
    for map_id in sorted(lists):
        rows = ", ".join(fmt % (row[0].replace("\\", "\\\\").replace('"', '\\"'), row[1])
                         for row in lists[map_id])
        out.append("        -- %s" % ZONES[map_id][1])
        out.append("        [%d] = { %s }," % (map_id, rows))
    out.append("    },")
    return out


def main():
    source = json.loads(SOURCE.read_text(encoding="utf-8"))
    pages = source["zones"]
    lists = {"HERBS": {}, "ORE": {}, "FISH": {}}
    dropped = set()
    for map_id, (area, name) in ZONES.items():
        if map_id in PENDING:
            continue
        page = pages.get(str(area))
        if page is None:
            fail("%s (area %d) is not in the source" % (name, area))
        if not page["title"].startswith(name):
            fail("area %d is titled %r, not %s" % (area, page["title"], name))
        if page.get("herbs") is None or page.get("ore") is None:
            fail("%s has no objects list" % name)
        herbs = nodes(page["herbs"], HERBS, dropped)
        ore = nodes(page["ore"], ORE, dropped)
        fish = []
        if page.get("fish") is not None and map_id not in NO_FISHING_LINE:
            fish = catches(page["fish"], page["fishTotal"])
        for key, rows in (("HERBS", herbs), ("ORE", ore), ("FISH", fish)):
            if rows:
                lists[key][map_id] = rows
    for key, floor in FLOORS.items():
        if len(lists[key]) < floor:
            fail("only %d zones yield %s, under %d: has the page layout changed?"
                 % (len(lists[key]), key, floor))

    lines = [
        "local _, ns = ...",
        "",
        "-- GENERATED by tools/make_gathering.py from tools/gathering/wowhead-classic.json",
        "-- (Wowhead's Classic zone pages, read %s). Never hand-edited: change the" % source["read"],
        "-- source or the script and run it again. Classic figures, unverified on Forever.",
        "-- HERBS and ORE: { name, skill } easiest first. FISH: { name, percent of the",
        "-- zone's catch } most common first. Keyed by UiMap ID. Pure data.",
        "-- luacheck: no max line length",
        "local MapData = {",
    ]
    lines += lua_table("HERBS", lists["HERBS"], '{ "%s", %d }')
    lines += lua_table("ORE", lists["ORE"], '{ "%s", %d }')
    lines += lua_table("FISH", lists["FISH"], '{ "%s", %d }')
    lines += ["}", "ns.MapData = MapData", "", "return MapData", ""]
    OUT.write_text("\n".join(lines), encoding="utf-8", newline="\n")

    print("wrote %s: %d zones with herbs, %d with ore, %d with fish"
          % (OUT.relative_to(ROOT), len(lists["HERBS"]), len(lists["ORE"]), len(lists["FISH"])))
    if dropped:
        print("dropped (not a Classic node name): " + ", ".join(sorted(dropped)))
    if PENDING:
        print("NOT READ YET, no lists: " + ", ".join(ZONES[i][1] for i in sorted(PENDING)))


if __name__ == "__main__":
    main()
