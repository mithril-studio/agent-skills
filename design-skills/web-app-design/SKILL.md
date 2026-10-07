---
name: web-app-design
description: The house style for every Mithril Studio web app — the "Legal Control" look extracted from the e-learning platform and the Legal AI app. Use when building or restyling any screen, shell, page, card, form, dialog, filter row, table or navigation in a Next.js/Tailwind/shadcn app; when building a focused reading or exercise surface (a lesson player); when starting a new app and it needs a design system; when asked to "make it look like our other apps", "match the e-learning / legal-ai-app style", or to decide where a back button, title, divider line, tab row, filter or action goes.
---

# Web app design — the house style

One look, shared by every app: a quiet navy-on-white interface in Archivo and Space
Grotesk, hairline dividers instead of shadows, one accent colour, and a fixed shell
(sidebar + top bar + scrolling content pane) where every page starts with the same
title bar. The two reference implementations are the e-learning platform
(`foundation-e-learning`) and the Legal AI app (`legal-ai-app`); when this file and a
reference app disagree, the e-learning app's layout and the Legal AI app's tokens win —
that is the merge that produced this style (September 2026). The e-learning app then
added the merged header-with-underline-tabs, the shared filter pattern, the dialog
shell and the lesson environment (5–7 October 2026); those are recorded below and are
part of the style.

Copy, do not reinterpret. The pixel values below are deliberate and already verified
for WCAG 2.1 AA contrast. Where you must invent something, follow the rules under
"Decide like the reference apps".

## 1. Tokens

Copy [`references/tokens.css`](references/tokens.css) into `globals.css` verbatim (light
`:root`, `.dark`, the `@theme inline` bridge, the lesson-environment block and the base
layer). It is the Legal Control palette in OKLCH, with the contrast fixes the
e-learning app earned.

| Role | Light | What it is for |
|---|---|---|
| `--background` / `--card` | white | canvas and cards — same colour; cards are separated by a ring, not a tint |
| `--foreground` | slate ink `#334155` | all body text and headings |
| `--primary` = `--accent-brand` | navy `#1F3864` | **the one accent**: primary buttons, the active-nav marker, selected states |
| `--accent-brand-ink` | navy, a hair darker | the accent *as text* on its own 6% tint (numbered step, hub-card tile) **and as the active-tab underline** |
| `--progress` | navy | every progress fill: bars, meters, the slider range, the lesson rail meter. Its own token because an indicator must clear 3:1 on canvas *and* card, which a brand's button fill need not |
| `--link` | navy | link text and the `link` button variant: 4.5:1 on canvas and card |
| `--ring` | blue `#5B7FB4` | focus rings, nothing else chromatic |
| `--secondary` / `--accent` | tint `#EAEFF7` | secondary button fill, active sidebar row |
| `--muted` / `--sidebar` | tint-2 `#F4F7FB` | sidebar rail, muted fills, hover rows, the segmented-control track |
| `--muted-foreground` | slate `oklch(0.54 …)` | secondary text; 4.5:1 on the tint — do not lighten |
| `--border` / `--input` | line `#E3E8EF` | every hairline in the app |
| `--success` / `--success-foreground` | sage green | completed / passed; fills vs text |
| `--destructive` | red `oklch(0.42 0.17 27)` | danger as *text on a 10% tint*, never a solid red fill |
| `--surface-inverse` | navy | the single permitted dark slab (a "continue" banner) |
| `--radius` | 12px | buttons/inputs `rounded-lg` (12), cards `rounded-xl` (~17), pills `rounded-full` |
| `--lesson-*` | warm canvas, navy ink, bronze | the lesson environment only — see §10 |

Rules that the tokens encode:

- **One accent.** Navy is the only chromatic colour for interaction. Sage is for
  "done", red for "danger"; neither is decoration. Never add a second accent, a
  gradient, or a purple/indigo anything. (`--progress` and `--link` are the same navy
  by default; they exist so a *brand* override can deepen them separately.)
- **Lines, not shadows.** Depth comes from a 1px hairline (`border-border`) or a
  10% ink ring (`ring-1 ring-foreground/10`). The only shadows in the platform chrome
  are `shadow-xs` on the page-header icon tile and `shadow-sm` on the lifted segment of
  a segmented control. (The lesson hero has its own `--shadow-lesson-hero`; §10.)
- **Dark mode is a token swap**, class-based (`.dark` on `<html>`), seeded from a
  `theme` cookie on the server so there is no flash. Every token has a dark value;
  components never branch on theme.
- **Type.** `--font-sans` Archivo (UI, prose), `--font-heading` Space Grotesk (every
  h1–h6, card titles), `--font-mono` IBM Plex Mono (figures, KPI numbers, code).
  Self-host via `next/font/google`; no runtime font fetch.
