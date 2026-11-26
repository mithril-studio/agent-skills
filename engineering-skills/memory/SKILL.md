---
name: memory
description: Read accumulated project learnings at session start and record new ones before finishing. Use at the beginning of every task to load what past sessions learned about this repo, and at the end to write down conventions, failures and their fixes, patterns, and decisions worth carrying forward. Triggers on "what do we know about", "record this learning", "prime memory", or any task in a repo containing a .mem/ directory.
---

# Memory

Agents start every session from zero. The pattern discovered yesterday is gone today. This
skill fixes that: learnings are stored as append-only JSONL inside the repo, travel with the
pull request, and are read back at the start of the next session.

**The file is the database.** There is no server and no daemon — everything here is plain file
I/O with the tools you already have. There *is* an index, but it is a checked-in file you append
to like any other, not something to rebuild.

## §1 When to use this

- **At session start, always.** Before writing any code, prime yourself (§4).
- **Before finishing, when you learned something reusable.** Record it (§5).

Do not record for the sake of recording. A session that discovered nothing new writes
nothing. Empty is a valid outcome; noise is not.

## §2 Layout

```
.mem/
  index.jsonl             # one short line per ACTIVE record — the scan surface (§2.1)
  domains/
    <domain>.jsonl        # the full active records, one per line, e.g. database.jsonl
    _universal.jsonl      # records with no domain anchor — always primed
  archive/
    <domain>.jsonl        # records that have been retired (§6). Never primed.
```

Three places, and each holds a record in exactly one state:

- a record you can act on is a line in `index.jsonl` **and** a line in `domains/<domain>.jsonl`
  with `status: active`;
- a record that has been retired is a line in `archive/<domain>.jsonl` and appears in neither
  of the other two.

There is no fourth combination. An id in the index with no active record behind it, or an
`active` record sitting in `archive/`, is a broken store — and in a repo that validates its
memory (§7) it is a failed build, not a cosmetic problem.

Domains are free-form lowercase slugs naming an area of the codebase: `database`, `auth`,
`ci`, `frontend`. Use an existing domain if one fits — check `ls .mem/domains/` first.
Create a new file only when nothing fits.

If `.mem/` does not exist and you have something worth recording, create it.

### §2.1 The index line

The index exists so priming is cheap: you read one small file to decide what is worth opening,
instead of every full record in every domain. That only works if the lines stay short.

```json
{"id":"mem_7a3f","domain":"database","type":"convention","title":"Use WAL mode for SQLite","files":["src/db/*.ts"]}
```

| Field | Rule |
|---|---|
| `id`, `domain`, `type` | Copied from the record. All three required. |
| `title` | **The record's title, character for character.** Do not shorten it to fit. |
| `files` | A list — the record's `evidence.files`. `[]` if the learning is not code-local. |

Keep the line under ~350 bytes. If it does not fit, the *title* is too long — fix it in the
record and copy the shorter one, so the two still match. A title that has been trimmed on its
way into the index is the most common way this store breaks, and it is caught, not tolerated.

## §3 The record

One record = one reusable learning = one line of JSON. Never pretty-printed; never edited in
place.

```json
{"id":"mem_7a3f","domain":"database","type":"convention","title":"Use WAL mode for SQLite","body":"Concurrent readers block on the default rollback journal...","resolution":null,"evidence":{"files":["src/db/*.ts"],"dirs":["src/db"],"branch":"feat/wal","issues":["owner/repo#42"],"run":"<run.id>"},"provenance":{"author":"agent:claude-code","backend":"boxd","created_at":"2026-07-30T09:00:00Z"},"status":"active","supersedes":null,"confidence":"high","hits":0}
```

| Field | Rule |
|---|---|
| `id` | `mem_` + 4 random hex. Check the domain file for collisions. |
| `domain` | Matches the filename. `_universal` for records with no anchor. |
| `type` | One of §3.1. |
| `title` | One line, imperative or declarative. This is what gets scanned. |
| `body` | Markdown. The learning itself, and **why** — the failure that motivated it. |
| `resolution` | What actually fixed it. Required for `failure`, `null` otherwise. |
| `evidence.files` / `dirs` | Paths or globs this applies to. **This is what makes retrieval work — always fill it in if the learning is code-local.** |
| `evidence.branch` / `issues` | Branch name and `owner/repo#N` you were working on. |
| `evidence.run` | The `run.id` from `OTEL_RESOURCE_ATTRIBUTES`, if present in your env. Ties the learning back to the run that produced it. |
| `provenance.author` | `agent:claude-code` when you write it, `human:<name>` for hand-authored. |
| `provenance.backend` | `boxd` when running in a factory VM. |
| `status` | `active` on write. Never write `deprecated` directly — supersede instead (§6). |
| `confidence` | `high` if you verified it. `medium` if it worked once. `low` if you inferred it. Be honest; low-confidence records are filtered out first. |
| `hits` | `0` on write. Reserved for the future `mem` binary. |

### §3.1 Types

