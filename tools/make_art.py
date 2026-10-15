#!/usr/bin/env python3
"""Cut the addon's art out of the mockup sheets in tools/art and write the
TGAs the client loads, plus images/thumbnail.png. Never edit the TGAs by
hand: change the crops here and rerun.

  GoblinThings/Media/header.tga  2048x512: the plaque banner, at the sheet's
      native 1390x338 in the top-left corner (no resampling, so it is as sharp
      at 4K as the source), its edges feathered to alpha so it melts into the
      window. Window.BANNER crops the canvas with SetTexCoord.
  GoblinThings/Media/icon.tga    256x256: the round goblin portrait (the
      minimap button and the AddOns-list icon), the sheet's backdrop cut away.
  images/thumbnail.png           512 px: the icon, for the Wago listing.

Run from anywhere: python tools/make_art.py [preview_dir]
"""

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SHEET = ROOT / "tools" / "art" / "sheet-banner.png"  # the 2172x724 concept sheet (lossless)
MEDIA = ROOT / "GoblinThings" / "Media"
THUMBNAIL = ROOT / "images" / "thumbnail.png"

BANNER_BOX = (0, 0, 1390, 338)  # on the sheet, above its gold rule; keep Window.BANNER in step
BANNER_CANVAS = (2048, 512)
FEATHER = 28  # px of the banner's edge that fade to transparent

ICON_CENTRE, ICON_RADIUS = (1177, 548), 120  # the round portrait on the sheet, rivets included
ICON_SIZE = 256
THUMBNAIL_SIZE = 512


def feathered(im: Image.Image, px: int) -> Image.Image:
    """im with its border faded to alpha 0 over px pixels (a blurred inset)."""
    w, h = im.size
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rectangle((px, px, w - 1 - px, h - 1 - px), fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(px / 2))
    out = im.convert("RGBA")
    out.putalpha(mask)
    return out


def banner(sheet: Image.Image) -> Image.Image:
    canvas = Image.new("RGBA", BANNER_CANVAS, (0, 0, 0, 0))
    canvas.paste(feathered(sheet.crop(BANNER_BOX), FEATHER), (0, 0))
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
    MEDIA.mkdir(parents=True, exist_ok=True)
    banner(sheet).save(MEDIA / "header.tga")
    print("Wrote", MEDIA / "header.tga")
    icon(sheet, ICON_SIZE).save(MEDIA / "icon.tga")
    print("Wrote", MEDIA / "icon.tga")
    THUMBNAIL.parent.mkdir(parents=True, exist_ok=True)
    icon(sheet, THUMBNAIL_SIZE).save(THUMBNAIL)
    print("Wrote", THUMBNAIL)
    if len(sys.argv) > 1:  # previews for a human, on the window's dark grey
        out = Path(sys.argv[1])
        out.mkdir(parents=True, exist_ok=True)
        dark = (22, 22, 24, 255)
        b = banner(sheet).crop(BANNER_BOX)
        Image.alpha_composite(Image.new("RGBA", b.size, dark), b).save(out / "header.png")
        i = icon(sheet, ICON_SIZE)
        Image.alpha_composite(Image.new("RGBA", i.size, dark), i).save(out / "icon-256.png")
        small = Image.alpha_composite(Image.new("RGBA", (31, 31), dark), i.resize((31, 31), Image.LANCZOS))
        small.resize((248, 248), Image.NEAREST).save(out / "icon-31-x8.png")
        print("Previews in", out)


if __name__ == "__main__":
    main()