- **Brand themes override tokens, never components.** A per-organisation theme
  (e-learning ADR-0017) sets the same role-named slots — primary, sidebar chrome, a
  "markering" highlight family, `--progress`, `--link`, `--heading` — on `<body>`;
  nothing in a component reads a brand colour directly. Two mechanisms:
  - *Derived*: up to five brand colours; each token takes the nearest value to the
    brand's own that clears its floor. A **fill keeps the brand's lightness** (a labelled
    button only needs 4.5:1 for its text, WCAG 1.4.11 asks no boundary contrast), so a
    pale lime stays lime on the button and is deepened only where it is an indicator
    (`--progress`, 3:1) or text (`--link`, 4.5:1).
  - *Preset*: a hand-assigned token map for one organisation's published palette
    (`src/lib/brand-presets.ts`), pinned one-to-one wherever a pairing clears the floor
    and documented per token where it cannot. A preset runs through the same
    accessibility gate as a derived theme the first time it is read.
  - Because a brand's highlight can be a pastel, **an indicator never uses the
    markering *fill*** — the active-tab underline and the selected quiz-answer border
    use the markering *ink* (`accent-brand-ink`), which is legible on a tint by
    construction.

## 2. The shell — where the lines are

```
┌──────────────┬────────────────────────────────────────────────────────┐
│ brand row    │ top bar  [← Terug naar …]            [chrome] [actions] │  72px, border-b
│ 72px, border-b├────────────────────────────────────────────────────────┤
│              │ ┌──────────────────────────────────────────────────┐   │
│  nav items   │ │ [icon tile]  Page title   [filters]     [actions] │   │  100px title row
│              │ │ Tab · Tab · Tab                                   │   │  tab row (only with tabs)
│              │ ├──────────────────────────────────────────────────┤   │  ONE border-b under the block
│  (100px gap) │ │                                                   │   │
│  ── admin ── │ │   content, max-w 1248, px-10 py-8, gap 22px        │   │  the only scroll region
│  nav items   │ │                                                   │   │
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
6. Page header bottom: **one** `border-b` under the whole block — title row *and* tab
   row. There is no separate tab band and no second divider; the active tab's 2px
   underline rests on this line.
7. Inside content: card footers (`border-t bg-muted/50`), table rows
   (`[&_tr]:border-b`, last row none), the table toolbar's bottom (`border-b`),
   dialog header/footer edges, the hairline between dialog columns.

Nothing else draws a line. No vertical rules between content columns, no underlined
headings, no boxed sections — a section is an `h2` plus spacing.

### Sidebar

- `w-[240px]`, `bg-sidebar text-sidebar-foreground`, full height, `flex-col`.
- **Brand row**: `h-[72px] px-4 gap-3 items-center border-b`. Holds **either** the
  organisation logo **alone** — `h-11 w-auto max-w-[160px] object-contain object-left`,
  height-bound and width-free so a wordmark and a square mark both fill the lockup,
  with the organisation's name as the `alt` text and no name text beside it — **or**,
  when there is no logo, the name / product wordmark (lotus glyph + name in the heading
  face, `text-base font-semibold tracking-tight`). The collapse toggle is pushed right
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

One block, `border-b border-border`, inner container `mx-auto max-w-[1248px] px-10`
(or the narrow variant `max-w-[1229px] px-8` for settings-like pages), `flex-col`:

- **Title row** `min-h-[100px] items-center gap-x-4` (`flex-wrap gap-y-3 py-4` below
  `md`, `md:flex-nowrap md:py-0` above).
  - **Icon tile**: `size-11 rounded-xl border border-border bg-card text-foreground/75
    shadow-xs`, Lucide icon `size-5`, `aria-hidden`. Decorative — the title carries the
    meaning.
  - **`<h1>`**: `font-heading text-2xl leading-tight font-semibold tracking-tight
    text-heading`. Exactly one per page; it lives in the header, never in the body.
    Optional `titleExtra` (a status pill) sits inline after it.
  - **Filters slot** (`filters` prop, or the `PageFilters` portal from a tab page under a
    shared layout): page-level filters — a scope chip, the period control — anything
    that changes the KPIs and content of the *whole* page. Right-aligned next to the
    title (`md:ml-auto md:shrink-0 md:justify-end`), `gap-2`; below `md` it wraps onto
    its own row under the title, the one case the title row grows past 100px. Empty
    slot is `empty:hidden`.
  - **Actions** at the right edge (`shrink-0 gap-2`).
- **Tab row** (`tabs` prop, only for route-level sub-navigation): directly under the
  title inside the same block. The shared `HeaderTabs` (`src/components/header-tabs.tsx`)
  is a `<nav aria-label>` + `<ul class="flex items-center gap-6 overflow-x-auto">`,
  pulled onto the block's divider with `-mb-px`. Each entry is a link with
  `flex items-center gap-2 border-b-2 pb-3 text-sm whitespace-nowrap`:
  - active: `border-accent-brand-ink font-semibold text-foreground` + `aria-current`;
  - inactive: `border-transparent font-medium text-muted-foreground
    hover:text-foreground`.
  **Underline tabs, not pills** — no background on the active tab. The underline is the
  markering *ink* so a pastel brand highlight cannot make it vanish. It is *not* Radix
  Tabs — each entry navigates (APG: `<nav>` + links + `aria-current`). Scrolls sideways
  rather than wrapping. A form `<button>` tab (a tab that posts) takes the same
  `headerTabClass(active)` so it looks identical to its sibling links. Radix `Tabs` is
  only for in-page panel switching.
- The title row has a fixed height so the title lands at the same y on every page.
  **Back links therefore do not go in the header** — they would change its height.
- **Tab pages under a layout** keep the `h1` in the layout. Each tab page opens with a
  muted one-line description (`text-sm text-muted-foreground`), **not** an `h2`
  repeating the tab name; its first real section starts at `h2`.

### Content pane

- The pane under the top bar is the **only scroll region**: `min-h-0 flex-1
  overflow-y-auto`, `role="region"`, labelled, `tabIndex={0}` (axe's
  scrollable-region-focusable). The shell itself is `h-screen overflow-clip`.
- Page body container: `mx-auto w-full max-w-[1248px] px-10 py-8 flex-col gap-[22px]`
  (wide) or `max-w-[1229px] px-8 py-8` (narrow). Reading surfaces (a quiz, a
  questionnaire) use `max-w-[792px]`–`[912px]`; the lesson environment is its own
  layout at 920px (§10).
- Settings-style forms are capped at `max-w-[560px]`.
- `<main id="main-content" tabIndex={-1}>` wraps header + body; it is the skip-link
  target.

### Full-bleed workspaces (editors with their own chrome, no app sidebar)

A `<header class="flex flex-col border-b border-border px-4">` holding a `h-[72px]`
title bar — ghost `icon-sm` back button (`ArrowLeft`), the `h1` at `text-[15px]
leading-tight font-bold tracking-tight truncate`, a status pill, actions `ml-auto
gap-2` — and, when the workspace has route tabs, the same `HeaderTabs` row under it
inside the same block, one divider. The 72px matches the app shell's top bar so the
line sits at the same height when the user moves between the two.

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
- **Full-bleed workspaces**: the ghost `icon-sm` back button in the 72px title bar (§2).
- **Focused readers** (lesson player): the course outline rail replaces the sidebar;
  its back link ("Terug naar cursussen", `ChevronLeft size-3.5`, 13px,
  `text-lesson-rail-muted hover:text-lesson-rail-foreground`) sits at the top of that
  rail, above the title and progress bar.
- **Steppers / pagers** (quiz, questionnaire, wizard): previous/next are outline
  buttons at the bottom of the form with `ChevronLeft`/`ChevronRight`; they are not
  back links and never go in the top bar. In the lesson environment "Vorige" lives in
  the fixed bottom bar (§10).

## 4. Components

Vendored shadcn/ui (Radix) components, styled through the tokens. Defaults:

| Component | Preset |
|---|---|
| Button | `h-8 rounded-lg px-2.5 text-sm font-medium`; `default` navy fill (hover darkens by mixing 12% black — never fades to a lighter navy), `outline` white + border, `secondary` tint, `ghost`, `destructive` = red text on `bg-destructive/10`, `link` = `text-link underline-offset-4 hover:underline` (the `--link` token, not `--primary`). Sizes `xs/sm/lg/icon/icon-xs/icon-sm/icon-lg`, plus the `lesson` size and `lesson-*` variants (§10). Focus: `ring-3 ring-ring/50` + `border-ring`. |
| Input / Textarea / Select | `h-8 rounded-lg border-input bg-transparent px-2.5`, `aria-invalid:border-destructive`; always a real `<Label htmlFor>` above, `space-y-2`. |
| Field label | `FieldLabel` (`src/components/field-label.tsx`): the field name, then a red asterisk (`aria-hidden`, `text-destructive` — the input's own `required` is what is announced) **or** a muted "(optioneel)" suffix (`font-normal text-muted-foreground`). Every form on the platform uses this one pattern; never a "* = verplicht" legend, never a placeholder as the label. A format example ("06 12345678") goes in the placeholder, not the label. |
| Card | `rounded-xl bg-card ring-1 ring-foreground/10` (no border, no shadow), `py-4`, inner `px-4`; `CardTitle` heading face `text-base font-medium`; `CardFooter` `border-t bg-muted/50`. Empty-state card: `border-dashed`. |
| Table card | `TableCard`: `min-w-0 overflow-hidden rounded-xl border border-border bg-card`; the table scrolls sideways *inside* the card, never the page. Head cells `px-3 py-[11px] text-[11.5px] font-bold tracking-[0.06em] uppercase text-muted-foreground first:pl-[18px]`; body cells `px-3 py-[13px] first:pl-[18px]`. See §9 for the toolbar. |
| Status pill | `h-[22px] rounded-full px-2.5 text-xs font-semibold`, a 5px dot *and* a label — tones `success` / `accent` / `neutral` / `destructive`. Colour is never the only carrier. |
| KPI tile | `rounded-xl border bg-card px-[18px] py-4`: 12px semibold muted label, `font-mono text-3xl font-medium tracking-[-0.03em]` figure, a 4px meter `rounded-full bg-muted` with a `bg-progress` / `bg-success` fill (`ProgressFill`). |
| Progress fill / ring | `ProgressFill` and `ProgressRing` (`src/components/ui/`): the filled part of any meter, and the conic ring on the continue banner. Both set their size through the CSSOM in a ref callback, **never a JSX `style` prop** — a CSP with a per-request nonce drops server-rendered inline styles, so a `style={{width}}` fill renders full-width. Give a fill `w-0` so it is empty, not full, before hydration. The ring is `aria-hidden`; the percentage is text beside it. |
| Dropdown / Dialog / AlertDialog | Radix, `rounded-xl`, popover surface; confirmation = `AlertDialog`, never a hand-rolled overlay. Every *form* dialog takes the shell in §8. |
| Empty state | `rounded-xl border border-dashed border-border px-6 py-10 text-center text-sm text-muted-foreground`, optionally one outline CTA. A table whose filters matched nothing uses `EmptyResults` instead (§9). |
| Dark slab | `rounded-xl bg-surface-inverse text-surface-inverse-foreground p-6`: eyebrow 11.5px uppercase tracked at 70%, title 19px semibold, white action button, optional `ProgressRing` in `--surface-inverse-accent`. One per screen at most. |
| Hub card (landing grids) | `rounded-xl border bg-card p-5`, 36px icon tile on `bg-accent-brand/10 text-accent-brand-ink`, 15px semibold title, 13px muted description, `ArrowUpRight` top-right on hover; "Binnenkort" pill for not-built-yet. |
| File / asset field | A drop zone (`rounded-lg border border-dashed`, a `size-10` icon tile `border bg-card text-foreground/75`, file name 14px medium + 13px muted hint, a "Kiezen" outline button; the native input `sr-only`) behind an **Upload / URL** toggle — a tiny Radix `Tabs` list `h-8 rounded-lg border bg-background p-0.5` with `text-[13px]` triggers, active `bg-muted`. Dropping is a pointer shortcut only; the button and the URL input are the keyboard paths. Uploading without alt text is refused with a message. |

## 5. Typography scale

| Use | Classes |
|---|---|
| Page `h1` | `font-heading text-2xl font-semibold tracking-tight leading-tight` (24px) |
| Workspace `h1` in a bar | `text-[15px] font-bold tracking-tight` |
| Section `h2` | `text-[17px] font-semibold tracking-[-0.01em]` (e-learning) or `text-sm font-semibold` for dense admin pages (Legal AI) |
| Dialog column heading | `text-xs font-semibold uppercase tracking-[0.08em] text-muted-foreground` ("1 · Inhoud") |
| Card title | `font-heading text-base font-medium` |
| Body | `text-sm` (14px); prose/reading `text-base` |
| Secondary | `text-sm text-muted-foreground`; meta `text-[13px]`; table count `text-[12.5px]` |
| Eyebrow | `text-[11px]–[12px] font-semibold uppercase tracking-[0.08em] text-muted-foreground` |
| Figures | `font-mono` (KPIs, percentages, counts) |
| Lesson `h1` | `font-sans text-[32px] sm:text-[40px] leading-[1.1] font-extrabold tracking-[-0.025em] text-lesson-heading` — **the lesson environment uses Archivo extra-bold, not the heading face** (§10) |

Never skip heading levels. Pages contribute the `h1` via the page header; layouts
with tabs keep the `h1` in the layout and each tab page opens with a muted description
and starts its sections at `h2`.

## 6. Auth and public screens

Centred column, `min-h-screen p-8`, `gap-6`: the brand lockup (lotus glyph 28px +
product name in the heading face, plain text not a heading) above a `Card
max-w-sm`; the `h1` (`text-2xl font-semibold`) sits *inside* the card header; the
form in `CardContent space-y-4`; submit full-width in the footer; secondary links as
`text-sm text-muted-foreground hover:underline`. Errors: `role="alert"` box,
`rounded-lg border-destructive/30 bg-destructive/10 text-destructive`.

## 7. Decide like the reference apps

- **Server first.** Shell, sidebar, page header and pages are Server Components; the
  client leaves are the nav (active route), the account menu, the collapse toggle, the
  slot portals, the filter controls (they write the URL) and the dialog shell.
- **Reduce chrome, keep structure.** When unsure whether to add a border, a
  background, a label or a heading: leave it out and use spacing (`gap-[22px]`,
  `gap-6`, `mb-8`).
- **Icons are Lucide**, `size-4` in rows and buttons, `size-5` in the header tile,
  always `aria-hidden` with the text carrying meaning.
- **Loading** is announced, not swapped: `aria-busy` + `disabled` on the pending
  submit; a nav link's icon becomes a spinner while its navigation is pending.
- **Motion** is minimal and collapses under `prefers-reduced-motion`.
- **State is cookie-seeded** (theme, sidebar collapse, locale) so the server paints
  the final frame; no hydration flash, no `prefers-color-scheme` guess. **List state
  is URL-seeded**: every filter, search, sort and period lives in the query string.
- **Sizes never go through a JSX `style` prop.** A per-request-nonce CSP drops
  server-rendered inline styles, so a data-driven width, position or gradient is set
  through the CSSOM in a ref callback (`ProgressFill`, `ProgressRing`, the lesson
  rail width, hotspot rectangles). Design for that from the start; it is not a
  retrofit.
- **Dutch first.** Both apps are Dutch-first with an English toggle; every string
  goes through the message catalogue, URLs stay Dutch.
- **Accessibility is in the preset**: focus ring on everything interactive, `aria-current`
  on the active nav/tab, dot + text on every status, labels on every input, one `h1`,
  one scroll region, `main-content` landmark. Run axe on every new route and state.

## 8. Form dialogs — one shell

Every form dialog takes `FormDialog*` (`src/components/ui/form-dialog.tsx`); the
content-block dialog set the shape and every other dialog followed. Confirmation
dialogs (`AlertDialog`) take the same header/footer shape. Radix still owns focus
trapping and restoration.

- **Content**: `DialogContent` with `showCloseButton={false}`, `flex max-h-[calc(100vh-4rem)]
  flex-col gap-0 overflow-hidden p-0`. Width by column count — `size="wide"`
  (`sm:max-w-3xl`, one-column form or a list), `"xl"` (`sm:max-w-6xl`, two columns),
  `"full"` (`sm:max-w-[calc(100%-4rem)]`, three columns / a workspace-like editor).
- **Header**: `border-b border-border py-6 pl-10 pr-20`, `flex-row flex-wrap items-center
  gap-x-5 gap-y-3`, relative. `DialogTitle text-2xl font-semibold tracking-tight`; an
  optional **context slot** between title and description (a type `<Select>`, or a
  pill naming the record: `h-11 rounded-lg border border-border px-4 text-base`); a
  one-line `DialogDescription text-base` saying what the type is for; the close button
  (ghost `icon`, `aria-label="Sluiten"`) pinned `absolute top-1/2 right-8` so the
  description wraps under the title, not beside the button.
- **Body**: the only scroll region, `min-h-0 flex-1 overflow-y-auto`; `space-y-5 px-10
  py-8`, or `flush` when the body lays out its own columns. **Columns** (`FormColumns`):
  a `grid` of one, two or three `<section>`s, each `min-w-0 space-y-5 px-10 py-8` with a
  hairline on the left of every column after the first (`[&>section+section]:md:border-l`)
  and a numbered heading ("1 · Inhoud", "2 · Foutmoment", `text-xs font-semibold
  uppercase tracking-[0.08em] text-muted-foreground`). A one-column form reads as a
  plain stack without numbering. Lay the columns out as the *steps of authoring* the
  thing, left to right; a preview column (an image, a clip poster on a
  `bg-surface-inverse` 16:9 box with a 72px white play disc) is a column too.
- **Footer**: `border-t border-border px-10 py-5`, `flex-wrap justify-between gap-x-6
  gap-y-4`. Left: an optional *start* slot (the record's key behind a "Geavanceerd"
  disclosure, never in the body). Right: the form-level `role="alert"` region
  (`text-sm text-destructive`, next to the buttons so an error lands where the author
  is looking), "Annuleren" (`outline`, `h-11 px-5 text-[15px]`) and the primary action
  (`h-11 px-6 text-[15px]`).
- The caller still owns the `<form>` — it wraps body and footer so the submit button
  posts it.

## 9. Filters, search and sort — one pattern

Every list and table page uses the components in `src/components/filters/`; no
per-page GET form, no "Toepassen"/"Filteren" button, no scope badge, no ad-hoc select.
**Filters apply on change and live in the URL** (`?periode=`, `?van=`/`?tot=`,
`?zoek=`, `?sort=`/`?dir=`, one param per chip); nothing is written for a value at its
default so the URL stays clean. Parsing is server-side and shared
(`src/lib/list-query.ts`, `src/lib/period-query.ts`).

Where a filter lives:

- **Page-level** (changes the KPIs and content of the whole page: scope, period) →
  the page header's filters slot (§2). Order: scope chip, then period.
- **Table-level** (narrows one table: search, status, column sort) → the table's
  toolbar, inside the table card.

The components:

| Component | Preset |
|---|---|
| `FilterChip` | One Radix `Select` trigger with the label *inside* it — "Filiaal: **Alle filialen** ⌄": key `font-medium text-muted-foreground`, value `font-semibold text-foreground`. `h-10 rounded-[10px] border-border bg-card px-3.5 text-[13.5px] gap-1.5`. The chip *is* the indicator of what is applied — never a separate scope pill. `aria-label` repeats the visible text (a combobox is not named from contents). `locked` renders it read-only (`disabled:opacity-100`) for a viewer whose scope is fixed, so the value stays visible without pretending to be a choice. The "all" option maps to `""` (no param). |
| `SegmentedControl` | 2–5 mutually exclusive choices. Track `role="group" aria-label`: `inline-flex h-10 max-w-full items-center gap-0.5 overflow-x-auto rounded-[10px] bg-muted p-1` (`bg-muted`, not `bg-secondary` — muted text on the darker tint falls under AA). Segment: `h-8 rounded-lg px-3 text-[13px] gap-1.5` with `aria-pressed`; active `bg-card font-semibold text-foreground shadow-sm`, inactive `font-medium text-muted-foreground hover:text-foreground`. |
| `PeriodControl` | The page-level period: segments **7 / 30 / 90 dagen**, **Alles** only where a page allows everything (the audit log), and **Aangepast** (`CalendarDays size-3.5`) opening a Radix `Popover` with a labelled from/to pair (`grid grid-cols-2 gap-3`, `text-xs` labels). Never a hand-rolled overlay. |
| `SearchInput` | `h-10 rounded-[10px] border border-border bg-card pl-[34px] pr-3 text-[13.5px]`, leading `Search size-4` icon, `sr-only` label repeated as the placeholder ("Zoek op naam of e-mail"), debounced write to the URL, follows the URL when "Wissen" clears it. |
| `TableToolbar` | The row above the table head, inside `TableCard`: `flex flex-wrap items-center gap-3 border-b border-border px-4 py-3` — search first, then the table's chips/segments, then the result count pushed right (`ml-auto text-[12.5px] text-muted-foreground`). |
| `SortableHead` | A `<button>` inside the `<th>` writing `?sort=`/`?dir=`; the active column shows one `ArrowUp`/`ArrowDown size-3.5 text-foreground` and carries `aria-sort`, every other sortable column a muted `ArrowUpDown` at 70% so it reads as "click to sort"; `sr-only` text names the action. Dates and scores sort descending first. |
| `ClearFilters` | "Wissen", ghost `h-10 px-3 text-[13px]`, drops the listed params in one URL update. **Rendered only when at least one filter differs from its default** — decided on the server from the parsed values, so it never appears for a URL already at its defaults. |
| `EmptyResults` | In-card, under the toolbar: `px-6 py-12 text-center text-sm text-muted-foreground`, "Geen resultaten" + a "Filters wissen" action, so the filters that caused it stay in view. |

## 10. The lesson environment — a focused reading surface

The lesson player (the learner's lesson route, `src/components/lesson-player/`,
`src/components/content-blocks/interactive/`) is **not** a shell page: no sidebar, no
top bar, no page header, no card around the content. It is its own layout with its
own palette, built so a learning form reads the same whichever block a lesson holds.

### Tokens

`--lesson-*` (in `references/tokens.css`): a warm canvas `#f6f3ee`, an off-white rail
`#fbf9f6`, white surfaces, navy ink `#1b2540` for headings, buttons and the active
step, `#4a5263` body text, `#6b6457` muted, warm hairlines `#e7e2d9` / `#d9d3c8`, a
bronze accent `#a8793a` for **fills and progress only** (never running text — the
deepened `--lesson-eyebrow #8a6430` is the text-safe bronze), three semantic colours
(`--lesson-stop` and `--lesson-wrong` `#c2410c`, `--lesson-correct` `#1d6b4f`) and the
dark player surface `#11151f`. Radii derive from `--radius` so a brand corner style
reaches them: `rounded-lesson-card` (14px) for answer cards and panels,
`rounded-lesson-hero` (18px) for the hero; lesson buttons use `rounded-lg`.
`--shadow-lesson-hero` is the one shadow in the environment.

