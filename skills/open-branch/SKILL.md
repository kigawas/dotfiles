---
name: open-branch
description: Start a change. Fetch the real base, cut a worktree rather than switching a shared checkout, install the untracked state a worktree lacks, and prove the tree runs before the first edit. Use when beginning any change, when a fresh worktree will not build its environment, or when it fails tests in bulk.
---

# Opening a branch

`FETCH → CUT → INSTALL → PROVE`. The mirror of
[clear-branch](../clear-branch/SKILL.md).

PROVE is the step that pays. A worktree starts with none of the untracked state a
run needs, and the failures that causes arrive in bulk and blame the wrong thing:
hundreds of red tests because static files were never built read as a broken
branch. Once the tree is shown to run, every failure after that is yours.

The repository's `AGENTS.md` (or `CLAUDE.md`) names its install and test
commands. This skill says what those commands have to achieve in a fresh
worktree, and the traps between them.

## FETCH the base

```bash
git fetch origin
```

Fetch with the configured refspec, so every `origin/*` ref moves. Naming one
branch moves only that one, and a branch cut from a stale ref starts behind
without saying so. Leave `--prune` to [clear-branch](../clear-branch/SKILL.md);
it does nothing for the freshness of the base.

## CUT a worktree

```bash
git worktree add -b <branch> <path> origin/main
```

- **Branch from `origin/main`**, or the default branch
  (`git symbolic-ref --short refs/remotes/origin/HEAD`), not the local `main`,
  which is wherever the last session left it.
- **Cut a worktree rather than switching a checkout.** Other sessions may be
  working in the shared checkout, and a switch moves the tree under all of them.
  `git worktree list` shows who stands where.
- **Keep `<path>` outside the repository**, or under a directory git ignores.
- **Until the first `git push -u`, the upstream is `origin/main`.** So
  `git status -sb` counts against the base: "behind" means the base moved under
  you. After the push it counts against `origin/<branch>`, and that signal is
  gone.
- **For a change stacked on an open PR**, cut from that PR's branch
  (`origin/<parent-branch>`) and target it as the PR base.
  [clear-branch](../clear-branch/SKILL.md#a-pr-stacked-on-the-merged-one) covers
  the rebase once the parent merges.

## INSTALL the untracked state

Run the repository's setup inside the worktree. Whatever the commands, they have
to cover:

- **The environment, from the lock.** Install the committed lock without moving
  it: `UV_FROZEN=1 uv sync`, `npm ci`, `pnpm install --frozen-lockfile`. A bare
  `uv sync` or `uv run` re-resolves when the manifest is ahead of the lock and
  rewrites the lock without saying so. The exceptions are the commands meant to
  move the lock (`uv add`, `uv lock`, `npm install <pkg>`): frozen, `uv add`
  edits the manifest and leaves the lock behind.
- **Local config, from the example.** Seed `.env` from the committed
  `.env.example`, not from the main checkout's `.env`. The main checkout's file may hold
  real credentials, or a database URL that points both checkouts at one database,
  where a migrate in the worktree migrates the other one's. Guard the copy
  (`test -f .env || cp .env.example .env`): run from the wrong directory, an
  unguarded copy overwrites an untracked file nothing can restore. Placeholder
  values make a fresh worktree weaker than CI wherever CI injects real secrets,
  so a test failing on one of those is no evidence CI would fail.
- **Build output** the tests read: collected static files, generated code,
  compiled assets.
- **Shared services, per worktree.** Tests that use a database, cache or server
  on a fixed port collide when two worktrees run at once. Give this worktree its
  own (a database named after the branch, free ports), and note it:
  [clear-branch](../clear-branch/SKILL.md) tears it down.

**Each command stands alone.** An agent's shell tool can start a fresh shell per
call, so an `export` does not reach the next command, and in some tools the
working directory resets too. Put variables inline and the directory in front:
`cd <path> && UV_FROZEN=1 uv run pytest …`. Otherwise the command runs in the
main checkout, which is already set up, and passes for the wrong tree.

**A fresh worktree can resolve a different toolchain** than the main checkout
from the same lock: another interpreter build, another Node. The error then names
the wrong cause, such as "no wheel for this platform". Pin the main checkout's
interpreter by path, in one command that stops when the path is empty (an empty
`--python ""` is silently ignored, which brings back the discovery the pin
overrides):

```bash
cd <path> &&
MAIN=$(git worktree list --porcelain | awk '/^worktree /{sub(/^worktree /, ""); print; exit}') &&
P=$(readlink -f "$MAIN/.venv/bin/python") && [ -n "$P" ] &&
UV_FROZEN=1 uv sync --python "$P"
```

## PROVE before the first edit

Run a small, fast selection that exercises every piece INSTALL set up: an import
of the environment, a value from `.env`, a test that reads the build output or
talks to the service. Then the full suite if it is quick.

**Read the count, not the colour.** A mostly green run is the normal look of a
half-installed tree, and skipped tests pass silently: a test that needs the
service skips when it is absent. Expect every test in the selection to pass and
none to skip.

Anything red here belongs to the setup. Everything red after this is yours.
