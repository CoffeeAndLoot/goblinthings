# Art spec: the header banner

For the image generator that made `tools/art/concept-sheet.png`. Feed it that sheet as the
reference so it is the same goblin, and ask for one plain image to this spec. Drop the result in
`tools/art/header-source.png`; `tools/make_art.py` cuts `GoblinThings/Media/header.tga` from it.

## The one hard rule

The image is the header. It is laid straight into a window whose colour is `#16171A`, edge to
edge, under a 2 px gold line. So the backdrop must be that colour, flat, and the scene must fade
into it on its own, with no frame, box, rule or edge of any kind. If the backdrop is any other
shade, it reads as a picture pasted into the window.

## Dimensions

- **2048 x 512 px**, landscape, PNG, no transparency needed.
- Everything that matters sits inside the left **1850 px**; the right ~200 px is backdrop with the
  scene's props fading out, so the window's close button can sit over it.
- Keep the goblin's ears and the wrench tip at least **40 px** below the top edge: the gold line
  runs along the top.

## Content

Exactly the Option 3 ("Name on Plaque") layout from the sheet, same goblin, same palette:

- **Left third:** the green goblin, grinning, wrench raised in his right hand, elbow on the desk,
  the teal potion flask, crate, gold coins and gears around him, the green glow behind.
- **Centre and right:** the riveted wooden plaque with iron corner brackets, reading
  **GOBLIN THINGS** in the gold beveled lettering, and under it **Time is money, friend.** in the
  cream serif. The plaque's right bracket ends around x = 1800.
- Pipes and props may trail off to the right, dissolving into the backdrop.

## Backdrop and edges

- Backdrop colour **#16171A** (R 22, G 23, B 26): cool, near-black. **Not** warm brown-black, not a
  gradient, not a wall or workshop interior.
- The scene's glow, desk and props **fade into that colour** toward the top, bottom and right.
  The bottom edge in particular must be a soft dissolve, not a desk line or a gold rule.
- The left edge may be cut by the crate and props: it meets the window's left edge.
- No border, no vignette ring, no drop shadow around the whole image, no text or labels besides
  the plaque's two lines.

## Prompt

Paste with the sheet attached as reference:

> Using the attached sheet as the character and style reference, one single image, 2048 by 512
> pixels, landscape. Recreate the "Option 3 - Name on Plaque" banner exactly: the same grinning
> green goblin on the left, wrench raised, elbow on the desk, teal potion flask, crate, coins and
> gears, green glow behind him; centre and right, the riveted wooden plaque with iron corner
> brackets reading "GOBLIN THINGS" in gold beveled lettering and "Time is money, friend." in cream
> serif beneath. The plaque ends about 250 pixels before the right edge. The background is a flat,
> uniform near-black of hex #16171A, cool not brown; the scene's glow, desk and props fade softly
> into that colour at the top, bottom and right edges. No frame, no border, no vignette, no gold
> line, no desk edge line, no labels, no UI, no other text. Nothing within 40 pixels of the top
> edge. Painterly Warcraft style, crisp at full size.

## Check before handing it over

- Open it beside a swatch of `#16171A`: the corners should be indistinguishable from the swatch.
- The bottom row of pixels is backdrop, not desk.
- 2048 x 512 exactly (resize is fine if the generator picks a near size; keep the aspect 4:1).

## Optional: the round icon

If the same session can also make the icon: **512 x 512**, the goblin's head and shoulders inside
the riveted bronze ring from the sheet's "Fav / Promo Icon", on the same `#16171A` backdrop
(it is cut to a circle, so the backdrop does not show). Save as `tools/art/icon-source.png`.
