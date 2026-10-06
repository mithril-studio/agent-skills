---
name: web-app-design
description: The house style for every Mithril Studio web app — the "Legal Control" look extracted from the e-learning platform and the Legal AI app. Use when building or restyling any screen, shell, page, card, form, dialog or navigation in a Next.js/Tailwind/shadcn app; when starting a new app and it needs a design system; when asked to "make it look like our other apps", "match the e-learning / legal-ai-app style", or to decide where a back button, title, divider line, tab row, filter, search box, sort control or action goes.
---

# Web app design — the house style

One look, shared by every app: a quiet navy-on-white interface in Archivo and Space
Grotesk, hairline dividers instead of shadows, one accent colour, and a fixed shell
(sidebar + top bar + scrolling content pane) where every page starts with the same
title bar. The two reference implementations are the e-learning platform
(`foundation-e-learning`) and the Legal AI app (`legal-ai-app`); when this file and a
reference app disagree, the e-learning app's layout and the Legal AI app's tokens win —
that is the merge that produced this style (September 2026).

Copy, do not reinterpret. The pixel values below are deliberate and already verified
for WCAG 2.1 AA contrast. Where you must invent something, follow the rules under
"Decide like the reference apps".

## 1. Tokens

Copy [`references/tokens.css`](references/tokens.css) into `globals.css` verbatim (light
`:root`, `.dark`, the `@theme inline` bridge and the base layer). It is the Legal Control
palette in OKLCH, with the contrast fixes the e-learning app earned.

| Role | Light | What it is for |
|---|---|---|
| `--background` / `--card` | white | canvas and cards — same colour; cards are separated by a ring, not a tint |
| `--foreground` | slate ink `#334155` | all body text and headings |
| `--primary` = `--accent-brand` | navy `#1F3864` | **the one accent**: primary buttons, the active-nav marker, selected states |
| `--accent-brand-ink` | navy, a hair darker | the accent *as text* on its own 6% tint (active tab, numbered step) |
| `--ring` | blue `#5B7FB4` | focus rings, nothing else chromatic |
| `--secondary` / `--accent` | tint `#EAEFF7` | secondary button fill, active sidebar row |
| `--muted` / `--sidebar` | tint-2 `#F4F7FB` | sidebar rail, muted fills, hover rows |
| `--muted-foreground` | slate `oklch(0.54 …)` | secondary text; 4.5:1 on the tint — do not lighten |
| `--border` / `--input` | line `#E3E8EF` | every hairline in the app |
| `--success` / `--success-foreground` | sage green | completed / passed; fills vs text |
| `--destructive` | red `oklch(0.42 0.17 27)` | danger as *text on a 10% tint*, never a solid red fill |
| `--surface-inverse` | navy | the single permitted dark slab (a "continue" banner) |
| `--radius` | 12px | buttons/inputs `rounded-lg` (12), cards `rounded-xl` (~17), pills `rounded-full` |

Rules that the tokens encode:

- **One accent.** Navy is the only chromatic colour for interaction. Sage is for
  "done", red for "danger"; neither is decoration. Never add a second accent, a
  gradient, or a purple/indigo anything.
- **Lines, not shadows.** Depth comes from a 1px hairline (`border-border`) or a
  10% ink ring (`ring-1 ring-foreground/10`). The only shadows in the whole system are
  `shadow-xs` on the page-header icon tile and `shadow-sm` on the active segment of a
  segmented control.
- **Dark mode is a token swap**, class-based (`.dark` on `<html>`), seeded from a
  `theme` cookie on the server so there is no flash. Every token has a dark value;
  components never branch on theme.
- **Type.** `--font-sans` Archivo (UI, prose), `--font-heading` Space Grotesk (every
  h1–h6, card titles), `--font-mono` IBM Plex Mono (figures, KPI numbers, code).
  Self-host via `next/font/google`; no runtime font fetch.

## 2. The shell — where the lines are

