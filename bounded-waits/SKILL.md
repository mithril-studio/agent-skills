---
name: bounded-waits
description: Cap how long you passively babysit a backgrounded long-running command (a full e2e suite, a build, a slow integration run) before moving on. Use whenever you background a command and start polling for it to finish, especially near the end of a session — never let watching a slow check consume the time or turn budget you need to commit and open the PR.
---

# Bounded waits

A backgrounded long-running command (a full Playwright/e2e suite, a slow build, an
integration run) is easy to get stuck babysitting: poll, sleep, poll again, and the session
runs out of turns or hits its timeout with the watching still in progress — before the
finished work ever got committed or the PR ever got opened. The work existed; nothing shows
it.

## The rule

Before backgrounding a slow command, decide the wait budget up front: a number of poll
cycles or a wall-clock cap. When you hit it and the command still isn't done, stop watching
it. Then:

1. **Prefer a narrower, faster check that still gives a real signal** — a single test file
   instead of the full suite, a typecheck instead of a full build — over continuing to wait
   on the slow one.
2. **If no fast substitute exists, stop waiting anyway.** Commit and push what's done, open
   the PR, and say plainly in the PR/commit that the full suite hasn't finished locally.
   Let CI (or a human) carry the slow check to completion — that's what it's for.

The deliverable — a commit, a pushed branch, an opened PR — always outranks watching a slow
check finish. A run that ends with passing-but-uncommitted work and no PR has produced
nothing usable; a run that ends with committed work and an honestly-flagged "e2e still
running in CI" has produced something real.

## Signal to catch yourself

If you notice you're several cycles into "check again, still running, wait more" with no
new information between checks, that's the moment to apply this skill — not two cycles
later.
