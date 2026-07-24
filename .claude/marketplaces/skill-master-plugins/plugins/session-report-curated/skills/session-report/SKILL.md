---
name: session-report
description: Generate a privacy-conscious, self-contained HTML report of Claude Code session usage (tokens, cache, subagents, skills, expensive prompts) from local Claude Code transcripts. Prompt text is redacted by default.
---

# Session Report (Curated)

Produce a self-contained HTML report of Claude Code usage for the **current
`HOME`/`CLAUDE_CONFIG_DIR` only** — this analyzes transcripts available on
this machine/environment, not a user's full history across other devices or
environments. Save it under `~/.claude/reports/`, never inside a project
repository.

This is a Skill Master curated fork of Anthropic's official `session-report`
skill. See `PROVENANCE.md` in this repo for the upstream source, commit, and
the exact local modifications (CLAUDE_CONFIG_DIR support, default prompt
redaction, safe output directory, plugin manifest).

## Privacy (read this first)

- **Default (no flags): prompt text and its surrounding transcript context
  are redacted.** `top_prompts[].text` is `"[redacted]"`, `context` is
  `null`. Only aggregate numeric statistics are included.
- Only pass `--include-prompts` when the user **explicitly** asks for
  verbatim prompt text in the report. When you do, tell the user clearly
  that the resulting HTML/JSON will contain real content from their
  conversations, and that they should treat the file as sensitive.
- Everything here runs locally: the analyzer only reads `.jsonl` transcript
  files from disk and writes to stdout/a local file. It never makes network
  requests and never sends transcript data anywhere.
- Do not copy, commit, or upload the generated report anywhere. Do not run
  this against another user's or another environment's transcripts.

## Steps

1. **Get data.** Run the bundled analyzer (absolute path — it lives in the
   same directory as this SKILL.md) with the requested time range. Default
   range is the **last 7 days**; honor `24h`, `7d`, `30d`, or `all` if the
   user asks for a different one:
   ```sh
   node <skill-dir>/analyze-sessions.mjs --json --since 7d > /tmp/session-report.json
   ```
   For all-time, use `--since all` (or omit `--since`). Only add
   `--include-prompts` if the user explicitly asked for prompt text — never
   by default.

2. **Read** `/tmp/session-report.json`. Skim `overall`, `by_project`,
   `by_subagent_type`, `by_skill`, `cache_breaks`, `top_prompts`, and the
   `privacy` block (`prompts_included`, `local_only`).

3. **Prepare the output location.** Reports are saved under
   `~/.claude/reports/`, never inside the current project/repository:
   ```sh
   mkdir -p -m 700 ~/.claude/reports
   ```
   Choose the output filename `session-report-$(date +%Y%m%d-%H%M).html`
   unless the user explicitly names a different path.

4. **Copy the template** (bundled alongside this SKILL.md) to that output
   path:
   ```sh
   cp <skill-dir>/template.html ~/.claude/reports/session-report-$(date +%Y%m%d-%H%M).html
   chmod 600 ~/.claude/reports/session-report-$(date +%Y%m%d-%H%M).html
   ```

5. **Edit the output file** (use Edit, not Write — preserve the template's
   JS/CSS):
   - Replace the contents of `<script id="report-data" type="application/json">`
     with the full JSON from step 1, verbatim (do not re-add prompt text
     that was redacted). The page's JS renders the hero total, all tables,
     bars, and drill-downs from this blob automatically, including the
     `privacy` badge in the footer.
   - Fill the `<!-- AGENT: anomalies -->` block with **3–5 one-line
     findings**, expressed as a **% of total tokens** wherever possible
     (total = `overall.input_tokens.total + overall.output_tokens`). One
     line per finding, exact markup:
     ```html
     <div class="take bad"><div class="fig">41.2%</div><div class="txt"><b>cc-monitor</b> consumed 41% of the week across just 3 sessions</div></div>
     ```
     Classes: `.take bad` for waste/anomalies (red), `.take good` for
     healthy signals (green), `.take info` for neutral facts (blue). Look
     for: a project or skill eating a disproportionate share, cache-hit
     <85%, a single prompt >2% of total, subagent types averaging >1M
     tokens/call, cache breaks clustering. If prompts are redacted, refer to
     prompts by project/session/timestamp, not by content.
   - Fill the `<!-- AGENT: optimizations -->` block (bottom of the page)
     with 1–4 `<div class="callout">` suggestions tied to specific rows.
   - Do not restructure existing sections.

6. **Report to the user**:
   - The saved report path (under `~/.claude/reports/`).
   - The time range analyzed.
   - Number of sessions found.
   - Whether prompts are redacted or included (from the `privacy` block).
   - That this only covers transcripts under the current `HOME`/
     `CLAUDE_CONFIG_DIR`, not the user's full account history across other
     machines.
   - Do not open, render, commit, publish, or upload the file — reporting
     the path is the deliverable.

## Notes

- The template is the source of interactivity (sorting, expand/collapse,
  block-char bars). Your job is data + narrative, not markup.
- Keep commentary terse and specific — reference actual project names,
  numbers, timestamps from the JSON.
- `top_prompts` already includes subagent tokens and rolls task-notification
  continuations into the originating prompt.
- If the JSON is >2MB, trim `top_prompts` to 100 entries and `cache_breaks`
  to 100 before embedding (they should already be capped).
- Do not run this skill automatically at `SessionStart`, `Stop`, or after
  every task — only when the user explicitly asks for a usage/token/cache
  report.
