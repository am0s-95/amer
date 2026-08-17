#!/usr/bin/env python3
"""Banana Claude -- FREE generator via Pollinations.ai (FLUX).

No API key, no signup, no credit card. Uses only Python stdlib.

NOTE: Requires outbound access to image.pollinations.ai. From a restricted
Claude Code web environment this host may be blocked by the network policy --
allow `pollinations.ai` in the environment settings, or run on your own machine.

Usage:
    generate_free.py --prompt "a cat in space" [--width 1344] [--height 768]
                     [--model flux] [--seed 42] [--out path.jpg]
"""

import argparse
import sys
import time
import urllib.parse
import urllib.request
from datetime import datetime
from pathlib import Path

OUTPUT_DIR = Path.home() / "Documents" / "nanobanana_generated"
API_BASE = "https://image.pollinations.ai/prompt/"


def generate(prompt, width, height, model, seed, out_path):
    enc = urllib.parse.quote(prompt)
    qs = urllib.parse.urlencode({
        "width": width,
        "height": height,
        "model": model,
        "seed": seed,
        "nologo": "true",
        "enhance": "true",
    })
    url = f"{API_BASE}{enc}?{qs}"

    req = urllib.request.Request(url, headers={"User-Agent": "banana-claude/1.0"})
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                data = resp.read()
            if not data or len(data) < 1000:
                raise ValueError("Empty/too-small response")
            with open(out_path, "wb") as f:
                f.write(data)
            return out_path
        except Exception as e:  # noqa: BLE001
            if attempt < 2:
                time.sleep(2 ** (attempt + 1))
                continue
            print(f"ERROR: {e}", file=sys.stderr)
            sys.exit(1)


def main():
    p = argparse.ArgumentParser(description="FREE image generation via Pollinations (FLUX)")
    p.add_argument("--prompt", required=True)
    p.add_argument("--width", type=int, default=1344)
    p.add_argument("--height", type=int, default=768)
    p.add_argument("--model", default="flux", help="flux | flux-realism | turbo")
    p.add_argument("--seed", type=int, default=42)
    p.add_argument("--out", default=None)
    args = p.parse_args()

    if args.out:
        out_path = Path(args.out).resolve()
        out_path.parent.mkdir(parents=True, exist_ok=True)
    else:
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        ts = datetime.now().strftime("%Y%m%d_%H%M%S")
        out_path = (OUTPUT_DIR / f"banana_free_{ts}.jpg").resolve()

    result = generate(args.prompt, args.width, args.height, args.model, args.seed, out_path)
    print(f"Saved: {result}")


if __name__ == "__main__":
    main()
