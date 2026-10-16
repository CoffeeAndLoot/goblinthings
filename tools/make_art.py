#!/usr/bin/env python3
"""Cut the addon's art out of the mockup sheets in tools/art and write the
TGAs the client loads, plus images/thumbnail.png. Never edit the TGAs by
hand: change the crops here and rerun.

  GoblinThings/Media/header.tga  2048x512: the plaque banner from
      tools/art/header-source.png (docs/art-spec.md), at its native 2000x508 in
      the top-left corner (no resampling, so it is as sharp at 4K as the
      source). Its flat backdrop is set to the window colour exactly, so laid
      edge to edge it is the header. Window.BANNER crops the canvas.
  GoblinThings/Media/icon.tga    256x256: the round goblin portrait (the
      minimap button and the AddOns-list icon), the sheet's backdrop cut away.
  images/thumbnail.png           512 px: the icon, for the Wago listing.

Run from anywhere: python tools/make_art.py [preview_dir]
"""

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SHEET = ROOT / "tools" / "art" / "sheet-banner.png"  # the 2172x724 concept sheet: the icon
BANNER_SOURCE = ROOT / "tools" / "art" / "header-source.png"  # 2000x750, made to docs/art-spec.md
MEDIA = ROOT / "GoblinThings" / "Media"
THUMBNAIL = ROOT / "images" / "thumbnail.png"

BANNER_BOX = (0, 122, 2000, 630)  # on the source; keep Window.BANNER in step
BANNER_CANVAS = (2048, 512)
WINDOW = (0x16, 0x17, 0x1A)  # Look.COLOUR.window

ICON_CENTRE, ICON_RADIUS = (1177, 548), 120  # the round portrait on the sheet, rivets included
ICON_SIZE = 256
THUMBNAIL_SIZE = 512


def on_window(im: Image.Image) -> Image.Image:
    """im with its flat backdrop shifted onto the window colour: pixels within
    a few levels of the backdrop move fully, the scene's own pixels not at all."""
    a = np.asarray(im.convert("RGB")).astype(float)
    backdrop = np.median(a[:20].reshape(-1, 3), axis=0)  # the top rows are all backdrop
    near = np.clip(1 - (np.abs(a - backdrop).max(axis=2) - 12) / 30, 0, 1)[..., None]
    out = a + (np.array(WINDOW) - backdrop) * near
    return Image.fromarray(np.clip(out, 0, 255).astype("uint8"))


def banner(source: Image.Image) -> Image.Image:
    canvas = Image.new("RGBA", BANNER_CANVAS, WINDOW + (255,))
    canvas.paste(on_window(source.crop(BANNER_BOX)), (0, 0))
    return canvas


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
    source = Image.open(BANNER_SOURCE).convert("RGB")
    MEDIA.mkdir(parents=True, exist_ok=True)
    banner(source).save(MEDIA / "header.tga")
    print("Wrote", MEDIA / "header.tga")
    icon(sheet, ICON_SIZE).save(MEDIA / "icon.tga")
    print("Wrote", MEDIA / "icon.tga")
    THUMBNAIL.parent.mkdir(parents=True, exist_ok=True)
    icon(sheet, THUMBNAIL_SIZE).save(THUMBNAIL)
    print("Wrote", THUMBNAIL)
    if len(sys.argv) > 1:  # previews for a human, on the window's dark grey
        out = Path(sys.argv[1])
        out.mkdir(parents=True, exist_ok=True)
        dark = (0x16, 0x17, 0x1A, 255)
        banner(source).crop((0, 0, BANNER_BOX[2] - BANNER_BOX[0], BANNER_BOX[3] - BANNER_BOX[1])).save(out / "header.png")
        i = icon(sheet, ICON_SIZE)
        Image.alpha_composite(Image.new("RGBA", i.size, dark), i).save(out / "icon-256.png")
        small = Image.alpha_composite(Image.new("RGBA", (31, 31), dark), i.resize((31, 31), Image.LANCZOS))
        small.resize((248, 248), Image.NEAREST).save(out / "icon-31-x8.png")
        print("Previews in", out)


if __name__ == "__main__":
    main()