```
┌──────────────┬────────────────────────────────────────────────────────┐
│ brand row    │ top bar  [← Terug naar …]            [chrome] [actions] │  72px, border-b
│ 72px, border-b├────────────────────────────────────────────────────────┤
│              │ ┌──────────────────────────────────────────────────┐   │
│  nav items   │ │ [icon tile]  Page title       [filters] [actions] │   │  100px title row
│              │ │ Tab    Tab    Tab   (underline, only with tabs)   │   │  same header block
│  (100px gap) │ ├──────────────────────────────────────────────────┤   │  one border-b under both
│  ── admin ── │ │                                                   │   │
│  nav items   │ │   content, max-w 1248, px-10 py-8, gap 22px        │   │  the only scroll region
│              │ │                                                   │   │
├──────────────┤ └──────────────────────────────────────────────────┘   │
│ account row  │                                                        │  border-t
└──────────────┴────────────────────────────────────────────────────────┘
   240px, border-r (68px icon rail when collapsed or < md)
```

Every hairline is `--border` / `--sidebar-border` at 1px. The complete list, so you
never add another:

1. Sidebar right edge (`border-r border-sidebar-border`).
2. Sidebar brand row bottom (`h-[72px] border-b`), which the top bar's bottom border
   continues across the full width — the two must stay at the same height.
3. Sidebar admin-group top: a `border-t` after a `mt-[100px]` gap, no label.
4. Sidebar account row top (`border-t`, `p-3`).
5. Top bar bottom (`h-[72px] border-b border-border px-6`).
6. Page header bottom: one `border-b` under the whole header block — the title row
   and, when the page has route tabs, the tab row beneath it. Never a second line
   between title and tabs; the active tab's 2px underline rests on this one.
7. Inside content: card footers (`border-t bg-muted/50`), table rows
   (`[&_tr]:border-b`, last row none), dialog/dropdown edges.

Nothing else draws a line. No vertical rules between columns, no underlined headings,
no boxed sections — a section is an `h2` plus spacing.

### Sidebar

- `w-[240px]`, `bg-sidebar text-sidebar-foreground`, full height, `flex-col`.
- **Brand row**: `h-[72px] px-4 gap-3 items-center border-b`. Holds the organisation
  logo (36px) + name, or the product wordmark (lotus glyph + name in the heading face,
  `text-base font-semibold tracking-tight`), and the collapse toggle pushed right
  (`ml-auto`, ghost icon button, `PanelLeft`/`PanelLeftClose`).
- **Nav**: `px-3 py-[18px]`, items `gap-1`. Each item: `flex items-center gap-2.5
  rounded-lg px-3 py-[9px] text-sm font-medium`, Lucide icon `size-4`.
  - Inactive: `text-sidebar-foreground/80 hover:bg-sidebar-active`.
  - **Active**: `bg-sidebar-active text-sidebar-active-foreground` plus a 2.5px navy
    marker bar on the leading edge (`before:absolute before:inset-y-2 before:left-0
    before:w-[2.5px] before:rounded-full before:bg-sidebar-marker`) and
    `aria-current="page"`. Never a solid navy fill for the active row.
- **Admin / management group**: `mt-[100px] border-t pt-4`, same item style. The gap and
  the rule carry the grouping; no "Admin" heading.
- **Account row** at the bottom: `border-t p-3`; one button row — 30px monogram circle
  (`bg-sidebar-active`, 11px semibold initials), name (13px medium), organisation or role
  as a 10px uppercase tracked eyebrow, `ChevronUp` — opening a Radix dropdown *upwards*
  (`side="top" align="start" w-[214px]`) with the organisation (check-marked), Settings,
  Sign out. The theme toggle lives in Settings, not here.
- **Collapse**: cookie-seeded (`sidebar_state` / `sidebar_collapsed`) so SSR paints the
  right width; labels become `sr-only`, icons stay, nothing is removed from the
  accessibility tree. Below `md` it is always the 68px icon rail.

### Top bar

