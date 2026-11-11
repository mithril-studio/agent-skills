---
name: design-judge
description: Design judge loop. A separate model compares screenshots of a screen, keeps a change only if it beats the best version so far, and lists what to fix next, for up to four rounds. Use when asked to run the design judge or get a second opinion on a design; after building or restyling one of the one to three screens that carry a project, before calling the UI done; or to compare two screenshots of a design.
---

# Design judge

You grade your own screens too kindly. The judge is a second opinion: Claude Opus in a fresh process that sees only screenshots, never your code or your reasoning. This skill gets the judge ready on this machine and hands you to its loop, `LOOP.md`, which owns the rounds and the report format.

Two branches: **improve a screen** (steps 1 to 5) or **compare two screenshots** (steps 1, 2 and the last section).

## 1. Get the harness

```bash
H="${DESIGN_JUDGE_HOME:-$HOME/apps/active/design-agent-harness}"
[ -d "$H" ] || git clone --depth 1 https://github.com/mithril-studio/design-agent-harness "$H"
[ -d "$H/node_modules" ] || (cd "$H" && npm install)
node "$H/judge.mjs"
```

`H` is that folder for the rest of the run. It needs Node 22 or later and the `claude` CLI on `PATH`, logged in: every judge call is a `claude -p` process on the user's login, so there is no API key. If `claude` is missing, tell the user the judge can't run here and stop.

Done when the last command prints the judge's usage.

## 2. Clear the sandbox

The judge calls `api.anthropic.com`, and screenshots launch Chrome. A sandboxed shell blocks both, which shows up as `judge returned no result` or a browser launch error. Run those commands with that host and the browser allowed. If you can't allow them yourself, ask the user to allow them (`/sandbox` in Claude Code) and wait.

## 3. Pick the style and references

- **Style.** The project's `Design:` line in its CLAUDE.md or AGENTS.md names a theme. The style is the entry in `ls "$H/guides/styles"` that matches it. Most are `<theme>-<platform>`, with platform one of `website`, `app`, `ios`, `macos`: `Design: Industrial (…)` on a marketing site is `industrial-website`. Others are named after one look, such as `calm-editorial`.
- **References.** Pick two from `ls "$H/references"` that show the same theme and the same kind of screen.

`guides/` and `references/` are gitignored, so a fresh clone has neither. When the style or the references aren't there, run without `--style` or `--ref` and say so in your report.

## 4. Take the screenshots

`LOOP.md` says where to save them and at what width. To take them:

- **Web.** If the `design` skill is loaded, its `shoot.mjs` writes both files and runs a clutter audit. Run it from the project folder: `node "$D/tools/shoot.mjs" <url> .design-runs/shots <screen>`. Otherwise:

  ```bash
  npx -y playwright screenshot --full-page --viewport-size=1440,900 <url> .design-runs/shots/<screen>-desktop.png
  npx -y playwright screenshot --full-page --viewport-size=390,844 <url> .design-runs/shots/<screen>-mobile.png
  ```

  The first run may need `npx -y playwright install chromium`.
- **iOS.** `xcrun simctl io booted screenshot .design-runs/shots/<screen>-desktop.png`.
- **macOS.** A screenshot of the app window, saved under the same name.

The judge can't click. To judge a dialog, a hover state or an error, put the screen in that state before you take the screenshot.

## 5. Run the loop

Read `$H/LOOP.md` now and follow it round by round, reading `H` there as this folder. Reshoot with step 4 every round.

Done when a report ends in `STOP`, the code is on the round it names, and you have given the user the closing summary from `LOOP.md`.

## Compare two screenshots

When the question is which of two designs is better, skip the loop:

```bash
node "$H/judge.mjs" compare a.png b.png --brief "<what the screen is for and who uses it>"
```

Report its first line (the winner or a split, with the vote count) and what the votes say the losing design should change.
