# agent-skills

My skills for coding agents, in one place, so any agent on any machine can be given the
same capabilities with one command.

A skill is a folder with a `SKILL.md`: frontmatter naming it and describing when to use it,
then instructions in markdown. No code runs on your machine to install one — it is text an
agent reads.

## Install

```bash
git clone https://github.com/mithril-studio/agent-skills
cd agent-skills
./install.sh                      # everything -> ~/.claude/skills
./install.sh memory               # just one
./install.sh --dest /some/path    # somewhere else
```

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

| Skill | What it does |
|---|---|
| [`memory`](./memory) | Read accumulated project learnings at session start; append new ones before finishing. Append-only JSONL stored in the repo, so learnings ship inside the pull request and compound across sessions. |

## What belongs here

**Mine.** Skills I wrote, that encode how I want an agent to work.

**Not third-party skills.** The boxd, n8n, langfuse and sentry skills come from their
vendors and are installed from their own sources — copying them here means maintaining a
fork that silently goes stale. Reference them, don't vendor them.

**Not personal workflow.** Chief-of-staff commands, inbox triage, anything touching private
context stays out of a public repo.

## Writing one

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