- `h-[72px] px-6 border-b`, three regions: **lead slot** left (back link / breadcrumbs),
  optional **chrome** (a global filter, a search box `w-72 h-9` with a leading
  `Search` icon), **actions slot** right (`gap-2`).
- The top bar is *chrome*, not the page title: it never shows the `h1`. The page
  header below owns the title.
- Per-page content is portalled into the two slots (`TopbarLead`, `TopbarActions`): a
  page cannot pass props to its layout, so each page mounts its own back link and its
  own actions (e.g. "Exporteer als CSV" as an outline button `h-9`) into the bar.

### Page header (first child of `<main>` on every shell page)

- One block, one divider: `<div className="border-b">` wrapping the title row and,
  when present, the tab row directly under it.
- Title row `min-h-[100px]`, inner container `mx-auto max-w-[1248px] px-10` (or the narrow
  variant `max-w-[1229px] px-8` for settings-like pages), `gap-x-4 items-center`.
- **Icon tile**: `size-11 rounded-xl border border-border bg-card text-foreground/75
  shadow-xs`, Lucide icon `size-5`, `aria-hidden`. Decorative — the title carries the
  meaning.
- **`<h1>`**: `font-heading text-2xl leading-tight font-semibold tracking-tight
  text-heading`. Exactly one per page; it lives in the header, never in the body.
  Optional `titleExtra` (a status pill) sits inline after it; **page-level filters**
  (scope, period — see §5) sit right-aligned in a `filters` slot, then optional actions
  at the right edge. Below `md` the filters slot wraps onto its own row under the
  title — the one case the title row grows past 100px.
- **Tabs — the settings-tabs pattern** (only for route-level sub-navigation:
  settings, analytics, organisation detail, a builder workspace). The tab row sits
  directly under the title inside the same header block — no separate tab band, no
  second divider. Underline tabs, not pills:

  ```tsx
  // components/header-tabs.tsx
  export function HeaderTabs({ label, children }: { label: string; children: React.ReactNode }) {
    return (
      // -mb-px pulls the active underline onto the header block's divider
      <nav aria-label={label} className="-mb-px min-w-0">
        <ul className="flex items-center gap-6 overflow-x-auto">{children}</ul>
      </nav>
    );
  }
  export const headerTabClass = (active: boolean) => cn(
    "flex items-center gap-2 border-b-2 pb-3 text-sm whitespace-nowrap transition-colors outline-none focus-visible:rounded-sm focus-visible:ring-3 focus-visible:ring-ring/50",
    active ? "border-accent-brand font-semibold text-foreground"
           : "border-transparent font-medium text-muted-foreground hover:text-foreground",
  );
  // each entry:
  // <li className="shrink-0">
  //   <Link href={href} aria-current={active ? "page" : undefined} className={headerTabClass(active)}>…</Link>
  // </li>
  ```

  - Active: semibold foreground text + 2px navy underline + `aria-current="page"`.
    Inactive: medium muted text, transparent underline. No pill background, no tint.
  - `gap-6` between entries; the row scrolls sideways (`overflow-x-auto`) rather than
    wrapping on narrow viewports.
  - A `<nav>` of links, *not* Radix Tabs — each entry navigates, so `role="tab"` would
    promise a panel switch that never happens. Radix `Tabs` is only for in-page panel
    switching. A form `<button>` that must sit in the row uses the same class helper.
  - The layout owns `<main>`, the `PageHeader` (with `tabs={<SettingsNav />}`) and the
    single `h1`. Each tab page opens with a **muted one-line description**
    (`text-sm text-muted-foreground`, the `aria-labelledby` of its `<section>`), not an
    `h2` repeating the tab name. Settings-like pages use the narrow width; forms there
    are capped at `max-w-[560px]`, optional fields say "(optioneel)" in the label, and
    every submit reads "Opslaan".
- The title row has a fixed height so the title and divider land at the same y on every
  page. **Back links therefore do not go in the header** — they would change its height.

### Content pane

