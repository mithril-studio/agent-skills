# Filters, search and tables

One pattern for every page that has filters, a search box, sorting, or a table with a
toolbar. Filters apply on change, a filter's own value shows what is applied, and the
query string holds the whole view, so a link reproduces it and a reload keeps it. The
reference implementation is the e-learning platform: `src/components/filters/*`,
`src/lib/list-query.ts`, `src/lib/period-query.ts` (October 2026).

## Placement

```
┌ page header ───────────────────────────────────────────────────────────────────┐
│ [icon] Analytics          Filiaal: Alle filialen ⌄  [7 dagen|30 dagen|90 dagen|📅 Aangepast] │ ← page-level
│ Overzicht   Inzichten   Auditlog                                               │
├────────────────────────────────────────────────────────────────────────────────┤
│  KPI tiles ("Actief", not "Actief (30 dagen)")                                  │
│  ┌ TableCard ───────────────────────────────────────────────────────────────┐  │
│  │ 🔍 Zoek op naam of e-mail   Status: Actief ⌄   Wissen          12 teamleden │  │ ← TableToolbar
│  │ NAAM ↑            LAATST ACTIEF ⇅        VOORTGANG ⇅                       │  │ ← SortableHead
│  │ …rows… (scrolls sideways inside the card on narrow viewports)              │  │
```

- **Page-level filters** change the KPIs and content of the whole page (scope, period).
  They go right-aligned next to the title through `PageHeader`'s `filters` prop. A tab
  page under a shared layout, which can't pass props to the layout, uses the
  `<PageFilters>` portal into the same slot (`id="page-header-filters"`). Below `md` the
  slot wraps onto its own row under the title.
- **Table-level filters** (search, status, role) go in the `TableToolbar` inside the
  `TableCard`, never in the page header.

## Components (`components/filters/`)

All of them are client leaves that write the URL through one hook. The page stays a
Server Component that parses `searchParams` and filters and sorts the rows itself.

### `useFilterParams()`, the only way a control changes the URL

```ts
export function useFilterParams() {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const [isPending, startTransition] = useTransition();
  const setParams = useCallback((updates: Record<string, string | null | undefined>) => {
    const next = new URLSearchParams(searchParams.toString());
    for (const [key, value] of Object.entries(updates)) {
      if (value === null || value === undefined || value === "") next.delete(key); // "" = default
      else next.set(key, value);
    }
    if (!("page" in updates)) next.delete("page"); // a changed filter never lands on a dead page
    const query = next.toString();
    startTransition(() => router.replace(query ? `${pathname}?${query}` : pathname, { scroll: false }));
  }, [pathname, router, searchParams]);
  return { searchParams, setParams, isPending };
}
```

Use `replace`, not `push`, because a filter tweak isn't a history entry. A default value
writes nothing, so default links stay clean.

### `FilterChip`, "Filiaal: Alle filialen ⌄"

- A Radix **Select** trigger with the label inside: the key (`"Filiaal: "`) is
  `font-medium text-muted-foreground` and the value is `font-semibold text-foreground`,
  both inline in one truncating `<span>` so the word space survives.
- Trigger: `h-10 w-auto gap-1.5 rounded-[10px] border-border bg-card px-3.5
  text-[13.5px]`.
- `aria-label={`${label}: ${value}`}`. A combobox doesn't take its name from its
  content, so the visible text has to be repeated.
- An `allLabel` option maps to `""` (no param). Radix reserves `""`, so use a
  `"__all__"` sentinel internally. Pass `groups` for grouped options (branches per
  region).
