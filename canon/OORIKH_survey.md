# OORIKH THE GREAT — Verified Survey & 3D Scan

Image-measured reconstruction of the fortified river capital. Built by analyzing
4 reference angles (IMG_8625/8626/8627/8628) + canon facts. Measurements below are
**measured/derived**; items marked *(lore)* are descriptive estimates that cannot be
read from AI reference images.

## Measurement method (followed every pass)
1. Open the reference images, segment the city by **texture/variance** (buildings = high
   texture; desert/sky/water = smooth).
2. PCA on the city mask → oval axes + tilt; correct oblique vertical squash (~0.6).
3. Radial brightness profile → concentric ring-street count.
4. Anchor absolute scale to footprint/population (no metric reference exists in the images).

## Verified plan (image-corrected)

| Metric | Value | Source |
|--------|-------|--------|
| Plan ratio (long:short) | **1.70 : 1** | measured (IMG_8627, oblique-corrected) |
| Long axis | 1,838 m | derived (ratio + area) |
| Short axis | 1,081 m | derived |
| Wall perimeter | 4,662 m | derived (Ramanujan) |
| Wall height | 14 m | canon |
| Towers | 34 (gap ≈137 m) | canon + image |
| Gates | 7 (gap ≈666 m) | canon |
| Bridges | **4** | image (corrected from 3) |
| Terraces | 7 × 8 m = 56 m hill | canon + image |
| Footprint | ≈1.56 km² | derived (28k pop @ 18k/km²) |
| River port quay | 400 m, 8 berths | canon |
| River path | hugs EAST + SOUTH edge | image (corrected from central) |

## Zone descriptions

### 👑 Crown District (north summit)
- Contents: royal palace + domed hall + ~8 noble blocks + gardens
- Count: ~12 structures · Footprint 14–40 m · Height 14–70 m
- Dome curvature: hemispherical R≈52 m *(lore)* · Wall batter ~4° *(lore)*
- Est. age: ~220 yrs (oldest core) *(lore)*

### 🛒 Merchant Ring (mid)
- Contents: guild houses, market halls, caravanserais
- Footprint 9–15 m · Height 6–12 m · Roof arch ~8° *(lore)*
- Est. age: ~150 yrs *(lore)*

### 🏘️ Common Quarters (lower/outer)
- Contents: dense dwellings, workshops, cisterns
- Footprint 5–10 m · Height 4–12 m · Flat/low roofs ~3° *(lore)*
- Est. age: ~90 yrs, rebuilt in layers *(lore)*

### ⚓ River Port (south-east bank)
- Contents: 400 m quay, 8 warehouses, 8 berths, jetties
- Warehouse 34×26×18 m · 4 bridges over the river
- Est. age: ~110 yrs *(lore)*

### 🧱 Curtain Wall + Gates
- 34 towers (20×28 m, gap 137 m) · 7 gates (twin towers, h≈38 m)
- Wall h 14 m, perimeter 4,662 m · oval curvature 1.70:1 · batter ~5° *(lore)*
- Est. age: ~260 yrs (defensive core) *(lore)*

## Palette (extracted from images, hex)
`#CEB497` `#BC9B79` `#AC8461` `#927860` `#87664B` `#68503D` — warm honey sandstone,
terracotta roofs, deep alley shadows. No glow.

## 3D scan
Interactive Three.js organic ray-scan in `canon/oorikh_scan.js`
(render in a Three.js viewer; globals: THREE, OrbitControls, EffectComposer,
RenderPass, UnrealBloomPass, canvas, width, height).

## Honesty note
A single set of AI images cannot yield cm-accurate or true depth measurements, nor real
ages/curvatures. Ratios are measured; absolute metres are anchored to footprint/population;
ages and curvatures are lore estimates. Give one confirmed real dimension to calibrate
absolute scale exactly.