- The pane under the top bar is the **only scroll region**: `min-h-0 flex-1
  overflow-y-auto`, `role="region"`, labelled, `tabIndex={0}` (axe's
  scrollable-region-focusable). The shell itself is `h-screen overflow-clip`.
- Page body container: `mx-auto w-full max-w-[1248px] px-10 py-8 flex-col gap-[22px]`
  (wide) or `max-w-[1229px] px-8 py-8` (narrow). Reading surfaces (a lesson, a quiz) use
  `max-w-[792px]`–`[912px]`.
- `<main id="main-content" tabIndex={-1}>` wraps header + body; it is the skip-link
  target.

## 3. Back buttons, breadcrumbs, forward/back pagers

**A back link lives in the top bar's lead slot, top-left, on the same row as the
actions — never inside the page header, never above the title, never as a button in
the body.** It appears only on detail pages that have an obvious parent list
(organisation → organisations, client → clients, report → reports).

Two accepted renderings, both `text-muted-foreground hover:text-foreground`:

- **Text back link** (default, Legal AI app `BackLink`): ghost `Button size="sm"`
  as a `Link`, `-ml-3 p-2 gap-1`, `ChevronLeft size-4` + "Terug naar *&lt;parent&gt;*"
  (truncate). Use when the bar has room.
- **Icon-only** (e-learning): `ArrowLeft size-4` inside a bare `Link` with
  `aria-label="Terug naar …"`. Use when the bar is crowded (filters, search, actions).

Related rules:

- The label is always "Terug naar &lt;where&gt;" — name the destination, never a bare
  "Terug" or "Vorige" except inside a stepper.
- **Breadcrumbs** (hierarchies deeper than one level, e.g. folders): a `<nav
  aria-label>` + `<ol>` *inside the content container*, above the first section, `mb-2
  text-sm text-muted-foreground`, `ChevronRight size-3.5` separators, last crumb
  `aria-current="page" font-medium text-foreground`. The top-bar back link then
  points one level up.
- **Full-bleed workspaces** (editors with their own chrome, no app sidebar): a `h-14`
  header `border-b bg-card px-4` with a ghost `icon-sm` back button (`ArrowLeft`),
  the `h1` at `text-[15px] font-semibold tracking-tight`, then a status pill.
- **Focused readers** (lesson player): the course outline rail replaces the sidebar;
  its back link ("Terug naar cursussen", `ChevronLeft size-3.5`, 12.5px) sits at the
  top of that rail, above the title and progress bar.
- **Steppers / pagers** (quiz, questionnaire, wizard): previous/next are outline
  buttons at the bottom of the form with `ChevronLeft`/`ChevronRight`; they are not
  back links and never go in the top bar.

## 4. Components

Vendored shadcn/ui (Radix) components, styled through the tokens. Defaults:

| Component | Preset |
|---|---|
| Button | `h-8 rounded-lg px-2.5 text-sm font-medium`; `default` navy fill (hover darkens by mixing 12% black — never fades to a lighter navy), `outline` white + border, `secondary` tint, `ghost`, `destructive` = red text on `bg-destructive/10`, `link`. Sizes `xs/sm/lg/icon/icon-sm`. Focus: `ring-3 ring-ring/50` + `border-ring`. |
| Input / Textarea / Select | `h-8 rounded-lg border-input bg-transparent px-2.5`, `aria-invalid:border-destructive`; always a real `<Label htmlFor>` above, `space-y-2`. |
| Card | `rounded-xl bg-card ring-1 ring-foreground/10` (no border, no shadow), `py-4`, inner `px-4`; `CardTitle` heading face `text-base font-medium`; `CardFooter` `border-t bg-muted/50`. Empty-state card: `border-dashed`. |
| Status pill | `h-[22px] rounded-full px-2.5 text-xs font-semibold`, a 5px dot *and* a label — tones `success` / `accent` / `neutral` / `destructive`. Colour is never the only carrier. |
| KPI tile | `rounded-xl border bg-card px-[18px] py-4`: 12px semibold muted label, `font-mono text-3xl font-medium tracking-[-0.03em]` figure, a 4px meter `rounded-full bg-muted` with an accent/success fill. |
| Dropdown / Dialog / AlertDialog | Radix, `rounded-xl`, popover surface; confirmation = `AlertDialog`, never a hand-rolled overlay. |
| Empty state | `rounded-xl border border-dashed border-border px-6 py-10 text-center text-sm text-muted-foreground`, optionally one outline CTA. |
| Dark slab | `rounded-xl bg-surface-inverse text-surface-inverse-foreground p-6`: eyebrow 11.5px uppercase tracked at 70%, title 19px semibold, white action button. One per screen at most. |
| Hub card (landing grids) | `rounded-xl border bg-card p-5`, 36px icon tile on `bg-accent-brand/10 text-accent-brand-ink`, 15px semibold title, 13px muted description, `ArrowUpRight` top-right on hover; "Binnenkort" pill for not-built-yet. |

