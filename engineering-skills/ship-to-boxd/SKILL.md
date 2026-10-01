---
name: ship-to-boxd
description: Update the boxd VM that runs this repository's app — pull the latest commits from GitHub into the checkout on the VM, rebuild, restart, and verify it is healthy. Use when the user says "deploy", "ship it", "ship to boxd", "update the VM", "pull the latest on the box", "rebuild on the VM", "is the server up to date", or names a boxd machine and asks for the newest code on it. Runs from a laptop or planner box that has the boxd CLI, never from inside the VM.
---

# Ship to boxd

The repo's app runs on one always-on boxd machine that holds a git checkout of it. Shipping
means: make that checkout match what is on GitHub, rebuild, restart, prove it is up. You drive
the VM from here with `boxd machine exec`; you never edit code on it.

The `boxd-cli` skill (installed with the CLI at `~/.claude/skills/boxd-cli/`) is the reference
for the CLI itself. This skill is the procedure.

## Before anything: does the repo already know how to deploy?

Look for a deploy script (`scripts/deploy.sh`, `deploy.sh`, a `deploy` target in a Makefile or
justfile) and a Deployment section in `AGENTS.md`, `CLAUDE.md`, or the README.

- **A deploy script exists.** Run it, the way its header and `AGENTS.md` say to. Run its dry-run
  form first when it has one (`--check`, `--dry-run`, `status`). Then stop: the script is the
  procedure, and the rest of this skill is for repos that have none.
- **Deploy notes exist but no script.** They name the VM, the path, the branch, the build and
  the service. Take every value from them. The steps below apply.
- **Nothing exists.** Work it out in step 1, confirm it with the user before you touch the
  machine, and write it down at the end so the next ship is deterministic.

## 1. Pin down the target

You need five facts. Find each in the repo first, on the machine second, and ask when a
source disagrees or is missing. Never guess a VM name from similarity to the repo name.

| Fact | Where it lives |
|---|---|
| VM name | Deploy notes; else `boxd ls` and ask which one |
| Checkout path on the VM | Deploy notes; else `boxd machine exec VM -- 'ls -d /home/boxd/*/.git'` |
| Branch that ships | Deploy notes; else the branch the VM checkout is on (`git -C PATH branch --show-current`) |
| Build commands | Deploy notes; else the project's own docs and manifest (`package.json` scripts, `pyproject.toml`, `Makefile`), the same ones CI runs |
| How the app runs | Deploy notes; else a systemd unit (`systemctl list-units --type=service \| grep -i NAME`), `pm2 ls`, or `docker compose ps` in the checkout |

Machines are `2 vCPU / 8 GiB`, the user is `boxd` with passwordless sudo, home is `/home/boxd`.

## 2. Decide what ships: the branch as it is on origin

What reaches the server is `origin/<branch>`, never your working tree.

```bash
git fetch origin <branch>
WANT=$(git rev-parse origin/<branch>)
```

If you have commits that are not on origin and the user wants them shipped, land them the way
the repo's rules say (push, land script, PR), then re-fetch. Say so explicitly if you ship
without them.

## 3. Make sure the machine is up

```bash
boxd machine get VM --json       # .status
```

| Status | Do |
|---|---|
| `running` | Continue. |
| `standby` | Continue; the first exec wakes it. |
| `hibernated` | `boxd machine wake VM`, then poll `get` until `running`. |
| `stopped` | `boxd machine start VM`, then poll `get` until `running`. |
| missing, `failed`, `destroying` | Stop and report. Provisioning a machine is not this skill. |

## 4. Read the machine before writing to it

```bash
boxd machine exec VM -- 'cd PATH && git rev-parse HEAD && git branch --show-current && git status --porcelain'
```

- Record the SHA as **BEFORE**. Every report and every rollback uses it.
- **Dirty working tree or a different branch: stop.** Something changed on the VM outside git.
  Report what `git status` shows and let the user decide. Never stash, reset, or commit on the
  VM to make the problem go away.
- `BEFORE` equal to `WANT`: the machine is already current. Say so and stop, unless the user
  asked for a rebuild anyway.

Take a rollback point before the pull. A checkpoint restores in place and costs seconds:

