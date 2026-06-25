# 🌉 OORIKH — MCP Bridges (Claude drives Blender / Unreal / Houdini)

How it works: each bridge is an MCP server that runs on **your computer**, next to the
app it controls. **Claude Code must run on that same computer** (or via a tunnel) — a
remote web session cannot reach your local Blender/Unreal. So: open the app → start its
bridge → run `claude` in the repo → I build, you watch.

## 1. 🟧 Blender bridge  (primary)
Repo: https://github.com/ahujasid/blender-mcp
```powershell
pip install blender-mcp
# Blender: Preferences ▸ Add-ons ▸ Install ▸ BlenderMCP addon ▸ enable
# 3D view ▸ N panel ▸ "BlenderMCP" tab ▸ Connect
claude mcp add blender -- uvx blender-mcp
```
Gives: object/mesh creation, Geometry Nodes, materials, Poly Haven assets, Python exec.

## 2. 🟦 Unreal Engine bridge
Best for city building (50+ tools, towns/castles/PCG):
- https://github.com/flopperam/unreal-engine-mcp  (UE 5.5+, natural-language world building)
For Claude Code + headless/UE 5.7:
- https://github.com/remiphilippe/mcp-unreal  (single Go binary, Blueprint/actors/PCG)
```powershell
# install the UE plugin from the repo into your project's Plugins/ folder, enable it,
# then register the MCP server per the repo README, e.g.:
claude mcp add unreal -- <command from repo README>
```
Gives: spawn actors, Blueprints, materials, landscape, PCG, cinematics.

## 3. 🟪 Houdini bridge  (later — advanced sims)
Repo: https://github.com/oculairmedia/houdini-mcp  (controls Houdini via hrpyc)
```powershell
# enable hrpyc / RPC in Houdini, then register:
claude mcp add houdini -- <command from repo README>
```
Gives: procedural nodes, sims (rock-flow, debris, pyro) — the reel's dynamic FX.

## The LOOP (orchestration once bridges are connected)
1. **Blender** — build city skeleton (Geo Nodes), kitbash buildings, hero assets, scatter.
2. **→ Unreal 5** — import, light (Lumen), detail (Nanite), real-time flythrough + cinematics.
3. **→ Houdini** — advanced sims (rock-flow, dust, explosions), bake back to UE5.
4. Repeat per district (Crown → Merchant → Common → Port → Walls) using `canon/OORIKH_survey.md`.

You watch; I drive each tool through its bridge. Verify each step, then I continue.

## Reality notes
- Bridges run locally; this web session can't reach them. Use Claude Code **on the PC**.
- Repo READMEs hold the exact current `claude mcp add` command (these projects update fast).
- Start with Blender bridge only (simplest); add Unreal, then Houdini, as you grow.