## 5. Filters, search and tables

Every list or table page uses one URL-synced filtering pattern: filters apply on change,
the chip's value is the indicator, and the query string is the state. Components,
placement and the ten rules are in
[`references/filtering.md`](references/filtering.md) — read it before building any page
with a filter, search box, sort, or table toolbar.

The short version:

- **Page-level filters** (scope, period — anything that changes the KPIs) go in the page
  header's `filters` slot, right of the title (`<PageFilters>` portal for tab pages under
  a shared layout). **Table-level filters** (search, status) go in the `TableToolbar`
  inside the table card.
- `FilterChip` "Filiaal: Alle filialen ⌄" (key muted 500, value ink 600, `h-10
  rounded-[10px]`); `SegmentedControl` on a `bg-muted` track, active segment `bg-card
  shadow-sm` (the second permitted shadow); `PeriodControl` 7 / 30 / 90 dagen /
  Aangepast; `SortableHead` with `aria-sort`.
- No "Toepassen" buttons, no scope pills, "Wissen" only when something is non-default,
  "Geen resultaten" + "Filters wissen" inside the table.

## 6. Typography scale

| Use | Classes |
|---|---|
| Page `h1` | `font-heading text-2xl font-semibold tracking-tight leading-tight` (24px) |
| Workspace `h1` in a bar | `text-[15px] font-bold tracking-tight` |
| Section `h2` | `text-[17px] font-semibold tracking-[-0.01em]` (e-learning) or `text-sm font-semibold` for dense admin pages (Legal AI) |
| Card title | `font-heading text-base font-medium` |
| Body | `text-sm` (14px); prose/reading `text-base` |
| Secondary | `text-sm text-muted-foreground`; meta `text-[13px]` |
| Eyebrow | `text-[11px]–[12px] font-semibold uppercase tracking-[0.08em] text-muted-foreground` |
| Figures | `font-mono` (KPIs, percentages, counts) |
| Reading `h1` | `text-[32px] font-bold tracking-[-0.03em]` (lesson title) |

Never skip heading levels. Pages contribute the `h1` via the page header; layouts
with tabs keep the `h1` in the layout; each tab page opens with a muted description and
uses `h2` only for real sections below it, never to repeat the tab name.

## 7. Auth and public screens

Centred column, `min-h-screen p-8`, `gap-6`: the brand lockup (lotus glyph 28px +
product name in the heading face, plain text not a heading) above a `Card
max-w-sm`; the `h1` (`text-2xl font-semibold`) sits *inside* the card header; the
form in `CardContent space-y-4`; submit full-width in the footer; secondary links as
`text-sm text-muted-foreground hover:underline`. Errors: `role="alert"` box,
`rounded-lg border-destructive/30 bg-destructive/10 text-destructive`.

## 8. Decide like the reference apps

- **Server first.** Shell, sidebar, page header and pages are Server Components; the
  client leaves are the nav (active route), the account menu, the collapse toggle and
  the slot portals.