- `locked`: rendered disabled with `disabled:opacity-100` for a viewer whose scope is
  fixed (a branch admin's own branch). The value stays visible as the indicator without
  pretending to be a choice.
- **The chip is the scope indicator.** Never add a separate "Hele organisatie" badge.

### `SegmentedControl`, 2–5 mutually exclusive options (status, view)

```ts
export const segmentClass = (active: boolean) => cn(
  "inline-flex h-8 items-center gap-1.5 rounded-lg px-3 text-[13px] whitespace-nowrap transition-colors outline-none focus-visible:ring-3 focus-visible:ring-ring/50",
  active ? "bg-card font-semibold text-foreground shadow-sm"
         : "font-medium text-muted-foreground hover:text-foreground",
);
// SegmentedTrack:
// <div role="group" aria-label={label}
//   className="inline-flex h-10 max-w-full items-center gap-0.5 overflow-x-auto rounded-[10px] bg-muted p-1">
```

- Each segment is a `<button aria-pressed>`. Selecting the `defaultValue` segment clears
  the param.
- The track is `bg-muted`, **not** `bg-secondary`. Muted text on the darker tint drops to
  4.37:1 (below AA); on `muted` it holds 4.69:1.
- `max-w-full overflow-x-auto`: on a narrow screen the rail scrolls inside itself
  instead of widening the page (WCAG 1.4.10).
- The active segment's `shadow-sm` is the one shadow allowed besides the header icon
  tile.

### `PeriodControl`, the page-level period for time-based data

- The `SegmentedTrack` holds **7 dagen / 30 dagen / 90 dagen**, plus **Alles** first
  where a page allows everything (an audit log), and **Aangepast** (with a
  `CalendarDays` icon) as a Radix **Popover** trigger in the same rail.
- The popover has a "Van"/"Tot" pair of `type="date"` inputs (`h-9 rounded-lg`, each
  with a `<Label>`, `max`/`min` tied to each other). Each edit writes the URL straight
  away, so the KPIs follow.
- Choosing Aangepast seeds `van`/`tot` with the window currently shown, so the numbers
  don't jump while the dates are being edited.
- URL: `?periode=7|30|90|alles|aangepast`, `?van=` / `?tot=` (YYYY-MM-DD). Each page names
  its own default: 30 days for analytics, everything for the audit log.
- **KPI labels lose their hardcoded period** ("Actief", not "Actief laatste 30 dagen").
  The control already says it.

### `SearchInput`, debounced

- `h-10 w-full rounded-[10px] border border-border bg-card pl-[34px] pr-3 text-[13.5px]`,
  with a leading `Search` icon (`size-4`, muted, `pointer-events-none`), an `sr-only`
  `<label>`, and a placeholder that repeats it ("Zoek op naam of e-mail").
- Keep a local draft and write `?zoek=` (trimmed) **250 ms** after the last keystroke.
  When the URL changes underneath it (a "Wissen" click, back navigation), the box follows.

### `TableCard` + `TableToolbar`

```tsx
<TableCard>  {/* min-w-0 overflow-hidden rounded-xl border border-border bg-card */}
  <TableToolbar count={t("count", { count: rows.length })}>  {/* flex flex-wrap items-center gap-3 border-b px-4 py-3 */}
    <SearchInput id="branch-search" label={t("search")} value={search} className="w-full sm:w-72" />
    <FilterChip id="branch-status" param="status" label={t("status")} value={status ?? ""}
      allLabel={t("allStatuses")} options={statusOptions} />
    <ClearFilters params={["zoek", "status"]} active={hasTableFilters} />
  </TableToolbar>
  {rows.length === 0 ? <EmptyResults params={["zoek", "status"]} /> : <Table>…</Table>}
</TableCard>
```

- Order: search, then table filters, then "Wissen", then the count pushed right
  (`ml-auto text-[12.5px] whitespace-nowrap text-muted-foreground`), pluralised through
  the catalogue ("1 teamlid" / "12 teamleden").
- The table scrolls sideways **inside the card** (the shared `<Table>` wrapper owns the
  overflow), never the page.
- Header cells: `px-3 py-[11px] text-[11.5px] font-bold tracking-[0.06em] uppercase
  text-muted-foreground first:pl-[18px]`. Body cells: `px-3 py-[13px] first:pl-[18px]`.

### `SortableHead`

- A `<button>` inside the `<th>`, which carries `aria-sort="ascending|descending|none"`.
  It writes `?sort=<column>&dir=asc|desc`.
- The active column shows one arrow (`ArrowUp`/`ArrowDown`, `size-3.5 text-foreground`)
  and its label turns ink. Inactive sortable columns show `ChevronsUpDown` in
  `text-muted-foreground/70`. An `sr-only` span says "Sorteer op …" or the current
  direction.
- Clicking the active column flips it. Clicking another column starts at
  `initialDirection`, which is `desc` for dates, scores and progress.
- Sort only where it means something: name, dates, progress, counts. Never free-text or
  action columns.

### `ClearFilters` and `EmptyResults`

- `ClearFilters` ("Wissen", a ghost `Button` at `h-10 px-3 text-[13px]`) drops the listed
  params in one update. It renders **only when `active`**, and `active` is computed on
  the server from the parsed values, so it never appears at defaults. It resets filters
  and search, not the sort.
- `EmptyResults` sits **inside the table card** under the toolbar, so the filters that
  caused it stay in view: `role="status"`, `px-6 py-12 text-center text-sm
  text-muted-foreground`, "Geen resultaten" plus an outline "Filters wissen".

## Server side (`lib/list-query.ts`, `lib/period-query.ts`)

The query-string shape is the same everywhere: `?zoek=`, one param per chip,
`?sort=`/`?dir=`, and `?periode=`/`?van=`/`?tot=`. Parse it in one place:

- `parseSearchParam(sp, "zoek")`, `parseEnumParam(sp, key, values)` (unknown values →
  `undefined`), `parseSortParam(sp, columns, fallback)`.
- `matchesSearch(query, ...fields)`: case-insensitive substring, and an empty query
  matches everything.
- `sortRows(rows, sort, valueFor)`: a stable sort with nulls **last** in both
  directions, `localeCompare(…, "nl", { sensitivity: "base" })` for strings.
- `parsePeriod(sp, now, { allowAll, defaultPreset })` returns
  `{ preset, isDefault, from, to, fromDate, toDate }` in the organisation's time zone.
  A malformed or inverted custom range falls back to the default rather than an empty
  window. `periodParams(period)` rebuilds the query for links.

The page filters and sorts in memory (or passes the parsed values to the repository) and
renders only the result. First paint is already filtered, with no client spinner.

## The rules

1. **Filters apply on change.** No "Toepassen"/"Filteren" button, no GET `<form>`.
2. **"Wissen" only when something differs from its default.**
3. **No separate scope indicators.** The chip's value is the indicator.
4. **Page-level filters go in the page header**, right-aligned next to the title, and
   wrap below it under `md`.
5. **Table-level filters go in the `TableToolbar`**, not the page header.
6. **Time-based data gets the `PeriodControl`**, and KPI labels drop their hardcoded
   period.
7. **Sortable where it means something:** name, dates, progress.
8. **The URL is the state.** Filters, search and sort live in the query string, written
   with `replace`; search is debounced by about 250 ms.
9. **Mobile:** toolbars wrap, segmented rails and tables scroll inside themselves, and
   the page never scrolls sideways.
10. **Empty results:** "Geen resultaten" plus "Filters wissen", inside the table card.

Every string (keys, values, counts, empty state, sort announcements) comes from a
`filters` namespace in the message catalogue, in nl and en.

## Retrofitting an existing app

1. **Audit first, change nothing.** List every page or component with filters, search,
   sort, apply/clear buttons, scope badges or table toolbars, with file paths and the
   pattern each one uses now.
2. **Build the shared components and the two parsers once.** No new dependencies; reuse
   the vendored Select, Popover, Button and Table.
3. **Apply the rules page by page.** Add unit tests for the parsers, and e2e/axe
   coverage for the new controls (chip, segments, popover, sort, empty state, 320px).
4. **Report** what changed on each page, and flag any filter that didn't fit
   (multi-select facets, cross-page scope) for a decision rather than forcing it in.
