"""Writes GoblinThings/MapData.lua from the sources in tools/gathering/.

    python tools/make_gathering.py

Spec: docs/superpowers/specs/2026-11-14-map-gathering-lists-design.md. The
sources are read out of Wowhead's zone pages in a browser (Wowhead refuses a
plain script): wowhead-forever.json is Forever's own database, the authority;
wowhead-classic.json is Classic Era's, used for a zone or a fish list Forever's
does not have yet and marked as such in the output. MapData.lua is never
hand-edited: change a source or the rules here and run this again. It writes
nothing unless every check passes.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FOREVER = ROOT / "tools" / "gathering" / "wowhead-forever.json"
CLASSIC = ROOT / "tools" / "gathering" / "wowhead-classic.json"
OUT = ROOT / "GoblinThings" / "MapData.lua"

# UiMap ID -> (Wowhead area ID, the zone's name as the page titles it): every
# zone the readout describes. Mount Hyjal, Riverglades, Zephras Isle and
# Shen'dralas are Forever's own: only its database has them. (Its Darkspear
# Islands page, area 16606, has no objects or fishing list.)
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
    2482: (616, "Mount Hyjal"), 2548: (16591, "Riverglades"),
    2521: (16593, "Zephras Isle"), 2652: (16651, "Shen'dralas"),
}

# Zones in neither source yet (Wowhead asks for human verification after about
# 30 pages, and only the owner may pass it): they get no lists. Empty when
# every page has been read.
PENDING = set()

# Wowhead types quest objects as herbs and veins too, so every name must be
# one of these (kept) or one of QUEST_OBJECTS (dropped); a name in neither
# stops the run, so a new one is decided by a person, not let through.
HERBS = {
    "Peacebloom", "Silverleaf", "Earthroot", "Mageroyal", "Briarthorn", "Stranglekelp", "Bruiseweed",
    "Wild Steelbloom", "Grave Moss", "Kingsblood", "Liferoot", "Fadeleaf", "Goldthorn",
    "Khadgar's Whisker", "Wintersbite", "Firebloom", "Purple Lotus", "Arthas' Tears", "Sungrass",
    "Blindweed", "Ghost Mushroom", "Gromsblood", "Golden Sansam", "Dreamfoil", "Mountain Silversage",
    "Plaguebloom", "Icecap", "Black Lotus",
    # Not Classic Era's, and on Forever's pages with a real skill:
    "Wilted Peacebloom", "Stunted Silverleaf", "Dreamroot", "Moonroot", "Nightmare Moss",
    "Star Lotus", "Demonsage",
}
ORE = {
    "Copper Vein", "Tin Vein", "Silver Vein", "Iron Deposit", "Gold Vein", "Mithril Deposit",
    "Truesilver Deposit", "Dark Iron Deposit", "Small Thorium Vein", "Rich Thorium Vein",
    "Incendicite Mineral Vein", "Lesser Bloodstone Deposit", "Indurium Mineral Vein",
    "Small Obsidian Chunk", "Large Obsidian Chunk",
    # Not Classic Era's, and on Forever's pages:
    "Poor Copper Vein", "Chunk of Amber", "Large Chunk of Amber", "Fool's Gold Vein",
    "Cold Iron Deposit", "Greater Moonstone Formation", "Starsilver Vein", "Heavy Thorium Vein",
}
QUEST_OBJECTS = {
    "Beached Sea Creature", "Skeletal Sea Turtle", "Incendia Agave", "Gloom Weed", "Doom Weed",
    "Tomb Weed", "Serpentbloom", "Violet Tragan", "Hyjal Silphium",
}
# An ooze-covered vein is its plain vein to a miner.
ORE_ALIAS = {"Thorium Vein": "Small Thorium Vein"}

# Wowhead item class.subclass of a catch worth listing: meat (the raw fish),
# herbs (Stranglekelp), "other" trade goods (Forever files Oily Blackmouth,
# the eels and clams here), reagents (Classic's place for the same) and food
# and drink (Deviate Fish, Darkshore Grouper). Gear, potions, trunks and
# quest items are not.
FISH_CLASSES = {"7.8", "7.9", "7.11", "15.1", "0.5"}
FISH_SHARE = 3    # percent of the zone's whole catch
FISH_ROWS = 8
FISH_CASTS = 100  # fewer catches than this is too few to trust
FLOORS = {"HERBS": 25, "ORE": 25, "FISH": 20}  # zones that must yield a list


def fail(message):
    sys.exit("make_gathering: " + message + " (nothing written)")


def nodes(rows, allowed, where):
    best = {}
    for name, skill in rows:
        if name.startswith("Ooze Covered "):
            name = name[len("Ooze Covered "):]
        name = ORE_ALIAS.get(name, name)
        if name in QUEST_OBJECTS:
            continue
        if name not in allowed:
            fail("%s lists %r: add it to HERBS, ORE or QUEST_OBJECTS" % (where, name))
        if name not in best or skill < best[name]:
            best[name] = skill
    return sorted(best.items(), key=lambda row: (row[1], row[0]))


def catches(page):
    if page is None or page.get("fish") is None or page["fishTotal"] < FISH_CASTS:
        return []
    total = page["fishTotal"]
    kept = [(name, round(count * 100 / total)) for _item, name, count, kind in page["fish"]
            if kind in FISH_CLASSES and count * 100 >= FISH_SHARE * total]
    kept.sort(key=lambda row: (-row[1], row[0]))
    return kept[:FISH_ROWS]


def page_of(source, area, name):
    page = source["zones"].get(str(area))
    if page is None:
        return None
    if not page["title"].startswith(name):
        fail("area %d is titled %r, not %s" % (area, page["title"], name))
    if page.get("herbs") is None or page.get("ore") is None:
        fail("%s has no objects list" % name)
    return page


def lua_lists(name, lists):
    out = ["    %s = {" % name]
    for map_id in sorted(lists):
        rows = ", ".join('{ "%s", %d }' % (row[0].replace("\\", "\\\\").replace('"', '\\"'), row[1])
                         for row in lists[map_id])
        out.append("        -- %s" % ZONES[map_id][1])
        out.append("        [%d] = { %s }," % (map_id, rows))
    out.append("    },")
    return out


def lua_set(name, ids):
    return ["    %s = { %s }," % (name, ", ".join("[%d] = true" % i for i in sorted(ids)))]


def main():
    forever = json.loads(FOREVER.read_text(encoding="utf-8"))
    classic = json.loads(CLASSIC.read_text(encoding="utf-8"))
    lists = {"HERBS": {}, "ORE": {}, "FISH": {}}
    classic_nodes, classic_fish = set(), set()
    for map_id, (area, name) in ZONES.items():
        if map_id in PENDING:
            continue
        ours, theirs = page_of(forever, area, name), page_of(classic, area, name)
        page = ours or theirs
        if page is None:
            fail("%s (area %d) is in neither source" % (name, area))
        herbs = nodes(page["herbs"], HERBS, name)
        ore = nodes(page["ore"], ORE, name)
        if ours is None and (herbs or ore):
            classic_nodes.add(map_id)
        fish = catches(ours)
        if not fish:
            fish = catches(theirs)
            if fish:
                classic_fish.add(map_id)
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
        "-- GENERATED by tools/make_gathering.py from tools/gathering/*.json: Wowhead's",
        "-- Forever zone pages (read %s) and, for the zones and fish lists in" % forever["read"],
        "-- CLASSIC_NODES and CLASSIC_FISH, its Classic Era pages (read %s)." % classic["read"],
        "-- Never hand-edited: change a source or the script and run it again.",
        "-- HERBS and ORE: { name, skill } easiest first. FISH: { name, percent of the",
        "-- zone's catch } most common first. Keyed by UiMap ID. Pure data.",
        "-- luacheck: no max line length",
        "local MapData = {",
    ]
    for key in ("HERBS", "ORE", "FISH"):
        lines += lua_lists(key, lists[key])
    lines += lua_set("CLASSIC_NODES", classic_nodes)
    lines += lua_set("CLASSIC_FISH", classic_fish)
    lines += ["}", "ns.MapData = MapData", "", "return MapData", ""]
    OUT.write_text("\n".join(lines), encoding="utf-8", newline="\n")

    def named(ids):
        return ", ".join(ZONES[i][1] for i in sorted(ids)) or "none"

    print("wrote %s: %d zones with herbs, %d with ore, %d with fish"
          % (OUT.relative_to(ROOT), len(lists["HERBS"]), len(lists["ORE"]), len(lists["FISH"])))
    print("herbs and ore from Classic's pages: " + named(classic_nodes))
    print("fish from Classic's pages: " + named(classic_fish))
    no_fish = set(ZONES) - PENDING - set(lists["FISH"])
    print("no fish list (none on the page, or too few catches, in either source): " + named(no_fish))
    if PENDING:
        print("NOT READ YET, no lists: " + named(PENDING))


if __name__ == "__main__":
    main()