- **Reduce chrome, keep structure.** When unsure whether to add a border, a
  background, a label or a heading: leave it out and use spacing (`gap-[22px]`,
  `gap-6`, `mb-8`).
- **Icons are Lucide**, `size-4` in rows and buttons, `size-5` in the header tile,
  always `aria-hidden` with the text carrying meaning.
- **Loading** is announced, not swapped: `aria-busy` + `disabled` on the pending
  submit; a nav link's icon becomes a spinner while its navigation is pending.
- **Motion** is minimal and collapses under `prefers-reduced-motion`.
- **State is cookie-seeded** (theme, sidebar collapse, locale) so the server paints
  the final frame; no hydration flash, no `prefers-color-scheme` guess.
- **Dutch first.** Both apps are Dutch-first with an English toggle; every string
  goes through the message catalogue, URLs stay Dutch.
- **Accessibility is in the preset**: focus ring on everything interactive, `aria-current`
  on the active nav/tab, dot + text on every status, labels on every input, one `h1`,
  one scroll region, `main-content` landmark. Run axe on every new route and state.

## 9. Do not

- Put a back link in the page header, above the title, or in the body.
- Give the active sidebar row a solid navy fill, or make the sidebar a dark panel.
- Add a second accent, a gradient, box shadows on cards, `rounded-2xl`+ on anything
  but pills, or a coloured page background.
- Hand-roll a dropdown, dialog, tab set or tooltip.
- Use colour alone for status, or an icon alone for an action without an accessible
  name.
- Let the header rows vary in height between pages — the lines must align.
- Put tabs in their own band with a second divider, or style them as pills.
- Repeat the active tab's name as an `h2` on a tab page.
- Add a "Toepassen"/"Filteren" button, a GET `<form>` for filters, a separate scope
  badge, or a label above a filter dropdown.
- Use `prefers-color-scheme` or client-only theme detection.

## 10. Starting a new app — checklist

1. `globals.css` ← `references/tokens.css`; fonts via `next/font/google` bound to
   `--font-archivo`, `--font-space-grotesk`, `--font-ibm-plex-mono`.
2. Vendor shadcn `button`, `card`, `input`, `label`, `textarea`, `select`,
   `dropdown-menu`, `dialog`, `alert-dialog`, `popover`, `tabs`, `table`; apply the presets in §4.
3. Build the shell from §2: `AppShellFrame`, `Sidebar` (+ `SidebarNav`, `AccountMenu`,
   `SidebarToggle`), `Topbar` (+ `TopbarLead`, `TopbarActions` portals), `PageHeader`,
   `StatusPill`, `BackLink`, `SkipLink`, `HeaderTabs`.
4. Add `components/filters/*`, `lib/list-query.ts` and `lib/period-query.ts` from
   `references/filtering.md` before the first list page.
5. Add the design-token contrast test from the e-learning app
   (`tests/unit/design-tokens-contrast.test.ts`) so a token edit cannot drop below AA.
6. Add an axe e2e spec covering each route, its dark variant, collapsed sidebar, open
   account menu and 320px.

## Sources

- e-learning: `src/app/globals.css`, `src/components/shell/*`,
  `src/components/page-header.tsx`, `src/components/header-tabs.tsx`,
  `src/app/(learner)/(shell)/instellingen/*`, `src/components/filters/*`,
  `src/lib/list-query.ts`, `src/lib/period-query.ts`, `src/components/status-pill.tsx`,
  `src/components/ui/*`, `src/components/learner/continue-banner.tsx`,
  `src/app/(platform-admin)/(builder)/cursus-bouwer/[courseId]/(workspace)/workspace-frame.tsx`,
  `src/components/lesson-player/*`.
- Legal AI app: `app/src/app/globals.css`, `app/src/components/shell/*`,
  `app/src/components/BackLink.tsx`, `app/src/components/Breadcrumbs.tsx`,
  `app/src/components/brand/*`, `app/src/components/ui/*`.
