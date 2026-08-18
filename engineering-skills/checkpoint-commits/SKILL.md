---
name: checkpoint-commits
description: Commit and push every working increment as you go, instead of holding all work uncommitted until the session ends. Use during any multi-step implementation session — especially long or unattended ones (a factory run, a background agent, anything that can be killed by a timeout, a crash, or a lost connection) — where uncommitted work has nowhere else to live.
---

# Checkpoint commits

An agent session can end before you expect it to: a run-level timeout, a killed VM, a
dropped connection, an exhausted turn budget. Whatever you haven't committed and pushed at
that moment does not exist for whoever — or whatever — picks up next. They start from
scratch, at full cost, having learned only what your logs happened to say.

**Commit is the checkpoint. Push is the durability guarantee.** A local commit survives a
crash of the process but not the loss of the machine it's on. A pushed commit survives
either.

## The rule

After every increment that is genuinely done — it does what it's supposed to and its own
check passes (a test file, a typecheck, a lint pass, a manual verification) — commit it and
push it to the current branch immediately. Don't batch several increments into one commit
at the end "to keep history clean." A clean history is worth nothing if the history never
gets written.

Concretely:

- One vertical slice (one seam, one behavior) → one check → one commit → one push.
- Never let "I'll commit once it's all working" span more than one slice. If you're mid-way
  through a second feature with the first one still uncommitted, stop and commit the first.
- Prefer several small, honestly-scoped commits over one large one. Squashing is a later,
  optional step for whoever reviews the history — it is not a reason to defer committing now.
- If you inherit prior work already on the branch (a retry, a resumed session), the same
  rule applies going forward from wherever it left off — don't wait to "catch up" all at
  once either.

## What this is not

Not a call to commit broken or half-finished code. The gate is still "this increment does
what it's supposed to and its check passes" — checkpoint commits are frequent *finished*
increments, not a lower bar for what counts as done.
