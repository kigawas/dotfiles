---
name: review-loop
description: Review every open PR in a repository on a recurring trigger, as an independent third party. Each firing gives new PRs a full review, re-reviews any PR whose head or base moved since its verdict, and checks what merged. Use when asked to watch a repository's PRs, to review the open-PR queue on a schedule, or to keep up with a review backlog rather than one named PR.
---

# Reviewing the open PRs on a trigger

This is the *outer* loop: which PRs, how often, and what to do with each
verdict. It delegates the rest:

- [open-branch](../open-branch/SKILL.md) for the worktree, which here is
  detached at the PR's head.
- [REVIEWER.md](../adversarial-review/REVIEWER.md) for the method. The
  [adversarial-review](../adversarial-review/SKILL.md) loop is for your **own**
  diff over several rounds. This skill reviews **someone else's** open PR, one
  round per push, reproduced independently, ending in a real GitHub review.
- [author-loop](../author-loop/SKILL.md) for working unattended on a trigger at
  all: cadence, renewing, pausing, the state record and its traps. Everything
  there applies here, and its [triggers.md](../author-loop/triggers.md) maps
  each runtime. That skill's queue is your own work; this one never authors
  anything.

Reached from here when the case arises:

- [re-review.md](re-review.md): a PR you reviewed moved, by a push, a rebase, a
  parent's merge or its base advancing.
- [after-merge.md](after-merge.md): a PR merged since the last firing.
- [mutants.md](mutants.md): the mutant battery each PR keeps.
- [shared-identity.md](shared-identity.md): a person also reviews under the
  routine's GitHub identity. Read it before the first firing; its guard then
  runs first on every PR.

## The standing prompt

One trigger, hourly and off the hour (`7 * * * *`). The prompt is a **standing
instruction**: each firing finds the work fresh from the open-PR list, so the
prompt names no PR numbers.

```
Run one firing of the review-loop skill on <owner>/<repo>, reviewing as
<identity>. Read the state record at <where> first, and update it before
reporting. Each runner gets its own test environment: <how>. If nothing needs
attention, post nothing to GitHub and end with one line saying so.
```

**Silence on GitHub is a feature.** A firing that finds nothing posts nothing
there, beyond the state record's own upkeep.

## Verdicts, and what an approval does

**Every verdict is explicit.**
- **APPROVE** only after the full method finds nothing blocking, or a check in
  re-review.md carries an earlier approval over, and only pinned to the head
  that was reviewed. The body says what you verified and how, not the PR's
  claims restated, and lists any non-blocking lows.
- **REQUEST_CHANGES**, with inline comments, for any substantiated blocking
  finding: a bug, a failing test, red CI, a false claim.
- **Never a bare COMMENT as the verdict**: it leaves the author guessing.
- **Post nothing** for a PR you have not approved whose head conflicts with its
  base, or that is waiting for a rebase (re-review.md). Record it as waiting,
  with its head and merge-base, and take it up again once either moves.

