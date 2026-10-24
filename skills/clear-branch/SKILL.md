---
name: clear-branch
description: Clean up after a PR merges. Confirm the work actually landed, then remove the worktree, prune, and delete the local branch. Use when a PR merges, when stale branches pile up, when a branch reads `gone`, or when a stacked PR's parent has merged.
---

# Clearing a landed branch

`CONFIRM → WORKTREE → PRUNE → DELETE`. The mirror of
[open-branch](../open-branch/SKILL.md).

CONFIRM comes first because the other three cannot be undone from the local
repository. This skill ends at the checkout; reading the reviewer comments on the
merged PR is the rest of
[After the merge](../adversarial-review/SKILL.md#after-the-merge).

## CONFIRM the work landed

**A branch reading `gone` means the remote branch was deleted.** A merge does
that, and so does a closed or abandoned PR. Ask the PR:

```bash
gh pr view <n> --json mergedAt,headRefOid,mergeCommit,baseRefName
```

- A non-null `mergedAt` says it merged **into `baseRefName`**. That is landing
  only when `baseRefName` is the default branch. A PR merged into another branch
  (a stacked parent's) has landed only once that branch's own PR merged to the
  default branch afterwards; confirm that PR too, or treat the work as not
  landed.
- **Compare `headRefOid` with the local tip** (`git rev-parse <branch>`). A match
  proves nothing was committed locally after the merge. Otherwise fetch the PR
  head (`git fetch origin pull/<n>/head`) and run
  `git merge-base --is-ancestor <branch> <headRefOid>`. Success means the local
  branch is only behind, with commits added on GitHub ("Update branch", a
  committed suggestion), and nothing is lost. Failure means local commits the PR
  never had, which the delete would take with it.
- Read CI's run on the base for `mergeCommit.oid` once it finishes
  (`gh run list --commit <oid> --event push`). Two green PRs can break each other
  once both have merged, and a red run there blocks nothing and pages no one.

Without a PR number, compare content. Run `git fetch` first, so `origin/main`
is current, then take the first field of
`git diff "$(git merge-base origin/main <branch>)" <branch> | git patch-id --stable`
and look for it among the first fields of `git show <commit> | git patch-id
--stable` for the commits on `origin/main` since the merge-base. A match is
strong evidence. A miss is weak evidence of anything, since a squash that
resolved a conflict carries a different diff; treat it as a question for
someone, never as permission.

**What git cannot tell you.** A squash or rebase merge rewrites the commits
`git branch -d` looks for, so it refuses a branch that did land, and
`git branch --merged` leaves it out. Neither is evidence the work is missing.
Confirm from the PR, then delete with `git branch -D`.

## WORKTREE, before the branch

`git branch -D` refuses a branch checked out in any worktree, so remove the
worktree first, **from outside it**: `git worktree remove` will remove the one you
stand in and leave you in a directory that no longer exists.

First tear down what the worktree started for itself: its test database, a
server on its own ports ([open-branch](../open-branch/SKILL.md), INSTALL). If a
service it holds is serving anyone else, it is shared: report it rather than
stopping it. Then:

```bash
git -C <worktree> status --short
git -C <worktree> stash list
git worktree remove <worktree>
```

`git worktree remove` refuses on modified or untracked files, but ignored state
such as `.venv`, `.env` and build output does not trigger it. So a refusal means
real work: go and look rather than reaching for `--force`.

## PRUNE, between the two

```bash
git fetch --prune
```

The prune is what makes `git branch -vv` show `[origin/<branch>: gone]`, and it
clears each branch's stale tracking ref before anything measures against it.

## DELETE

```bash
git branch -D <branch>
```

For a batch of stale branches, list the candidates with `git branch -vv`, then
confirm each separately and record the evidence, because "they all read `gone`"
is the reasoning this skill exists to prevent:

| Branch | PR | Merged into the default branch | Local tip vs `headRefOid` |
| --- | --- | --- | --- |
| `fix/…` | #… | yes | exact match, or ancestor of the PR head |

A branch that fails any check stays, and gets reported.

## A PR stacked on the merged one

After a squash or rebase merge, a stacked child still carries the parent's
original commits, so GitHub shows them beside its own and may report conflicts.
It needs a rebase, not a merge, and possibly a new base: GitHub retargets the
child to the parent's base only when the parent's head branch is deleted;
otherwise the child still targets the parent's branch.

**First check the child is yours** (`gh pr view <child> --json author`). Both
push guards below are about your view of the remote being current, not about the
branch being yours, so they let you overwrite someone else's branch. A child that
is not yours gets reported, not rebased. When sessions share one account, the
author check is conclusive only when it says no.

Then, in a worktree of its own, replay only the child's commits onto the
parent's base (`<base>`, the parent's `baseRefName`, usually `main`). Start every
command with `cd <child-worktree> &&`: a shell tool that resets the working
directory would otherwise test and push from the shared checkout, which can push
another session's branch
([open-branch](../open-branch/SKILL.md#install-the-untracked-state)).

```bash
cd <child-worktree> && git rebase --onto origin/<base> <parent-head-sha> <child-branch>
cd <child-worktree> && <the suites the child touches>
cd <child-worktree> && git push --force-with-lease --force-if-includes
```

Take `<parent-head-sha>` from
`gh api repos/{owner}/{repo}/pulls/<parent> --jq .head.sha`. After the push,
check the child's base (`gh pr view <child> --json baseRefName`). If it still
names the parent's branch, retarget it (`gh pr edit <child> --base <base>`), or
it can merge into a branch that never reaches the default branch.

**Use both guards.** `--force-with-lease` alone is satisfied by any fetch that
updated the tracking ref, including the prune above or another session's fetch
that collected someone else's commit. `--force-if-includes` also requires the
remote tip to be in the local branch's reflog.

**A rejection is not always someone else's push.** `(stale info)` comes from the
lease: the remote moved since your last fetch. `(remote ref updated since
checkout)` comes from `--force-if-includes`: the remote tip is not one this
branch has held, which a fresh clone or a reflog expired by `gc` also produces.
Settle which it is by running `git fetch` first (a rejected push does not
refresh the tracking ref, so without it the check below matches exactly when
someone else pushed), then comparing `git rev-parse origin/<child-branch>` with
your pre-rebase tip in `git reflog show <child-branch>`. A mismatch means
someone else pushed: report the branch rather than following git's hint to
`git pull`, which merges the parent's original commits back in beside the
replayed ones.

## Without `gh`

A session without `gh` asks the PR questions through the GitHub MCP server
(`pull_request_read`). The `git` commands need no substitute.