**An organisation's house style always wins.** The player root carries
`data-lesson-branded` whenever a tenant theme is active, and `[data-lesson-branded]`
re-points every lesson token at the platform/brand token (canvas → `--background`,
rail → `--sidebar`, accent → `--progress`, eyebrow → `--accent-brand-ink`, …). `.dark`
does the same unconditionally. The semantic colours and the player surface keep their
meaning in every theme.

### Buttons

Variants `lesson-primary` (`bg-lesson-primary` navy fill, hover mixes 15% black),
`lesson-secondary` (`border-lesson-line-strong bg-lesson-surface text-lesson-ink
hover:bg-lesson-canvas`) and `lesson-text` (`text-lesson-ink hover:bg-lesson-line/60`),
all `font-semibold`, always with `size="lesson"`: **44px** (`h-11 gap-2 px-5
text-[15px]`) — the environment's one button height and a comfortable touch target.
Spot & Stop's STOP button is `lesson-primary` with `bg-lesson-stop font-extrabold
tracking-[0.06em]`, `disabled:opacity-45` until the clip plays.

### Layout

```
┌───────────────┬─┬────────────────────────────────────────────┐
│ rail          │▏│  [Voorbeeldmodus banner — admin preview only] │
│ ← Terug naar  │ │                                              │
│ Course title  │ │   eyebrow  MODULE 1 · LES 2 · 5 MIN           │
│ x van y ▬▬▬   │ │   h1                                          │
│               │ │   one instruction sentence                    │
│ MODULE 1   3  │ │   ① Kijk ✓ ─ ② Kies ─ ③ Leer                  │
│  ① Lesson     │ │   ┌──────────── hero (video/image) ─────────┐ │
│  ② Lesson ●   │ │   └──────────────────────────────────────────┘ │
│  ③ Lesson     │ │   answer cards / white panels                 │
│               │ │                               max-w 920px    │
├───────────────┴─┴──────────────────────────────────────────────┤
│ [Vorige]            [Chat over deze les]         [Verder →]    │  bottom bar, border-t
└────────────────────────────────────────────────────────────────┘
```

- **Root**: `flex h-screen flex-col overflow-hidden bg-lesson-canvas text-lesson-body`.
- **Rail** (`bg-lesson-rail`, user-resizable): the drag handle is a real WAI-ARIA
  window splitter (`role="separator"`, `aria-orientation`, live `aria-valuenow`,
  arrows/Home/End, focus ring) — never a mouse-only divider. Its width is applied
  through the CSSOM after hydration, not a `style` prop. Content `px-5 pt-7 pb-5 gap-5`:
  the back link (§3); the course title `font-sans text-[19px] font-extrabold
  tracking-[-0.02em] text-lesson-rail-foreground` with the module as a 13px muted
  subtitle; the progress line "x van y" `text-[12.5px] font-medium
  text-lesson-rail-muted` over a `h-1.5 rounded-full bg-lesson-line` bar with a
  `bg-lesson-accent` `ProgressFill`; then the outline — modules as `text-[11px] font-bold
  uppercase tracking-[0.08em] text-lesson-rail-muted` headings with a `font-mono`
  count, lessons as rows `rounded-[12px] border px-3 py-3 gap-3` (current:
  `border-lesson-line bg-lesson-surface` + a 1px ink shadow at 5%; others:
  `border-transparent hover:bg-lesson-line/40`) with a 26px numbered dot (done: bronze
  with a check; current: navy; todo: `border-lesson-line-strong text-lesson-rail-muted`)
  and a learning-form meta line.
- **Preview banner** (admin preview only): one `role="note"` strip across the top of
  the content, `min-h-9 bg-lesson-primary text-[13px] font-semibold` with an `Eye`
  icon — never a note per block.
- **Content**: the one scroll region (`role="region"`, labelled, `tabIndex={0}`)
  wrapping `<main id="main-content" tabIndex={-1} class="mx-auto max-w-[920px] px-6
  sm:px-8 pt-11 pb-16 flex-col">`. Top to bottom:
  1. **Eyebrow** "MODULE 1 · LES 2 · 5 MIN": `text-[12.5px] font-bold tracking-[0.1em]
     uppercase text-lesson-eyebrow`, parts joined by an `aria-hidden` middle dot.
  2. **`h1`** (§5, lesson row). Exactly one; the block's title *is* the lesson title.
  3. **One instruction sentence** (the block's intro): `max-w-[680px] text-[17px]
     leading-[1.6] text-lesson-body`. One per lesson — never an instruction per block
     and never repeated in the hero.
  4. **Step indicator** `LessonSteps`: an `<ol aria-label>` of 2–4 steps ("Kijk · Kies ·
     Leer"), 26px dots joined by `h-px w-8 bg-lesson-line-strong` — done: bronze dot with
     a check + `sr-only` "afgerond"; active: navy dot with the number +
     `aria-current="step"`; todo: `bg-lesson-line/70 text-lesson-muted`. Labels
     `text-[15px]`, semibold ink for done/active, medium muted for todo.
  5. **Hero** (`LESSON_HERO`): `overflow-hidden rounded-lesson-hero bg-lesson-player
     shadow-lesson-hero`, full content width, 16:9. A clip renders through the one
     `ClipPlayer` (below); an image sits directly in it.
  6. **Answer cards**: full-width buttons `flex items-center gap-4 rounded-lesson-card
     border-[1.5px] px-5 py-4 text-left text-[15.5px] font-medium`; after judging, the
     learner's card is marked by **border + icon + label** — wrong: `border-lesson-wrong`
     on a 6% mix of wrong over surface, a `bg-lesson-wrong` dot with ✕, label "Jouw
     keuze"; right: the same in `lesson-correct` with ✓, label "Juiste keuze". The right
     choice is revealed next to the learner's own once the step has been left, never on a
     retry.
  7. **Panels** `LessonPanel`: `rounded-lesson-card border border-lesson-line
     bg-lesson-surface px-6 py-5` with its own `h2` (`font-sans text-[18px] font-bold
     tracking-[-0.01em] text-lesson-ink`, an optional decorative icon) — "Waarom dit
     riskant is", "Goed gezien", "Toelichting". Feedback is a panel with a heading, never
     a coloured fragment mid-sentence. Running text `text-[15.5px] leading-[1.65]
     text-lesson-body`.
  8. **Rule grid** (a plain block, "De juiste aanpak: RAAK"): `h2 font-sans text-[22px]
     font-extrabold tracking-[-0.015em] text-lesson-ink` over a `grid grid-cols-2 gap-3
     md:grid-cols-[repeat(auto-fit,minmax(160px,1fr))]` of 2–6 tiles, each
     `rounded-lesson-card border border-lesson-line bg-lesson-surface p-5` with a 40px
     navy letter square (`rounded-[10px] bg-lesson-primary text-[18px] font-extrabold`),
     a 16px bold title and a 14px sentence.
  9. **Clip card** (a clip offered rather than played — "Bekijk hoe het wél moet"): a
     dark card `rounded-lesson-card bg-lesson-player text-lesson-player-foreground p-5
     gap-5 sm:flex-row sm:items-center`, a `sm:w-48` thumbnail (the clip's own `<video>`
     with its poster, `aria-hidden`, no controls), 18px bold title, 14px subtitle at 75%
     with the clip length, and one white "Afspelen" button (`bg-lesson-player-foreground
     text-lesson-player`, `Play` icon) that swaps the card for the player. One control.
- **Bottom bar** `LessonFooter`: `<nav aria-label>`, `shrink-0 border-t border-lesson-line
  bg-lesson-canvas py-3.5`, inner row at the same `max-w-[920px] px-6 sm:px-8` as
  `<main>` so its edges line up with the content column; three columns (`flex-1 basis-0`
  outer, centred middle) — **Vorige** left (`lesson-secondary`), the lesson chat's
  `lesson-text` toggle centre, the one primary action right (`lesson-primary`). An
  optional one-line note (why "Les afronden" is not offered yet) sits right-aligned
  above the row, `text-[13px] text-lesson-muted`.

### The one clip player (`ClipPlayer`)

A self-hosted clip looks and behaves the same in every learning form: before the
start, a scrim `bg-lesson-player/40` with one large play control — an 84px white disc
(`rounded-full bg-lesson-player-foreground text-lesson-player shadow-lg`, `Play size-8`)
over a 15px semibold label naming the action and the clip length; then **our own
player bar** `px-4 py-3 sm:px-5 gap-3` — Play/Pause (ghost, round, inverse hover),
elapsed `text-[13px] tabular-nums`, a display-only `h-1 rounded-full` progress track at
15% with a `ProgressFill` (**no seeking** — scrubbing ahead would defeat the exercise),
the length, and an optional trailing control (STOP). A clip held at a moment shows a
pill top-left `rounded-full bg-lesson-player/85 px-3 py-1.5 text-[13px] font-semibold`
with a `Pause` icon — "Gepauzeerd op 0:18" — and loses its Play/Pause; the block
decides when it moves on. Once the exercise is done the block switches to native
controls for free replay. Captions render whenever a captions file exists; a poster
whenever one is authored.

## 11. Do not

- Put a back link in the page header, above the title, or in the body.
- Give the active sidebar row a solid navy fill, or make the sidebar a dark panel.
- Add a second accent, a gradient, box shadows on cards, `rounded-2xl`+ on anything
  but pills, or a coloured page background (the lesson canvas is the one exception,
  and it is a token).
- Render route tabs as pills, with a background, or in a separate band with its own
  divider — one block, one line, underline tabs.
- Put an `h2` repeating the tab name at the top of a tab page.
- Add a "Toepassen"/"Filteren" button, a scope badge, or a filter that is not in the
  URL; show "Wissen" when nothing differs from the default.
- Set a size, position or gradient through a JSX `style` prop.
- Use the brand's highlight *fill* for an indicator (tab underline, selected border):
  use its ink.
- Squeeze a logo into a square beside its name — height-bound, width-free, alone.
- Hand-roll a dropdown, dialog, popover, tab set, tooltip or window splitter.
- Use colour alone for status, or an icon alone for an action without an accessible
  name.
- Let the header rows vary in height between pages — the lines must align.
- Use `prefers-color-scheme` or client-only theme detection.

## 12. Starting a new app — checklist

1. `globals.css` ← `references/tokens.css`; fonts via `next/font/google` bound to
   `--font-archivo`, `--font-space-grotesk`, `--font-ibm-plex-mono`.
2. Vendor shadcn `button`, `card`, `input`, `label`, `textarea`, `select`,
   `dropdown-menu`, `dialog`, `alert-dialog`, `popover`, `tabs`, `table`; apply the
   presets in §4. Add `FormDialog*` (§8), `FieldLabel`, `ProgressFill`, `ProgressRing`.
3. Build the shell from §2: `AppShellFrame`, `Sidebar` (+ `SidebarNav`, `AccountMenu`,
   `SidebarToggle`), `Topbar` (+ `TopbarLead`, `TopbarActions` portals), `PageHeader`
   (+ `HeaderTabs`, `PageFilters` portal), `StatusPill`, `BackLink`, `SkipLink`.
4. Add the filter kit from §9 (`FilterChip`, `SegmentedControl`, `PeriodControl`,
   `SearchInput`, `TableCard`/`TableToolbar`, `SortableHead`, `ClearFilters`,
   `EmptyResults`) with the shared query parsers.
5. Add the design-token contrast test from the e-learning app
   (`tests/unit/design-tokens-contrast.test.ts`) so a token edit cannot drop below AA;
   it covers the `--progress`/`--link` pairs and every `--lesson-*` pair.
6. Add an axe e2e spec covering each route, its dark variant, collapsed sidebar, open
   account menu, each open dialog, each filter popover, each validation-error state
   and 320px.

## Sources

- e-learning: `src/app/globals.css`, `src/components/shell/*`,
  `src/components/page-header.tsx`, `src/components/header-tabs.tsx`,
  `src/components/filters/*`, `src/components/field-label.tsx`,
  `src/components/status-pill.tsx`, `src/components/ui/*` (incl. `form-dialog.tsx`,
  `progress-fill.tsx`, `progress-ring.tsx`), `src/components/learner/continue-banner.tsx`,
  `src/lib/brand-theme.ts`, `src/lib/brand-presets.ts`,
  `src/app/(platform-admin)/(builder)/cursus-bouwer/[courseId]/(workspace)/workspace-frame.tsx`,
  `src/app/(platform-admin)/(builder)/cursus-bouwer/[courseId]/lessen/[lessonId]/{block-form-layout,asset-drop-field}.tsx`,
  `src/components/lesson-player/*`, `src/components/content-blocks/interactive/*`,
  `docs/accessibility.md`, `docs/lesson-redesign-followups.md`.
- Legal AI app: `app/src/app/globals.css`, `app/src/components/shell/*`,
  `app/src/components/BackLink.tsx`, `app/src/components/Breadcrumbs.tsx`,
  `app/src/components/brand/*`, `app/src/components/ui/*`.
