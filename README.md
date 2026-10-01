# agent-skills

My skills for coding agents, in one place, so any agent on any machine can be given the
same capabilities with one command.

A skill is a folder with a `SKILL.md`: frontmatter naming it and describing when to use it,
then instructions in markdown. No code runs on your machine to install one — it is text an
agent reads.

Skills are grouped into category folders here (`engineering-skills/code-review-and-quality/`) but
install flat, because that is the layout agents read (`~/.claude/skills/code-review-and-quality/`).

## Install

```bash
git clone https://github.com/mithril-studio/agent-skills
cd agent-skills
./install.sh                      # everything -> ~/.claude/skills
./install.sh code-review-and-quality  # just one
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

How I want an agent to write, review, change, and ship code.

| Skill | What it does |
|---|---|
| [`code-review-and-quality`](./engineering-skills/code-review-and-quality) | Multi-axis review of a change before it merges — whether a human, you, or another agent wrote it. |
| [`git-workflow-and-versioning`](./engineering-skills/git-workflow-and-versioning) | Commits, branches, conflicts, parallel worktrees, semantic version bumps, tags, changelogs. |
| [`incremental-implementation`](./engineering-skills/incremental-implementation) | Land multi-file changes in verifiable steps instead of one large drop. |
| [`performance-optimization`](./engineering-skills/performance-optimization) | Profile and fix performance across frontend, backend, queries and databases — measure before changing. |
| [`ship-to-boxd`](./engineering-skills/ship-to-boxd) | Update the boxd VM that runs a repo's app: pull `origin/<branch>` into the checkout on the VM, rebuild, restart, verify health, report before/after commits. Defers to a repo's own deploy script when one exists. |

### [`references`](./references)

Shared checklists several skills link to rather than restate. Not skills — no `SKILL.md`,
never installed as one.

| File | Linked from |
|---|---|
| [`definition-of-done.md`](./references/definition-of-done.md) | `incremental-implementation` |
| [`performance-checklist.md`](./references/performance-checklist.md) | `code-review-and-quality`, `performance-optimization` |
| [`security-checklist.md`](./references/security-checklist.md) | `code-review-and-quality` |

Every link sits under a `## See Also` heading, which is the point: a skill's `SKILL.md`
is loaded in full whenever that skill fires, so the 205-line security checklist stays out
of it and is read only when a review actually goes deep on security.

## Provenance

Everything in `engineering-skills` except `ship-to-boxd` is vendored from an MIT-licensed
upstream, not written here.

| Skill | Upstream |
|---|---|
| `code-review-and-quality`, `git-workflow-and-versioning`, `incremental-implementation`, `performance-optimization` | [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) — MIT, © Addy Osmani |
| `ship-to-boxd` | Mine — no upstream |

All of `references/` is from addyosmani/agent-skills too, same license.

### Staying honest about the fork

A vendored copy is a fork, and a fork nobody checks goes stale invisibly.
[`upstream.tsv`](./upstream.tsv) records where every vendored path came from, and
`upstream-diff.sh` compares them against the live upstreams:

```bash
./upstream-diff.sh                      # summary: same / DRIFT / GONE
./upstream-diff.sh --diff               # what actually changed
./upstream-diff.sh code-review-and-quality  # one entry
./upstream-diff.sh --refresh            # re-fetch upstream first
./upstream-diff.sh --check              # exit 1 on any drift, for CI
```

Drift is not a failure. Editing a vendored skill on purpose is fine — the script exists so
that choice stays visible instead of turning into a surprise later. Upstreams are cached in
`.upstream-cache/` (gitignored); `--refresh` updates them.

When you take ownership of a vendored skill for good, delete its row from `upstream.tsv`
and list it in the Provenance table as yours.

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
