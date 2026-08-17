# ============================================================
#  OORIKH — one-shot Windows setup for Claude Code bridges
#  Run from the repo root in PowerShell:
#     Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#     .\setup-windows.ps1
# ============================================================

$ErrorActionPreference = "Continue"
function Ok($m){ Write-Host "[OK]  $m" -ForegroundColor Green }
function Info($m){ Write-Host "[..]  $m" -ForegroundColor Cyan }
function Warn($m){ Write-Host "[!!]  $m" -ForegroundColor Yellow }
function Have($c){ return [bool](Get-Command $c -ErrorAction SilentlyContinue) }

Write-Host "`n=== OORIKH bridge setup ===`n" -ForegroundColor Magenta

# --- 1. Prerequisite checks ---
Info "Checking prerequisites..."
foreach($t in @("python","node","git","claude")){
  if(Have $t){ Ok "$t found" } else { Warn "$t MISSING - install it first (see canon/SETUP_ON_COMPUTER.md)" }
}

# --- 2. Python tooling (uv/uvx + skill deps) ---
Info "Installing Python tooling (uv, blender-mcp, yt-dlp)..."
python -m pip install --upgrade pip      | Out-Null
python -m pip install uv                 ; if($?){ Ok "uv (gives uvx)" }
python -m pip install blender-mcp        ; if($?){ Ok "blender-mcp" }
python -m pip install yt-dlp             ; if($?){ Ok "yt-dlp (for claude-watch)" }

# --- 3. ffmpeg (for claude-watch frame/audio extraction) ---
if(Have "ffmpeg"){ Ok "ffmpeg found" }
elseif(Have "winget"){ Info "Installing ffmpeg via winget..."; winget install -e --id Gyan.FFmpeg --accept-source-agreements --accept-package-agreements }
else { Warn "ffmpeg missing - install from https://ffmpeg.org/download.html and add to PATH" }

# --- 4. Register the Blender MCP bridge with Claude Code ---
if(Have "claude"){
  Info "Registering Blender MCP bridge..."
  claude mcp add blender -- uvx blender-mcp 2>$null
  if($?){ Ok "blender bridge registered (claude mcp add blender)" } else { Warn "could not auto-register; run manually: claude mcp add blender -- uvx blender-mcp" }
} else { Warn "claude CLI missing - skipping bridge registration" }

# --- 5. Optional API keys (free tiers) ---
Write-Host ""
Info "Optional free API keys (press Enter to skip each):"
$g = Read-Host "  GEMINI_API_KEY (banana via Gemini)"
if($g){ [Environment]::SetEnvironmentVariable("GEMINI_API_KEY",$g,"User"); Ok "GEMINI_API_KEY set (User)" }
$q = Read-Host "  GROQ_API_KEY (free Whisper for claude-watch)"
if($q){ [Environment]::SetEnvironmentVariable("GROQ_API_KEY",$q,"User"); Ok "GROQ_API_KEY set (User)" }

# --- 6. Manual steps that need a GUI ---
Write-Host "`n=== MANUAL STEPS (need the app's GUI) ===" -ForegroundColor Magenta
Write-Host @"
  BLENDER:
    1. Open Blender > Edit > Preferences > Add-ons > Install
    2. Install the BlenderMCP addon from https://github.com/ahujasid/blender-mcp
    3. Enable it; in the 3D view press N > 'BlenderMCP' tab > Connect
  UNREAL (later):
    - Install the UE plugin from https://github.com/flopperam/unreal-engine-mcp
      (or remiphilippe/mcp-unreal) into your project's Plugins/ folder, enable it,
      then: claude mcp add unreal -- <command from that repo README>
  HOUDINI (later):
    - Enable hrpyc in Houdini, then per https://github.com/oculairmedia/houdini-mcp:
      claude mcp add houdini -- <command from that repo README>
"@ -ForegroundColor Gray

Write-Host "`n=== DONE ===" -ForegroundColor Green
Write-Host "Next: open Blender, Connect the BlenderMCP panel, run 'claude' in this repo,"
Write-Host "then say:  the bridge is connected, start workflow #1`n"
