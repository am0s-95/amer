---
name: tool-report
description: Produce an evidence-backed due-diligence report on a third-party developer tool, library, service, or open-source project — architecture, claim auditing, project health, security and licensing risk, competitive placement, and a weighted verdict. Use when the user asks to research, audit, evaluate, vet, or "write a report on" a tool; when they share a repo URL, package name, or a video/post promoting a tool and ask what it really is; or when deciding whether to adopt a dependency. Do NOT use for reviewing the user's own code (use code-reviewer) or for general topic research with no tool at its center (use deep-research).
license: MIT
metadata:
  version: "1.0.0"
  domain: research
  triggers: تقرير عن أداة, قيّم هذه الأداة, هل هذه الأداة موثوقة, ابحث عن, tool report, evaluate tool, vet dependency, due diligence, is this tool legit, should we adopt
  role: specialist
  scope: research
  output-format: report
  related-skills: deep-research, security-review, documentation-lookup
---

# Tool Due-Diligence Report

Audit a third-party tool the way someone who will be blamed for adopting it would.
Marketing answers "what can it do." This skill answers **"what happens to me if I use it."**

## Scope check

Run this when a **specific tool** is the subject. If the request is broad research with no
tool at its center, use `deep-research` instead. If it's the user's own code, use `code-reviewer`.

## Three laws (apply before any research)

These override intuition and they are where most tool evaluations go wrong.

1. **Absence of CVEs is not a score.** It measures how much scrutiny the project has
   received, not how good the code is. A six-month-old project with a clean record is
   *less* proven than a mature one with a patched, publicly catalogued vulnerability.
   Never present "0 CVEs" as a positive finding without this caveat.
2. **Popularity is not readiness.** Stars, downloads, and viral growth are a marketing
   signal. Score readiness from CI state, release-artifact freshness, issue triage, and
   the fork:star ratio instead. Report them as two separate, unlinked axes.
3. **Every performance number is published by someone with a stake.** In tooling
   categories, benchmarks come from vendors who tune their own product and run
   competitors on defaults. Label the publisher of every number you quote. Report
   *behaviour patterns* (cliff / ceiling / plateau) rather than absolute values, and
   tell the user to measure on their own workload.

## Research order

Read in this order. It is deliberate: the marketing page is **last** because the earlier
sources tell you what the marketing page is omitting.

| # | Source | What you're hunting |
|---|--------|----------------------|
| 1 | `SECURITY.md` / security policy | Threat model, required vs. recommended hardening, supply-chain notes |
| 2 | Any `stealth` / `bypass` / `fingerprint` / `unblock` doc | ToS-violating behaviour the README never mentions |
| 3 | CVE databases (NVD, GitHub Advisory, OSV) + CISA KEV | Known exploitation, severity, patched versions, chained attacks |
| 4 | Package-registry incident reports (PyPI/npm blogs), Socket.dev / Snyk findings | Supply-chain compromise history and maintainer response quality |
| 5 | Open issues filtered by `bug`, `ci`, `bot-report` | Whether main/release branches are green; what maintainers admit is broken |
| 6 | Releases vs. published artifacts (npm/PyPI/Docker tags) | Merged-but-unshipped fixes — the gap between changelog and reality |
| 7 | Licence file + feature matrix | What's actually outside the "open source" core (SSO, SCIM, audit logs) |
| 8 | Funding, ownership, acquisitions, maintainer count | Bus factor and who controls the roadmap in 12 months |
| 9 | Independent coverage and practitioner write-ups | Failure reports the project would never publish |
| 10 | README / landing page | Claims to audit against everything above |

**Every numeric claim gets traced to its own computation.** If a project headlines a
figure, find the file or endpoint that computes it. A number backed by a CI check that
fails the build on drift is a different class of evidence from a number typed into a README.

## Scoring rubric

Score each 0–3 (0 absent, 3 excellent). Weighted total out of 100. Weights reflect what
actually fails in production, not what looks impressive in a feature list.

| Axis | Criterion | The decisive question | Weight |
|------|-----------|----------------------|--------|
| Integrity | Claim auditability | Is the headline number tied to a runnable computation, or just prose? | 12 |
| Integrity | Admitted limits | Does the project document what it does *not* do and what it breaks? | 8 |
| Security | Safe defaults | Are encryption and blocking on by default, or merely "recommended"? | 14 |
| Security | Incident response | How did they behave during their last documented security event? | 10 |
| Legitimacy | ToS compatibility | Does it require defeating a provider's detection to function? | 14 |
| Legitimacy | Data path | Where does the payload actually go, and under whose retention policy? | 8 |
| Readiness | CI + artifact freshness | Branches green? Is what's merged actually published? | 12 |
| Readiness | Exit cost | How standard is the interface? What does leaving cost? | 8 |
| Durability | Bus factor | One maintainer or a team? Who funds continuity? | 8 |
| Durability | Ownership stability | Odds of acquisition, pivot, or maintenance mode within 12 months? | 6 |

Score honestly, including partial scores. A tool can be excellent and still fail on
Legitimacy — say so plainly rather than averaging the problem away.

## Report structure

Deliver as an HTML artifact (load `artifact-design` first). Sections:

1. **Masthead** — name, one-paragraph thesis, date, version audited, source count, confidence.
2. **Verdict card** — one cell per rubric axis: a status chip plus two sentences of evidence.
   The reader must be able to stop here and still be correctly informed.
3. **What it is technically** — request path, dependencies, deployment model. Name the
   operational cost honestly (a stateful service with a database is not "a proxy").
4. **Claim audit** — a table of claim vs. what the docs actually support vs. verdict chip.
5. **Project health** — CI, releases, issue signal, growth pattern, contributors.
6. **Security and legal risk** — the longest section. Timeline any incident.
7. **Competitive placement** — when this beats the alternatives, and when it doesn't.
8. **When to choose / when not to** — two explicit lists, plus a non-negotiable hardening checklist.
9. **Sources** — numbered, each with a one-line note on what it supports. Mark any
   vendor-published benchmark as such, inline.
10. **Methodology and limits** — what you verified, and **what you could not verify and why**.

## Non-negotiables

- **Every claim carries a source.** Single-source claims get flagged as unverified.
- **State what you could not verify.** A report without a limits section is not finished.
- **Separate fact from inference.** Label your own judgements as yours.
- **Contradictions get surfaced, not resolved by preference.** When a third-party article
  and the project's own docs disagree, present both and say which is more current.
- **Correct your own earlier claims prominently** if the research overturns something you
  previously told the user.
- **Never recommend defeating a provider's controls**, even when the tool documents how.
  Report the capability, the vendor's disclaimer, and the risk transfer — then stop.
- **This is an evaluation, not a verdict on the user's choice.** ToS compatibility depends
  on their accounts and their contracts. Give them what they need to decide.

## Series continuity

Reports are numbered (`Tool Due-Diligence · No.NN`) and share one visual system: RTL,
IBM Plex Sans Arabic body, Noto Kufi Arabic display, IBM Plex Mono for data, teal accent
on cool slate, severity-striped finding cards, chip-based verdicts. Before writing a new
report, check prior artifacts (`Artifact` with `action: "list"`) for the next number and
reuse the established stylesheet so the series reads as one body of work.
