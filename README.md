# agent-skills

My skills for coding agents, in one place, so any agent on any machine can be given the
same capabilities with one command.

A skill is a folder with a `SKILL.md`: frontmatter naming it and describing when to use it,
then instructions in markdown. No code runs on your machine to install one — it is text an
agent reads.

Skills are grouped into category folders here (`engineering-skills/safe-refactor/`) but
install flat, because that is the layout agents read (`~/.claude/skills/safe-refactor/`).

## Install

```bash
git clone https://github.com/mithril-studio/agent-skills
cd agent-skills
./install.sh                      # everything -> ~/.claude/skills
./install.sh memory               # just one
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
| [`caveman-explore`](./engineering-skills/caveman-explore) | Read-only repository explorer for cold starts and broad localization. Returns compact `path:line` citations; its reads and greps stay out of the main conversation. |
| [`code-review-and-quality`](./engineering-skills/code-review-and-quality) | Multi-axis review of a change before it merges — whether a human, you, or another agent wrote it. |
| [`code-simplification`](./engineering-skills/code-simplification) | Cut accumulated complexity out of working code without changing its behavior. |
| [`codebase-design`](./engineering-skills/codebase-design) | Shared vocabulary for deep modules: where a seam goes, how to deepen an interface, how to make code testable and navigable. |
| [`context-engineering`](./engineering-skills/context-engineering) | Set up an agent's context and rules files for a project, and fix it when output quality starts degrading. |
| [`domain-modeling`](./engineering-skills/domain-modeling) | Build and sharpen a project's domain model — terminology, `CONTEXT.md`, and ADRs. |
| [`doubt-driven-development`](./engineering-skills/doubt-driven-development) | Put every non-trivial decision through a fresh-context adversarial review before it stands. For when verifying now is cheaper than debugging later. |
| [`frontend-ui-engineering`](./engineering-skills/frontend-ui-engineering) | Build accessible, responsive UI that reads as production-quality rather than AI-generated. |
| [`git-workflow-and-versioning`](./engineering-skills/git-workflow-and-versioning) | Commits, branches, conflicts, parallel worktrees, semantic version bumps, tags, changelogs. |
| [`improve-codebase-architecture`](./engineering-skills/improve-codebase-architecture) | Scan a codebase for deepening opportunities, present them as a visual HTML report, then grill through whichever one you pick. |
| [`incremental-implementation`](./engineering-skills/incremental-implementation) | Land multi-file changes in verifiable steps instead of one large drop. |
| [`lean-build`](./engineering-skills/lean-build) | Build feature work with high overbuilding risk: reuse what the repo has, hold scope, define the stop condition up front. |
| [`safe-refactor`](./engineering-skills/safe-refactor) | Restructure code while preserving behavior, with verification bracketing every structural edit. |

### [`memory-skills`](./memory-skills)

What an agent should carry across sessions.

| Skill | What it does |
|---|---|
| [`memory`](./memory-skills/memory) | Read accumulated project learnings at session start; append new ones before finishing. Append-only JSONL stored in the repo, so learnings ship inside the pull request and compound across sessions. |

### [`references`](./references)

Shared checklists several skills link to rather than restate. Not skills — no `SKILL.md`,
never installed as one.

| File | Linked from |
|---|---|
| [`accessibility-checklist.md`](./references/accessibility-checklist.md) | `frontend-ui-engineering` |
| [`definition-of-done.md`](./references/definition-of-done.md) | `incremental-implementation` |
| [`orchestration-patterns.md`](./references/orchestration-patterns.md) | `doubt-driven-development` |
| [`performance-checklist.md`](./references/performance-checklist.md) | `code-review-and-quality` |
| [`security-checklist.md`](./references/security-checklist.md) | `code-review-and-quality` |

## Provenance

Most of `engineering-skills` is vendored from two MIT-licensed upstreams, not written here.
Recorded so the next person knows what to diff against when upstream moves.

| Skill | Upstream |
|---|---|
| `code-review-and-quality`, `code-simplification`, `context-engineering`, `doubt-driven-development`, `frontend-ui-engineering`, `git-workflow-and-versioning`, `incremental-implementation` | [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) — MIT, © Addy Osmani |
| `codebase-design`, `domain-modeling`, `improve-codebase-architecture` | [mattpocock/skills](https://github.com/mattpocock/skills) — MIT, © Matt Pocock |
| `caveman-explore`, `lean-build`, `safe-refactor`, `memory` | Mine — no upstream |

`references/` is from addyosmani/agent-skills too, same license.

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