```bash
boxd machine checkpoint save VM pre-ship-${BEFORE:0:7}
boxd machine checkpoint list VM     # keep the last three pre-ship-*; remove older ones (limit is 10)
```

## 5. Pull

```bash
boxd machine exec VM -- 'cd PATH && git fetch origin <branch> && git merge --ff-only origin/<branch> && git rev-parse HEAD'
```

The result must equal `WANT`. Fast-forward only: if the merge refuses, the VM's history has
diverged from origin and someone has to look, so stop and report. If `fetch` fails on
authentication, the machine's GitHub credential is the owner's to fix; report it, never paste a
token into an exec.

## 6. Build

Run the repo's documented steps, in the repo's order, each as its own exec so a failure names
its step:

1. Install dependencies from the lockfile (`npm ci`, `pnpm install --frozen-lockfile`,
   `uv sync`, `cargo build --release`, whatever the repo uses).
2. Build.
3. Migrations, only if the repo documents them as part of a deploy.

```bash
boxd machine exec VM --timeout 900 -- 'cd PATH && npm ci --no-audit --no-fund 2>&1 | tee /tmp/ship-install.log'
```

Anything over ten seconds goes in a background command; poll its output rather than sleeping.
Pipe through `tee` to a log, never through `tail` or `grep` at the top level (that stalls the
stream). Decide a wait budget before you start, and when a build blows past it, stop watching
and report rather than let the session run out mid-watch.

Do not add, upgrade, or remove dependencies, and do not edit config or env files on the VM to
make a build pass. A build that fails on the VM is fixed in git and shipped again.

## 7. Restart and flush

```bash
boxd machine exec VM -- 'sudo systemctl restart SERVICE && sync'
```

`sync` matters: boxd reboots are cold, and an unflushed release can vanish in one. For pm2 use
`pm2 restart NAME`, for docker compose `docker compose up -d --build`; same `sync` after.

## 8. Verify

1. **The process is up.** `sudo systemctl is-active SERVICE` (or the pm2/compose equivalent).
2. **It answers locally.** `curl -fsS http://127.0.0.1:PORT/health` or whatever the app's
   cheapest honest endpoint is, polled for up to a minute.
3. **It answers publicly.** `curl -fsS https://VM.boxd.sh/...` using the `url` from
   `boxd machine get VM --json`. If the app runs on a port other than 8000 and nothing
   answers, the proxy may be pointed elsewhere: `boxd machine proxy list --vm VM`.
4. **It runs the new code.** If the app exposes a version or commit, check it equals `WANT`.

On failure: `sudo journalctl -u SERVICE -n 80 --no-pager`, then roll back (below) unless the
user wants to debug live. Do not leave a dead service behind and call it done.

## 9. Report

One short block, from facts you observed, not from what you intended:

- `VM`, branch, `BEFORE` → `WANT` (short SHAs), and the commits in between
  (`git log --oneline BEFORE..WANT` locally).
- What was verified and how (service active, local health, public URL).
- Anything skipped or left for the user: unpushed local work, a migration not run, a check
  that could not be made.

## Rollback

Two ways, in order of preference:

1. **Git.** `git reset --hard BEFORE` in the checkout, rebuild (step 6), restart (step 7),
   verify (step 8). Keeps everything else on the machine intact.
2. **Checkpoint.** `boxd machine checkpoint restore VM pre-ship-<short>`. Reboots the machine
   into the exact pre-ship state, including memory; anything written to disk after the
   checkpoint is lost. Use it when the build itself broke the machine.

## Leave the repo smarter than you found it

If you had to work the target out in step 1, propose a Deployment section for `AGENTS.md` with
the five facts and the health endpoint, and the one-liner that this skill now is for this repo.
The next agent should not rediscover any of it.

## Hard rules

- `boxd machine exec`, never `boxd connect`: connect needs a TTY and refuses to run in a
  script. Keep exec flags before the command, the `--` after the machine name, and wrap any
  command with `&&`, pipes, or redirects in single quotes.
- Code changes happen in git, never on the VM.
- Never print the contents of `.env`, `secrets/`, or an EnvironmentFile, and never rewrite them.
- Never `rm`, `fork`, `rename`, `share`, or reconfigure the machine. This skill updates what
  runs on it; it does not change what the machine is.
- Ship only what is on origin. If it is not pushed, it is not shipped.
