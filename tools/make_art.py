#!/usr/bin/env python3
"""Cut the addon's art out of the source in tools/art and write the
TGA the client loads, plus images/thumbnail.png. Never edit the TGA by
hand: change the crop here and rerun. (The window's plaque banner was cut here
too until 2026-11-14, when the window went back to the game's own look;
tools/art/header-source.png and docs/art-spec.md are what is left of it.)

  GoblinThings/Media/icon.tga    256x256: the round goblin portrait (the
      minimap button and the AddOns-list icon), the sheet's backdrop cut away.
  images/thumbnail.png           512 px: the icon, for the Wago listing.

Run from anywhere: python tools/make_art.py [preview_dir]
"""

import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SHEET = ROOT / "tools" / "art" / "concept-sheet.png"  # the 2172x724 concept sheet: the icon
MEDIA = ROOT / "GoblinThings" / "Media"
THUMBNAIL = ROOT / "images" / "thumbnail.png"

ICON_CENTRE, ICON_RADIUS = (1177, 548), 120  # the round portrait on the sheet, rivets included
ICON_SIZE = 256
THUMBNAIL_SIZE = 512


def icon(sheet: Image.Image, size: int) -> Image.Image:
    (cx, cy), r = ICON_CENTRE, ICON_RADIUS
    square = sheet.crop((cx - r, cy - r, cx + r, cy + r)).convert("RGBA")
    big = square.resize((size * 4, size * 4), Image.LANCZOS)  # mask at 4x for a smooth rim
    mask = Image.new("L", big.size, 0)
    inset = 3  # stay inside the rim's outer edge
    ImageDraw.Draw(mask).ellipse((inset, inset, big.width - 1 - inset, big.height - 1 - inset), fill=255)
    big.putalpha(mask)
    return big.resize((size, size), Image.LANCZOS)


def main():
    sheet = Image.open(SHEET).convert("RGB")
    MEDIA.mkdir(parents=True, exist_ok=True)
    icon(sheet, ICON_SIZE).save(MEDIA / "icon.tga")
    print("Wrote", MEDIA / "icon.tga")
    THUMBNAIL.parent.mkdir(parents=True, exist_ok=True)
    icon(sheet, THUMBNAIL_SIZE).save(THUMBNAIL)
    print("Wrote", THUMBNAIL)
    if len(sys.argv) > 1:  # previews for a human, on the window's brown
        out = Path(sys.argv[1])
        out.mkdir(parents=True, exist_ok=True)
        dark = (0x1E, 0x14, 0x0C, 255)  # Look.COLOUR.window
        i = icon(sheet, ICON_SIZE)
        Image.alpha_composite(Image.new("RGBA", i.size, dark), i).save(out / "icon-256.png")
        small = Image.alpha_composite(Image.new("RGBA", (31, 31), dark), i.resize((31, 31), Image.LANCZOS))
        small.resize((248, 248), Image.NEAREST).save(out / "icon-31-x8.png")
        print("Previews in", out)


if __name__ == "__main__":
    main()
