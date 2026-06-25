# 🏛️ OORIKH — 15 Workflows to Build the "Made by Humans, not AI" Look

Goal: a photoreal, hand-crafted, organically-distributed world (Crimson-Desert /
Unreal-5 quality) that nobody can flag as AI. The anti-AI signal = real scanned
materials + hand kitbash + lived-in decals + filmic compositing + rule-based organic
scatter. Do these in order; each is a self-contained step you can run with Claude + Blender MCP.

## Foundation
**1. Procedural city skeleton (Geometry Nodes)** — drive the oval plan, 7 terraces,
ring-roads, curtain wall, 34 towers, 7 gates, 4 bridges from curves + GN. Built-in
jitter = organic. (Use `canon/oorikh_scan.js` proportions: ratio 1.70, 1838×1081 m.)
→ covers: layout, walls, towers, gates, terraces, roads.

**2. Modular kitbash building system** — hand-model a small library of wall/window/
door/roof/balcony pieces; GN assembles endless unique houses from them.
→ buildings, windows, doors, facades.

**3. Sculpted + displaced terrain** — sculpt the central hill, displacement + erosion
for the 7 terraces and soil; retaining walls per level.
→ terrain, soil, terraces.

## Surfacing (the photoreal / anti-AI core)
**4. Megascans / Poly Haven PBR surfacing** — real scanned honey-sandstone, terracotta,
cobblestone, dirt on every surface (palette: #CEB497 #BC9B79 #AC8461 #87664B).
→ all materials. This is the #1 "not AI" signal.

**5. Decal & grunge layer** — dirt streaks, water stains, cracks, soot, banners, hung
laundry, signage via decals. Lived-in imperfection AI can't fake.
→ visual identity, weathering.

## Distribution (organic, rule-based)
**6. Rock & boulder scatter (GN instance-on-points)** — scanned rocks on terrain,
wall bases, riverbanks with density maps + random rotation/scale.
→ rocks, debris.

**7. Vegetation scatter** — palms, scrub, garden greenery via GN/BlenderKit density
painting; denser in palace gardens, sparse in commons.
→ trees, gardens.

**8. Props & set-dressing scatter** — boats at the quay, carts on avenues, market
stalls, canopies/umbrellas, crates, barrels — placed by GN rules (near roads/port).
→ boats, carts, umbrellas/canopies, street life.

**9. Crowd / agent scatter** — low-poly people and animals on streets and the port,
density by district, for scale and life.
→ population, scale cues.

## Hero craft (bespoke modeling)
**10. Hero asset modeling** — hand-model the Crown Palace + domed hall, the 7 gates,
the main bridge, the port quay — the camera's focal points get real geometry.
→ palaces, gates, bridges, quay.

**11. River system** — flow mesh with foam/caustics, carved banks hugging the east+south
edge, 4 bridges crossing; reflections + slight current.
→ river, water.

## Motion & effects (the reel energy)
**12. Simulation nodes** — debris/rock-flow, falling dust, cloth for banners/sails
(Blender 4.x simulation zones) — the satisfying motion from the reference reel.
→ effects, banners, debris.

**13. Particle FX & atmosphere** — wind-blown dust, embers, river spray, birds, smoke
from chimneys; volumetric haze.
→ visual effects, atmosphere.

**14. Lighting & atmosphere** — HDRI golden-hour + area lights + volumetric god-rays;
night variant with lantern/window emissives. Long soft shadows, light haze (canon mood).
→ lighting, mood, day/night.

## Finish (the signature look)
**15. Cinematic camera + compositing** — flythrough / parallax / focus-pull camera,
then Blender compositor: filmic grade, subtle bloom, lens dirt, chromatic aberration,
film grain. This filmic finish is what reads as "human-shot", not AI.
→ motion design, color grade, final identity.

---

## Anti-AI identity checklist (apply across all 15)
- ✅ Real **scanned PBR** materials (not flat AI textures)
- ✅ **Imperfection**: wear, dirt, asymmetry, hand-placed clutter
- ✅ **Rule-based organic scatter** (density maps, jitter), never grid-perfect
- ✅ **Consistent physical scale** (meters from the survey)
- ✅ **Filmic compositing** (grain, bloom, CA, grade) over clean renders
- ✅ Reference real reels with `claude-watch` and match technique, not output

## Suggested order to run with Claude + Blender MCP
1 → 3 → 4 → 10 → 11 → 2 → 5 → 6 → 7 → 8 → 9 → 14 → 12 → 13 → 15
(structure first, surface early, hero + river, then dressing, then motion + finish.)