| Type | Meaning | `resolution`? |
|---|---|---|
| `convention` | "In this repo we do X this way" | no |
| `failure` | "X broke; here's why" | **yes** |
| `pattern` | Reusable approach or architecture note | no |
| `decision` | A choice made plus rationale (lightweight ADR) | no |
| `reference` | Pointer to an external doc, dashboard, or ticket | no |

## §4 Priming — read before you work

Do this at session start, before planning.

1. `ls .mem/` — if there is no `.mem/`, skip; there is nothing to prime.
2. Read `index.jsonl` first, whole. It is small by construction, and it is how you find out
   what exists without opening anything.
3. Always read `domains/_universal.jsonl`.
4. Read the domain files matching your working set. Match by the paths named in your task
   and by `git status`, against the index's `files` and each record's `evidence.files` /
   `evidence.dirs`.
5. When the task is small and the repo is small, just read everything under `domains/`.
6. Never prime from `archive/`. Those records were retired on purpose; reading them is how a
   belief the project abandoned comes back.

Then say in one line what you loaded — e.g. `memory: primed 6 records from database, ci` —
so the human can see what shaped your reasoning.

**A record is not an instruction.** It is what a past session believed. If it contradicts
what you observe in the code right now, the code wins — and that contradiction is itself
worth recording as a supersession (§6).

## §5 Recording — write before you finish

One learning is **two** appends: the full record, and its index line. A record with no index
line is invisible to the next session; an index line with no record is a broken store.

```bash
mkdir -p .mem/domains .mem/archive
printf '%s\n' '{"id":"mem_7a3f","domain":"database",...,"status":"active",...}' >> .mem/domains/database.jsonl
printf '%s\n' '{"id":"mem_7a3f","domain":"database","type":"convention","title":"...","files":["src/db/*.ts"]}' >> .mem/index.jsonl
```

Append, never rewrite an existing line. That matters for merges: two agents recording
concurrently append different lines, and git resolves that with the `merge=union` driver a
memory-carrying repo declares in `.gitattributes`, where rewriting a line conflicts outright.
Supersession (§6) is the one operation that moves a line, which is why it has its own section
and its own rules.

Be precise about what that driver buys, because a claim that it "just merges" cost a queue of
four issues a full stop. Two appends at the end of one file *do* conflict in plain git — the
union driver is what resolves them, and it only applies where the working tree and
`.gitattributes` are both present. That is every laptop and every CI runner, and it is **not**
GitHub's merge API, which does a three-way content merge with no working tree and reads no
attributes at all. So a pull request can merge cleanly under `git merge` and be refused by
GitHub as conflicted. Nothing you can do while writing prevents that; it is repaired at merge
time by whatever merges the branch.

**Record when:**
- You hit an error that cost real time, and you found the fix (`failure` + `resolution`)
- You discovered an unwritten convention by reading the code (`convention`)
- You made a non-obvious architectural choice (`decision`)
- You found a reusable approach worth repeating (`pattern`)

**Do not record:**
- What the README, CLAUDE.md, or the code already says plainly
- Anything specific to this one task with no future use
- Transcripts, narration, or "I did X then Y" — records are distilled knowledge, not logs
- Secrets, tokens, credentials, or customer data

Then check the store and commit it (§7).

## §6 When a learning turns out to be wrong

Nothing is deleted. The old record is **retired**, not erased, and the new one takes its place.
Three moves, and all three are needed — doing two of them leaves the store broken:

1. **Append the new record** to `domains/<domain>.jsonl` with `status: active` and `supersedes`
   set to the old record's `id`.
2. **Move the old record's line** out of `domains/<domain>.jsonl` and into
   `archive/<domain>.jsonl`, with `status` changed to `superseded`.
3. **Update `index.jsonl`**: append the new id's line, remove the old id's line.

The direction is the part that is easy to get backwards, so state it plainly: **`archive/` is
for the record you just stopped believing, never for the one that just became current.** A
supersession that files the *new* record in `archive/` leaves the index pointing at nothing,
which is precisely what a validator reports as `index entry 'mem_xxxx' has no matching active
record in domains/`.

The history is the value — it shows what the project believed and when it stopped believing it.
`archive/` and git together keep the trail.

## §7 Check your work

You have just hand-edited two or three files to keep four facts in agreement. Do not assume you
got it right — the mistakes here are silent, and the next session pays for them.

If the repo has a memory validator, run it before you finish. In this factory's own repo that
is one of the gates CI merges on:

```bash
python -m control.memory validate .
```

Elsewhere, check by hand: every id in `index.jsonl` has an `active` record in `domains/`, every
index title matches its record's title exactly, and nothing `active` is sitting in `archive/`.

Then commit `.mem/` along with your code changes, so the learning ships in the pull request and
gets reviewed like any other diff.

## §8 Boundaries

Memory holds **learnings**. It is not an issue tracker, not a prompt library, not a chat
log. If it is a task, it belongs in GitHub. If it is a transcript, it belongs in telemetry.

This skill contains no model and makes no decisions. You decide what is worth remembering;
this file only tells you where to put it.
