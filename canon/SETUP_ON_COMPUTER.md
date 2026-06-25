# 🖥️ OORIKH — Do This When You Open the Computer (Master Setup)

Everything needed to continue OORIKH on your Windows PC. Follow top to bottom.

## 0. Get the project
```powershell
cd $HOME\Documents
git clone https://github.com/am0s-95/amer.git   # first time only
cd amer
git checkout claude/gracious-brown-v9ey2e
git pull origin claude/gracious-brown-v9ey2e     # get latest
```

## 1. Core tools (install once)
| Tool | Why | Get it |
|------|-----|--------|
| Node.js (LTS) | runs Claude Code | https://nodejs.org |
| Git | repo | https://git-scm.com/download/win |
| Claude Code | the agent | `npm install -g @anthropic-ai/claude-code` |
| **Blender 4.x** | the whole 3D world | https://www.blender.org/download |
| Python 3.11+ | scripts / MCP | https://python.org (tick "Add to PATH") |

## 2. Skills already in this repo (under `.claude/skills/`)
- **banana** — AI image generation (concept art / references)
  - Free path: `scripts/generate_free.py` (Pollinations FLUX, no key)
  - Or set `GEMINI_API_KEY` for Gemini (image gen needs billing)
- **claude-watch** — analyze reference reels (frames + transcript)
  - Needs: `yt-dlp` + `ffmpeg`  →  `pip install yt-dlp` and install ffmpeg (https://ffmpeg.org/download.html, add to PATH)
  - Optional free transcription: set `GROQ_API_KEY` (free tier) — https://console.groq.com/keys

## 3. THE KEY BRIDGE — Blender MCP (lets Claude drive Blender)
This is what turns Claude into your Blender co-pilot.
```powershell
pip install blender-mcp
```
Then in Blender: Edit ▸ Preferences ▸ Add-ons ▸ Install ▸ select the BlenderMCP addon
(from https://github.com/ahujasid/blender-mcp) ▸ enable it ▸ in the 3D view sidebar (N)
open "BlenderMCP" tab ▸ Connect.
Register it with Claude Code:
```powershell
claude mcp add blender -- uvx blender-mcp
```
(See the repo README for the exact current command.) It also exposes **Poly Haven**
(free HDRIs / textures / models) inside Blender.

## 4. Free asset bridges (install the Blender add-ons)
| Source | Gives | Cost |
|--------|-------|------|
| **Poly Haven** (via Blender MCP) | HDRIs, PBR textures, models | free |
| **BlenderKit** add-on | 30k+ models/materials | free tier |
| **Quixel Megascans / Fab** | scanned rocks, soil, surfaces | free w/ Epic account |
| **ambientCG** | CC0 PBR textures | free |

## 5. API keys to set (optional, all free tiers)
Set as Windows environment variables (System ▸ Environment Variables) so every session sees them:
- `GEMINI_API_KEY` — banana via Gemini  (you already created one: AIza… / AQ…)
- `GROQ_API_KEY` — free Whisper for claude-watch transcripts
- `ELEVENLABS_API_KEY` — (optional) higher-quality transcripts

## 6. OORIKH canon (already saved here)
- `canon/OORIKH.md` — locked prompt + seed
- `canon/OORIKH_survey.md` — verified measurements + zone descriptions
- `canon/oorikh_scan.js` — the 3D measurement scan (Three.js)
- `canon/BLENDER_15_WORKFLOWS.md` — the 15 build processes (read next)

## 7. First move on the computer
1. Open Blender, connect Blender MCP, run `claude` in the repo.
2. Tell Claude: "اقرأ canon/OORIKH_survey.md و BLENDER_15_WORKFLOWS.md وابدأ العملية رقم 1".
3. Build OORIKH process-by-process (see the 15 workflows).
