# Daily Development Audit: standing experiments

The audit routine reads this file at the start of every run and rewrites it at the end,
through a PR to `main`. At most three experiments are open at once. A new one may only be
added when a slot is free. Every run's report starts with one line per open experiment:
its ID, how many days it has been open, and its status.

Statuses: `not started`, `in progress`, `helped`, `did not help`, `retired` (superseded or
no longer measurable). An experiment is closed when its metric has been observed on at
least two days with evidence, or after 7 days without adoption (then `retired`, with the
reason).

## Open

| ID | First proposed | Change | Metric | Status | Last evidence |
|---|---|---|---|---|---|
| EXP-2026-11-07-01 | 2026-11-06 | `workflows` and `powerhouse` default branch `main`; delete-branch-on-merge on all 11 repos; close empty #273; re-target #274 | New PRs target `main` without correction; 0 open PRs on a merged base; heads fall from 165 | in progress: settings applied 2026-11-09T07:20Z from the owner's Mac (cloud token gets 403); #273 closed, #274 retargeted and merged, 11 merged branches deleted, heads 156 | 2026-11-09 |
| EXP-2026-11-05-01 | 2026-11-04 | `workflows/AGENTS.md`: plan mode asks at most one question round with a marked recommendation; execution never asks, decides, and lists decisions at the top of the PR body | 0 workspaces archived with an unanswered question; longest wait < 60 min; every PR body lists its decisions | not started (4 reviews). The routine may now open this PR itself | 2026-11-08 |
| EXP-2026-11-06-01 | 2026-11-05 | A `workflows` cloud workspace arrives with `server/node_modules`, `pdftotext` and `CHROME` set, by running Conductor's computer setup for the repo (the `.conductor/settings.toml` path has been inert since 2026-10-27) | 0 `npm ci`, 0 `dnf install`, 0 `CHROME=` typed in `workflows` sessions; `memory-templates` green on the first full run | not started (3 reviews). Needs a fresh `workflows` workspace to measure; the routine may create one throwaway workspace to test | 2026-11-08 |

## Closed

| ID | Proposed | Change | Outcome | Closed |
|---|---|---|---|---|
| EXP-2026-10-20-01 | 2026-10-19 | Clear the decision tail (answer or park open prompts) | did not help: 5 proposals still open after 24h | 2026-10-20 |
| EXP-2026-10-21-01 | 2026-10-20 | Open tasks with "recommend and proceed unless irreversible" | not tried; 3 sessions still ended on an open prompt | 2026-10-21 |
| EXP-2026-10-22-01 | 2026-10-21 | Fix e-learning audit gate; merge only green with a review | gate fix not tried; legal-ai-app stack to main helped (17 to 9 open); 3 merges into non-main bases | 2026-10-22 |
| EXP-2026-10-23-01 | 2026-10-22 | delete-branch-on-merge on 3 repos; merge instructions name `main` | not tried (false on 7 of 7); folded into EXP-2026-11-07-01 | 2026-11-09 |
| EXP-2026-10-24-01 | 2026-10-23 | Env-recovery doc for ship-to-boxd; default branch `main` | doc existed since Oct 14; default branch folded into EXP-2026-11-07-01 | 2026-11-09 |
| EXP-2026-10-25-01 | 2026-10-24 | Default branch `main` on GitHub and the Conductor target | Conductor target changed, helped (stale checkouts 4 to 1); GitHub side folded into EXP-2026-11-07-01 | 2026-11-09 |
| EXP-2026-10-26-01 | 2026-10-25 | Merge setup PR #192 | not tried; PR left conflicting, superseded by #206 | 2026-10-27 |
| EXP-2026-10-27-01 | 2026-10-26 | New setup PR cut from #192 | adopted (#206 merged 2026-10-27) but did not help: 5 of 7 later sessions still ran `npm ci` | 2026-10-27 |
| EXP-2026-10-28-01 | 2026-10-27 | Default branch `main`; probe a fresh workspace; send setup evidence to Conductor | not tried; hypothesis refuted 2026-11-02 (branches from `main` with the TOML present were still bare); folded into EXP-2026-11-06-01 | 2026-11-05 |
| EXP-2026-11-03-01 | 2026-11-02 | Migration-number guard test plus an AGENTS.md line | not tried over 4 reviews; 2 manual renumberings happened meanwhile; retired until a second parallel-migration day gives a measurement | 2026-11-09 |
| EXP-2026-11-04-01 | 2026-11-03 | Prompt line "take the recommended option, list decisions in the PR" | not tried (0 of 30 prompts); superseded by EXP-2026-11-05-01 | 2026-11-04 |
| EXP-2026-11-08-01, EXP-2026-11-09-01 | 2026-11-07, 2026-11-08 | Re-proposals of EXP-2026-11-07-01 | merged into EXP-2026-11-07-01 | 2026-11-09 |

## Standing items (not experiments, checked every run)

- 0 reviews on merged PRs since 2026-10-20 (0 of 49 on 2026-11-02, 0 of 13 on 2026-11-06).
- `workflows` has no CI; full suites run inside agent sessions (4 runs for one PR on 2026-11-06, 2 wasted).
- `legal-ai-app` #163 open since 2026-11-05 with 0 reviews.
- Unreviewed Inbox redesign (5e7fd75) shipped to production inside #271 on 2026-11-06.
- Audit runs on no-activity days cost about 4 USD each (runs 20 and 21); the prompt now shortens those runs.
