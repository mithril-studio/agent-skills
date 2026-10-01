# agent-skills

My skills for coding agents, in one place, so any agent on any machine can be given the
same capabilities with one command.

A skill is a folder with a `SKILL.md`: frontmatter naming it and describing when to use it,
then instructions in markdown. No code runs on your machine to install one — it is text an
agent reads.

Skills are grouped into category folders here (`engineering-skills/checkpoint-commits/`) but
install flat, because that is the layout agents read (`~/.claude/skills/checkpoint-commits/`).

## Install

```bash
git clone https://github.com/mithril-studio/agent-skills
cd agent-skills
./install.sh                      # everything -> ~/.claude/skills
./install.sh checkpoint-commits   # just one
./install.sh engineering-skills   # a whole category
./install.sh --dest /some/path    # somewhere else
./install.sh --list               # show what is available
```

`references/` installs alongside, one level above the skills directory
(`~/.claude/references/`), because that is where the skills' `../../references/…` links
resolve to once a skill sits in `~/.claude/skills/<name>/`.

Onto a remote machine — a boxd VM, a server, a container:

```bash
./install.sh --dest /tmp/skills
scp -r /tmp/skills/* host:~/.claude/skills/
```

Or straight from the VM itself, which is how the software factory's golden images do it:

```bash
git clone --depth 1 https://github.com/mithril-studio/agent-skills /tmp/agent-skills \
  && /tmp/agent-skills/install.sh
```

## Skills

### [`engineering-skills`](./engineering-skills)

How I want an agent to write, review, and change code.

| Skill | What it does |
|---|---|
| [`bounded-waits`](./engineering-skills/bounded-waits) | Cap how long you babysit a backgrounded slow command — never let watching it finish outrank committing and opening the PR. |
| [`checkpoint-commits`](./engineering-skills/checkpoint-commits) | Commit and push every working increment as you go, so a crash, timeout, or killed VM never loses finished work. |
| [`code-review-and-quality`](./engineering-skills/code-review-and-quality) | Multi-axis review of a change before it merges — whether a human, you, or another agent wrote it. |
| [`code-simplification`](./engineering-skills/code-simplification) | Cut accumulated complexity out of working code without changing its behavior. |
| [`debugging-and-error-recovery`](./engineering-skills/debugging-and-error-recovery) | Find the root cause of a failure systematically instead of guessing at it. |
| [`doubt-driven-development`](./engineering-skills/doubt-driven-development) | Put every non-trivial decision through a fresh-context adversarial review before it stands. For when verifying now is cheaper than debugging later. |
| [`incremental-implementation`](./engineering-skills/incremental-implementation) | Land multi-file changes in verifiable steps instead of one large drop. |
| [`security-and-hardening`](./engineering-skills/security-and-hardening) | Harden code that touches untrusted input, auth, storage, or third-party services. |
| [`test-driven-development`](./engineering-skills/test-driven-development) | Prove behavior with a failing test first — for new logic, and for every bug before its fix. |

### [`factory-skills`](./factory-skills)

How work gets planned before an agent touches it.

| Skill | What it does |
|---|---|
| [`factory-compose`](./factory-skills/factory-compose) | Turn a project brief into an ordered backlog of GitHub issues the Software Factory builds lowest-number-first. The issue body is the building agent's whole prompt and the reviewing agent's contract, so it carries a grounded file map, boundaries, and acceptance criteria that are executed rather than judged. Drafts for human review; creates only on approval. |

Unlike the other categories, this one runs *outside* the VM — on a laptop or a planner box,
against GitHub — rather than inside a build run.

### [`references`](./references)

Shared checklists several skills link to rather than restate. Not skills — no `SKILL.md`,
never installed as one.

| File | Linked from |
|---|---|
| [`definition-of-done.md`](./references/definition-of-done.md) | `incremental-implementation` |
| [`orchestration-patterns.md`](./references/orchestration-patterns.md) | `doubt-driven-development` |
| [`performance-checklist.md`](./references/performance-checklist.md) | `code-review-and-quality` |
| [`security-checklist.md`](./references/security-checklist.md) | `code-review-and-quality`, `security-and-hardening` |
| [`testing-patterns.md`](./references/testing-patterns.md) | `test-driven-development` |

Every link sits under a `## See Also` heading, which is the point: a skill's `SKILL.md`
is loaded in full whenever that skill fires, so the 205-line security checklist stays out
of it and is read only when a review actually goes deep on security.

## Provenance

Most of `engineering-skills` is vendored from an MIT-licensed upstream, not written here.

| Skill | Upstream |
|---|---|
| `code-review-and-quality`, `code-simplification`, `debugging-and-error-recovery`, `doubt-driven-development`, `incremental-implementation`, `security-and-hardening`, `test-driven-development` | [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) — MIT, © Addy Osmani |
| `bounded-waits`, `checkpoint-commits` | Mine — no upstream |

All of `references/` is from addyosmani/agent-skills too, same license.

### Staying honest about the fork

A vendored copy is a fork, and a fork nobody checks goes stale invisibly.
[`upstream.tsv`](./upstream.tsv) records where every vendored path came from, and
`upstream-diff.sh` compares them against the live upstreams:

```bash
./upstream-diff.sh                      # summary: same / DRIFT / GONE
./upstream-diff.sh --diff               # what actually changed
./upstream-diff.sh security-and-hardening   # one entry
./upstream-diff.sh --refresh            # re-fetch upstream first
./upstream-diff.sh --check              # exit 1 on any drift, for CI
```

Drift is not a failure. Editing a vendored skill on purpose is fine — the script exists so
that choice stays visible instead of turning into a surprise later. Upstreams are cached in
`.upstream-cache/` (gitignored); `--refresh` updates them.

When you take ownership of a vendored skill for good, delete its row from `upstream.tsv`
and move it to the "Mine" line above.

## What belongs here

**Mine, or vendored deliberately.** Skills that encode how I want an agent to work. Where a
skill is someone else's, the Provenance table says whose — a vendored copy is a fork, and a
fork nobody records is a fork that silently goes stale.

**Not vendor tooling skills.** The boxd, n8n, langfuse and sentry skills ship from their own
sources and update with the tool they describe. Reference them, don't copy them.

**Not personal workflow.** Chief-of-staff commands, inbox triage, anything touching private
context stays out of a public repo.

## Writing one

Put the folder inside the category it belongs to — `engineering-skills/my-skill/SKILL.md`.
A skill at the top level is picked up too, so a new category can wait until there is a
second skill to justify it.

Frontmatter needs `name` and `description`. The description is the only thing an agent sees
before deciding whether to load the skill, so it must say **when to use it**, not just what
it is — include the trigger phrases and situations that should pull it in.

```markdown
---
name: my-skill
description: Does X. Use when the user asks for Y, mentions Z, or a repo contains W.
---

# My skill

Instructions...
```

Keep skills passive: they tell the agent what to do, they don't contain a model and they
don't make decisions of their own. The caller has the intelligence.
