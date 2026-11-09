# Daily Development Audit: routine prompt

Paste this into the Conductor routine "Daily Development Audit". It replaces the prompt in
use until 2026-11-09. Changes from that version: the routine may act, not only propose; it
keeps a standing list of at most three experiments in
`routines/daily-development-audit/EXPERIMENTS.md` instead of inventing one a day; the
report opens with the age and status of each; no-activity days get a short run.

---

Audit my development work over the last 24 hours and identify practical ways to improve my velocity. This is the "Daily Development Audit" routine.

Owner: info@mithril-studio.com, Conductor user ID 97f187e4-d432-42b8-9439-e91d079b2fba.

Standing experiments

- Before anything else, read `routines/daily-development-audit/EXPERIMENTS.md` from `main` of mithril-studio/agent-skills. It holds at most three open experiments with their first-proposed date, metric and status, plus the closed ones. The first lines of your report are one line per open experiment: ID, days open, status today, one sentence of evidence.
- Assess each open experiment against today's evidence and its metric. Classify as helped, did not help, not tried, in progress, or insufficient evidence. A recommendation is not an implementation; an absent recurrence is not proven improvement.
- Close an experiment when its metric has been observed on two days, or retire it after 7 days without adoption and say why. Only when a slot is free may you add one new experiment, and only if today's evidence supports it. Do not re-propose a closed experiment under a new ID; reopen it with its original ID and say so.
- At the end of the run, rewrite EXPERIMENTS.md with the new state and open a PR to `main` of agent-skills titled "audit: experiments <UTC date>". Merge it yourself if the only changes are under `routines/daily-development-audit/`.

What you may do

- You may carry out an open experiment's change when it is reversible and inside the repositories: open a PR that edits AGENTS.md, CI workflows or skills; close a PR whose tree equals its base; delete branches of merged PRs; re-target a PR; open or comment on a GitHub issue; create one throwaway Conductor workspace to measure a setup experiment, and archive it afterwards.
- Do not deploy, run migrations, change production data, force-push, merge a PR you did not open (except the EXPERIMENTS.md PR), rotate secrets, or message other people. Repository settings need the owner's token (the cloud token gets HTTP 403); list those as a one-click item with the exact `gh api` command.
- Say in the report exactly what you changed, with links.

Coverage

- Cover my work across ALL accessible Conductor projects, repositories, workspaces, sessions and branches, including archived ones. The repository and branch used to launch this routine are only its execution context, never its audit boundary.
- Freeze the audit end time at run start; examine the preceding 24 hours. State the exact interval and timezone. Include activity on older branches and sessions updated during that interval.
- Enumerate all pages of `conductor --json workspace list --mine --include-archived --limit 100 --offset ...`. For each workspace with `lastActivityAt` or `createdAt` in the window, or within 48 hours before it, enumerate its sessions with `conductor --json workspace session <workspaceId> --include-archived --limit 100 --offset ...` and read every page of their messages. Attribute events by message `receivedAt`, never by a session's creation date.
- If `conductor sql` exists, use it to batch transcript discovery filtered on `workspace_creator_id` and the window; read `conductor sql --help` first. If it does not exist, say so once and use the enumeration above.
- Discover all projects with paginated `conductor project list`. For every repository, enumerate PRs updated in the window across all states, commits on all branches, and Actions runs. For a repository with development activity, mirror-clone it and inspect history across all refs; deduplicate commits shared by branches and note rebases or cherry-picks. Do not attribute other contributors' work to me.
- Include uncommitted work, abandoned attempts, debugging, repeated instructions and failed tests when transcripts or workspace files show them. Do not treat commit count or lines changed as productivity. Do not infer hours lost from gaps between messages.
- State coverage explicitly: projects, workspaces, sessions, refs and PRs examined, and what could not be accessed (Mac-only edits, unpushed checkouts, GitHub UI actions visible only through commits, deleted history, inaccessible sessions).

No-activity days

- If no session had messages in the window and no repository had commits or PR updates from me, write a report of at most 15 lines: the interval, the coverage counts, the standing-experiment lines, and nothing else. Do not propose anything.

Report

1. The standing-experiment lines (see above), then two or three sentences of meaningful progress with links to workspaces, sessions, PRs, commits or CI runs, then coverage.
2. Up to three highest-impact bottlenecks. For each: concrete examples with links, recurring or one-off, likely cause and confidence, the smallest practical improvement, a measurable success criterion. Fewer if fewer are supported. If a bottleneck is already covered by an open experiment, say so instead of describing it again.
3. What you changed this run, with links, and what needs the owner's hand, with the exact command or click.
4. The updated experiment table, and the PR that carries it.

Include a compact experiment record in the final response so the next run can recover it if the PR is not merged: audit interval, run ID, prior report location, each open experiment's ID, status, evidence and next review date, and the actions taken. Save the same report under `.context/daily-development-audit/<UTC-date>.md`. The final Conductor response is the durable handoff.

Keep the report concise and specific. Lead with results, not with the day's novelties.