**Know what your APPROVE does here.** Before the first firing, read the base
branch's rulesets (`gh api repos/{owner}/{repo}/rules/branches/<base>`) and any
classic branch protection (`…/branches/<base>/protection`, which needs admin
rights to read; the repository's `AGENTS.md` may say instead).
If one approval clears a PR to merge, the routine's APPROVE alone is the gate,
which is why the method before it is not optional. Two settings decide how much
re-reviewing that takes:
- **Whether a push dismisses approvals.** Even where it does, it never dismisses
  an approval posted after the push, so every approval names the commit it
  covers and goes out only while that commit is the head. Where it does not, an
  APPROVE keeps clearing every later push until the routine takes it back: tell
  a person before the first firing, and withdraw the approval as soon as a
  firing finds its head or merge-base moved (re-review.md).
- **Whether a PR must be up to date with its base to merge.** Where it need not,
  a PR approved against an older base can merge onto a newer one that no gate
  ran against, so an approved PR is checked again whenever its base advances
  (re-review.md).

**The routine never merges.** Approve only what you would merge yourself.

**The routine's identity is not the PRs' author.** GitHub refuses APPROVE and
REQUEST_CHANGES on your own pull request, so give the routine an identity of its
own. On a PR that identity authored, the verdict is a COMMENT whose body opens
with `Verdict: sound` or `Verdict: changes needed` and says why it is not a real
review. `Verdict: sound` needs every check an APPROVE does. A cloud scheduled
task acts as your own GitHub user ([triggers.md](../author-loop/triggers.md)),
so there the identity is shared unless the run gets a token of its own.

## The state record

The session is not the record, even for a trigger that fires back into the same
session: its context gets compacted. Keep the record where
[triggers.md](../author-loop/triggers.md) says the runtime can, and update it
before each report. It holds:

- **per PR:** the id of your latest verdict review on it, a withdrawal included
  (a thread reply is not one); the head, merge-base and verdict
  of your last posted verdict, as full 40-character SHAs; the head and
  merge-base of a review in progress; the reproduction behind each open finding;
  any hold or waiting mark, with its head and merge-base and the firing it
  started; any unwithdrawn approval; for an approved PR, the base tip it was
  last checked against; a parent's open finding it relies on, with the parent's
  head at the time (re-review.md); and the review that holds its mutant battery,
  or the entries themselves until a review posts them (mutants.md);
- **other reviewers' claims you have read:** each one's id, its `updated_at` or
  body hash, and its disposition, and for each claim still open, the firing it
  opened;
- **merges:** which ones you handled, any with a check still outstanding, and
  when this firing listed them (after-merge.md);
- **reports owed to a person:** a stuck hold, a claim open three firings, an
  unwithdrawn approval.

The head, merge-base and verdict change only when a verdict is posted; a
withdrawal ([Posting the review](#posting-the-review)) changes only the review
id and the verdict. A firing that ends before posting leaves the PR looking
unreviewed to the next one. A PR missing
from the record never gets a verdict carried over from memory: it gets the full
method.

## Each firing

1. **List open PRs** and take them oldest first, each stack from its bottom up:
   a parent's verdict bears on every PR stacked on it. For a PR you reviewed,
   recompute the merge-base before trusting an unchanged head. A PR stacked on
   one that has since merged shows a different diff with its own head untouched.
2. **Under a shared identity only**, the guard on every open PR, before anything
   else ([shared-identity.md](shared-identity.md)).
3. **Unwithdrawn approvals** → retry the withdrawal
   ([Posting the review](#posting-the-review), step 5).
4. **Held PRs** whose head and merge-base still match the hold → the APPROVE
   gate again, nothing else ([A held approval](#a-held-approval)).
   Steps 5 and 6 skip them. A hold that no longer matches is gone: take the PR
   as a moved one.
5. **New PRs**, and entries with no recorded head → [Reviewing one
   PR](#reviewing-one-pr). Skip a PR waiting at its current head and merge-base.
6. **Moved PRs** → [re-review.md](re-review.md): a head or merge-base that moved,
   a parent that moved under a child relying on its fix, and an approved PR
   whose base advanced.
7. **Merged since the last firing** → [after-merge.md](after-merge.md).
8. **Clean up** ([below](#cleanup-every-firing)), whether or not anything
   happened.

## Reviewing one PR

### Diff against the true merge-base

A PR's recorded base is a live pointer. GitHub retargets a stacked PR when its
parent merges, and after a squash or rebase merge the parent's commits are
never ancestors of `main`. Compute the merge-base every time.

Take the head once, from the PR, and use that one SHA for everything after: the
diff you read, the worktree you test, the state record and the review's
`commit_id`. A branch ref moves whenever anything fetches.

```bash
HEAD_SHA=$(gh pr view <n> --json headRefOid --jq .headRefOid)
git fetch origin <base-branch> "$HEAD_SHA" --quiet
BASE=$(git merge-base origin/<base-branch> "$HEAD_SHA")
git diff --stat "$BASE" "$HEAD_SHA"
```

**Write both SHAs down the moment you have them**, in an in-progress field of
the state record, never in its last-reviewed fields. Shell variables do not
outlive the tool call that set them, so every later `$HEAD_SHA` and `$BASE` here
means those written-down values. Never run `gh pr view` again to get the head
back: it returns whatever the head is by then. Later reads of it compare.

**The stat line must match the PR's own additions and deletions**, which GitHub
computes against the same merge-base. If they disagree, find out why (a
force-push, the wrong branch fetched) before trusting the diff.

### The worktree

[open-branch](../open-branch/SKILL.md): FETCH, then
`git worktree add --detach <path> "$HEAD_SHA"`, then INSTALL and PROVE. Give the
review **its own test environment** (database, ports, services), as the
repository's `AGENTS.md` describes, never one another runner uses.

A test that fails under load and passes alone is still a failure until the base
shows otherwise. Run the same selection under the same load, a few times, at the
head and in a worktree at the base
([REVIEWER.md](../adversarial-review/REVIEWER.md), method step 6). If it fails
at the base too, and the diff leaves both the test and the code it exercises
alone, it is not the diff's: name it in the body, and file it after a search for
duplicates. Anything else is a finding.

### Directly, or through a background reviewer

A small diff with one clear property is faster to review directly. A
substantial diff, above all one on the paths the repository's review notes rank
highest, is worth a fresh `adversarial-reviewer` in the background (never a
fork), briefed per
[the prompt shape](../adversarial-review/SKILL.md#prompt-shape). The brief
includes the merge-base and head SHAs, the intent, the blast radius, a ranked
attack list and **its own test environment**.

The reviewer's job ends at a verdict. Posting to GitHub is always the
dispatching session's step, taken after the rule below.

### Never post a review on a claim you have not reproduced

This is the rule the skill exists to enforce. It applies whether the claim comes
from the PR body, a commit message, a background reviewer's `SHIP`, or your own
last verdict on the same PR. The only exceptions are the carry-overs in
re-review.md.

Take the one or two most load-bearing claims and **mutate the real code to make
each false**: drop the guard, swap source and destination, send the request
without its key. Run the test that should catch it, and confirm it fails for the
stated reason. Keep each mutant as an entry in the PR's battery
([mutants.md](mutants.md)), restore, then run the gates. A claim no test in the
tree can reach goes in the review as unverified, naming what the author must
measure.

**Your own probe is a claim too.** A glob one segment short, or a fixture the
test never loads, reads exactly like a defect. Before posting a finding from a
probe, run the probe against a case where you know the answer, or make the
finding fail a test in the suite.

**Hunt for flaky tests.** A test that sleeps a fixed time for another task to
reach a state is a race: it passes on your machine and fails on a loaded runner.
Ask for a wait on the state itself, with a deadline. Run every new concurrency
test several times in your own environment:

```bash
( for i in $(seq 10); do <test-command> || { echo "failed on run $i"; exit 1; }; done )
```

Keep the `exit 1`: a loop that only `break`s ends with status 0, green on the
very failure it was hunting. The parentheses keep that `exit` in a subshell.

**A claim that a change touches only comments or docs is checked, not read.**
Each changed file passes only if its parsed form is unchanged once comments and
docstrings are dropped: for Python, compare the `ast.dump` of each commit's
version (`git show <commit>:<path>`), with docstrings removed, using the
project's own interpreter. A file with no such check, or one the change adds,
deletes or renames, is read in full. A comment can still change what a gate
checks, so name any suppression the change adds (`# type: ignore`, `# noqa`,
`// eslint-disable`).

### The APPROVE gate

Every APPROVE passes this gate first, whichever path leads to it: a first
review, a hold's release, a carry-over or a re-review (re-review.md). It has
three parts: the claims, the checks and the base. A part that fails gets
REQUEST_CHANGES. One still open or pending, or a read that fails, holds the
approval ([A held approval](#a-held-approval)).

#### Claims: what other reviewers said

A finding posted as a COMMENT, a thread comment or a conversation comment blocks
nothing, so an APPROVE could pass over a finding the routine never read. Read the
PR's three streams, every page:

```bash
( for s in pulls/<n>/reviews pulls/<n>/comments issues/<n>/comments; do
    echo "## $s"
    gh api --paginate "repos/{owner}/{repo}/$s?per_page=100" \
      --jq '.[] | [.id, (.updated_at // "-"), .user.login] | @tsv' || exit 1
  done ) || echo READ-FAILED
```

A failed call prints GitHub's error JSON and exits non-zero, so without the
`exit 1` a rate limit reads as nothing new. Match `READ-FAILED` as a substring.

Read everything on a first review. After that, read every claim still open, and
what is new: any id the record has not read, and any that changed, since an edit
keeps its id. A comment carries `updated_at`; a review carries none, though its
body can be edited, so compare a hash of its body:

```bash
( set -o pipefail
  h=$(gh api "repos/{owner}/{repo}/pulls/<n>/reviews/<id>" --jq '.body // ""' |
    shasum -a 256) && echo "${h%% *}" ) || echo READ-FAILED
```

Take every hash this one way, from the body as GitHub returns it: any other
input gives a different digest, and every review would then read as edited.

Posts under the routine's own identity are its own, not claims, unless a person
also reviews under it ([shared-identity.md](shared-identity.md)). Reproduce or
refute each substantive claim in the rest:
- **One that stands** is a finding: REQUEST_CHANGES, naming it.
- **One the code refutes** gets one reply with the evidence, and holds nothing.
- **One that can be neither reproduced nor refuted from here** (what another
  repository's caller sends, say) stays open and holds the approval; a push does
  not settle it. It closes when its thread gives you
  something to reproduce or refute, or a person writes a disposition for it into
  the state record. Once it has been open three firings, report it, naming what
  would settle it.

#### Checks: CI on that same head

CI reports in two ways, and a repository may use either: check runs and commit
statuses.

```bash
( gh api --paginate "repos/{owner}/{repo}/commits/$HEAD_SHA/check-runs?per_page=100" \
    --jq '.check_runs[] | ["run", .name, .status, .conclusion] | @tsv' &&
  gh api --paginate "repos/{owner}/{repo}/commits/$HEAD_SHA/status?per_page=100" \
    --jq '.statuses[] | ["status", .context, .state] | @tsv' ) || echo READ-FAILED
```

A check run not `completed` with `success`, `neutral` or `skipped`, or a status
not `success`, fails the part if it failed, and is pending otherwise. Read the
statuses one by one, never the combined `state`, which reads `pending` when
there are no statuses at all.

**A run you expect but cannot see is not a pass.** Decide from the CI
configuration (the workflows' triggers, or an external CI's) whether CI runs for
this PR at all. Where it should, a missing run holds
the approval: a PR retargeted without a push has none until its next push, and a
push seconds old may have none yet. So does any check the base's rules require.
Where no CI runs for the PR, approve on your own run and say in the body that no
CI ran.

#### Base: the head merged with the current base

CI and your own run tested the head, not the head merged with today's base. Run
[the base check](re-review.md#a-base-that-moves-under-an-unchanged-head): the
head merged with the current base tip, and the gates and the battery on that
merge. A conflict means no APPROVE: on a PR you have not approved, record it as
waiting. Record the base tip you checked; a later pass of the gate repeats this
part only for a newer tip.

### A held approval

A hold is not a review. Leave the last-reviewed head and merge-base where they
were, so the next firing takes the PR up again, and record the hold with the
head and merge-base you tested and the firing it started. A hold renewed on the
same head and merge-base keeps its first firing.

On a later firing, while the head and merge-base still match, pass the APPROVE
gate again; the review itself stands. When it passes, post the verdict pinned to
the hold's head, as below. When a part fails, REQUEST_CHANGES. A hold that
outlasts three firings is stuck, as when a run will never start until someone
pushes: report it, naming the PR and what it waits on.

### Posting the review

Post through the API, never `gh pr review`, which takes no commit and so
reviews whatever the head is when the call lands:

```bash
gh api repos/{owner}/{repo}/pulls/<n>/reviews --input review.json
```

`review.json` holds `commit_id` (`$HEAD_SHA`), `event` (`APPROVE`,
`REQUEST_CHANGES`, or `COMMENT` on the routine's own PR), `body` and a
`comments` array of `{path, line, body}`, which may be empty.

A **withdrawal** takes an approval back without reviewing anything new: a
REQUEST_CHANGES pinned to the PR's current head, naming the approval and why it
no longer stands (a newer head, a claim open or unread, a retarget). It records
its id and sets the verdict to withdrawn, and leaves the last-reviewed head and
merge-base where they were, so the next firing still sees whatever moved.

1. **Just before posting**, read the PR's head again, and the three streams for
   anything new. If the head moved, post nothing: take the PR up as moved. A new
   claim is taken as above first, and one that stands or stays open means no
   APPROVE.
2. **Post, then record** the new review's id, head, merge-base and verdict in
   the state record, before anything else. A post that returns an error may
   still have landed. Under the routine's own identity, read its latest review
   on the PR before treating the post as failed, and record one whose commit and
   body match what you sent. Under a shared identity, leave it: the guard holds
   the PR out next firing.
3. **Read the head again.** If it moved after step 1 and you approved, the
   approval sits on a commit that is no longer the head: withdraw it at once.
   Then re-review the new head, in this firing if it can finish, or the next.
   Skip step 4: the re-review reads the streams on the new head.
4. **Read the three streams again.** A claim posted between step 1 and the post
   was never read. If you approved and a new claim stands, REQUEST_CHANGES
   naming it. If one stays open, or the read fails, withdraw the approval,
   naming what is open or unread, and record a hold on that head.
5. **A withdrawal that cannot be posted**, here or anywhere else, leaves an
   APPROVE standing over a head or a claim it never answered. Record it as an
   **unwithdrawn approval**, with the approval's head and what it never
   answered, and report it every firing. Each firing retries it first, naming
   what is unanswered then. It clears when a withdrawal posts, when a later
   verdict on the PR replaces the approval, when nothing is left unanswered, or
   when the PR merges or closes; a merge over it is
   [after-merge.md](after-merge.md)'s to report.

A real defect outside the diff becomes an issue: search first
(`gh issue list --search`), so two firings do not file it twice.

## Cleanup, every firing

Before the turn ends:
- restore any mutation from its backup and confirm with `git status --short`;
- stop or drop every test environment the firing started;
- `git worktree remove` each worktree;
- confirm with `git worktree list` that background reviewers cleaned up after
  themselves.

A routine that leaves environments and worktrees behind compounds across dozens
of firings.
