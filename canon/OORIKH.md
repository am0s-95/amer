# OORIKH THE GREAT — Canon Reference

> Fortified river capital. This file LOCKS the canonical look so the city
> reproduces identically across every generation. Same prompt + same seed = same city.

## Locked generation spec

- **Engine:** Pollinations FLUX (free) — `.claude/skills/banana/scripts/generate_free.py`
- **Seed (LOCKED):** `42`  ← never change this for canon shots; change only for alternate angles
- **Aspect:** panoramic ~21:9 (`--width 2560 --height 1097`)
- **Model:** `flux`

### Canonical prompt (verbatim)

```
Cinematic high-altitude aerial of fortified oval river capital OORIKH, crown palace and grid district on the northern summit, seven stepped terraces of pale honey sandstone buildings with terracotta roofs, river with one major and two secondary bridges, busy river port with quay and warehouses, oval curtain wall with many towers and seven fortified gates, golden hour, ultra detailed, sharp focus, intricate masonry
```

### Reproduce it (run on a machine with open network — own PC)

```bash
python .claude/skills/banana/scripts/generate_free.py \
  --prompt "Cinematic high-altitude aerial of fortified oval river capital OORIKH, crown palace and grid district on the northern summit, seven stepped terraces of pale honey sandstone buildings with terracotta roofs, river with one major and two secondary bridges, busy river port with quay and warehouses, oval curtain wall with many towers and seven fortified gates, golden hour, ultra detailed, sharp focus, intricate masonry" \
  --width 2560 --height 1097 --seed 42 \
  --out OORIKH_CANON.jpg
```

## Canon facts (the design rules)

| Element | Canon |
|---------|-------|
| Shape | Elongated OVAL walled city on a central hill |
| Summit (north) | Crown Palace + formal grid Crown District |
| Slopes | SEVEN stepped terraces; Merchant (mid) → Common (lower) |
| River | River Orim through southern lower third |
| Bridges | ONE major + TWO secondary |
| Port | River port, 400m quay, 8 berths, warehouses |
| Wall | One continuous 14m oval curtain wall, 34 towers, SEVEN gates |
| Population | ~28,000 |
| Materials | Pale honey sandstone, aged dark-oak, wrought black iron, muted bronze-gold sun emblems, cream-linen banners |
| Forbidden | NOT Roman/Gothic/Arabian/Persian palace; NO fantasy spires, NO glow |

## Max-resolution workflow

1. Generate at `--width 2560 --height 1097` (above).
2. Upscale **4x–8x** with the FREE desktop app **Upscayl**
   (download the app, NOT the website): https://github.com/upscayl/upscayl/releases
3. Final canon plate lives in `canon/reference_images/`.

## Notes

- Keep the chosen hero image in `canon/reference_images/OORIKH_CANON.png`.
- For alternate views (night, ground level, port close-up) keep the prompt's
  canon facts intact and change only camera/time words; vary `--seed` for options.
