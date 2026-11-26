---
name: design
description: The design system for every app and site Joost builds — two themes (Editorial, Industrial) across four platforms (websites, web apps, iOS, macOS). Use whenever building, styling or restyling any UI: a landing page, marketing site, dashboard, app shell, screen, component, SwiftUI view, or when asked to "make it look good", "design this", "pick a style", "set up the design system", or when a UI looks stale/generic. Also use to review a screen visually before calling UI work done.
---

# Design

Source of truth: the `app-designs` repo, `$D` below. Get it first:

```bash
D="${APP_DESIGNS_HOME:-$HOME/apps/active/app-designs}"
[ -d "$D" ] || git clone --depth 1 https://github.com/mithril-studio/app-designs "$D"
```

It is private. If the clone fails, tell the user this machine has no access and stop. Read `$D/README.md` first. It's short and holds the theme comparison table.

Design is decided **once per project**, then executed. Never invent a style, a font, a palette or a radius. If something isn't in the recipe, copy the nearest reference instead of improvising.

## 1. Know the theme

- Look for a `Design:` line in the project's CLAUDE.md/AGENTS.md. If it's there, use it and don't ask.
- If it's missing, decide with the rule in the README (professional who reads → **Editorial**, operator who acts → **Industrial**, unclear → Industrial). State the choice in one line, then write `Design: <Theme> (<brand colour>)` into the project's CLAUDE.md.

## 2. Load only what you need

- **Starting a new web project? Copy the template, don't scaffold from scratch:** `$D/templates/industrial-app` (web apps) or `$D/templates/editorial-site` (websites). Reuse their `components/ui`, `components/shell`, `components/site`; build only the app-specific pages.

- Platform recipe: `$D/{websites|web-apps|ios-apps|macos-apps}/<theme>.md`
- Tokens: `$D/tokens/web/<theme>.css` (copy verbatim into `globals.css`) or `$D/tokens/apple/Theme.swift` (copy into the app target).
- Bar to beat (web): `$D/preview/<theme>-{website|app}.html` and its screenshot in `$D/preview/shots/`. Look at the PNG before building a new surface.
- Patterns the recipe doesn't cover: search Mobbin (iOS/web) for the screen type, filtered to a reference app first (Linear, Notion), then broader.

## 3. Build

- **Read `$D/foundations/restraint.md` before every screen.** Joost's main complaint is not typography; it's clutter: extra subheaders, search bars nobody needs, badly placed filters. Build the smallest screen that does the job, and list what you left out instead of adding it.

- Customise only `--brand`/`brand` and the wordmark. Everything else comes from tokens.
- Content is part of the design: write realistic copy, names, numbers and dates. Never use lorem ipsum.

## 4. Look at it (required)

- Web: `cd $D/tools && node shoot.mjs <url-or-file> <outDir> <name>` (desktop 1440 and mobile 390; it flags horizontal overflow). Read the PNGs.
- iOS/macOS: take a simulator or app screenshot (`xcrun simctl io booted screenshot <file>`) and read it.
- Resolve every ⚠ in the clutter audit, run the subtraction pass, then check against `$D/foundations/review.md`, fix, and reshoot. End with the `Kept: … / Left out: …` lines. Report failed rules as one line each with the fix applied.
- Then run the `design-judge` skill on the one to three screens that carry the project, and report its result.


## 5. Grow the system, don't fork it

- If a new pattern turns out well, add it to the platform recipe (a few lines), not to the project.
- New reference site: `cd $D/tools && node extract.mjs ../refs/<theme> name=https://url`.
