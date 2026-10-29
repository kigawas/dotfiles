---
name: author-loop
description: Work your own queue unattended on a recurring trigger. Arm a standing prompt, triage each firing most-finished first, keep a state record, and pause cleanly. Use when asked to work autonomously for hours, to watch your own PRs through to merge, to pause or resume such a loop, or when a recurring prompt keeps redoing finished work.
---

# Working your own queue on a trigger

The repository's `AGENTS.md` says what to do with an issue, and what round
budget autonomous work gets. This skill says what to do with *time*: a session
that keeps going for hours, across other people's merges, where what goes wrong
gathers between the firings rather than inside one.

The queue is **yours**: issues you are driving and pull requests you opened.
Reviewing other people's open PRs on a schedule is
[review-loop](../review-loop/SKILL.md). Doing both takes two standing prompts.

`ARM → TRIAGE → WORK → REPORT`, and `PAUSE` when told to stop. ARM happens
once; each firing runs TRIAGE through REPORT. How each runtime arms, lists and
deletes a trigger, and where it can keep the state record, is in
[triggers.md](triggers.md).

## ARM: the standing prompt

The prompt fires into a turn that has none of the reasoning that produced it.
So it carries its own instructions, or names this skill in plain words, which
every runtime that loads the skill follows (triggers.md says where a run loads
it). Four properties are load-bearing:

- **Idempotent.** Most firings have nothing to do. A prompt that says what to
  check, in order, stops at the first "no"; one that says "continue the work"
  re-reads everything to find that out.
- **Delta-only reporting.** Put *report only what changed since the last
  firing* in the prompt. The blocked table is the one exception, carried whole
  every time (REPORT).
- **An explicit precedence order:** TRIAGE below. Without one, a firing starts
  a new issue while an approved PR sits unrebased behind a merge.
- **A state record, named in the prompt.** The transcript is not the record: it
  is compacted in place over hours, and a summary keeps conclusions, not the
  blocked table. The queue, each PR's next step and the blocked table live in
  one record the next firing can read, and the prompt says where.

A prompt with all four:

```
Run one firing of the author-loop skill on <owner>/<repo>. Read the state
record at <where> first, and update it before reporting. Report only what
changed since the last firing, then the blocked table in full; if nothing
changed, say so in one line.
```

Add what the repository needs every firing, such as how each runner isolates
its test environment. Write it into the prompt itself: a firing reads the
prompt, not this session.

**Cadence: hourly, off the hour** (`7 * * * *`). A review round takes half an
hour or more, so a shorter cadence lands a firing on a tree still being graded.
If asked for another interval, round it to one that divides the hour
(`7,37 * * * *` for half-hourly) and say so: `*/45` fires at `:00` and `:45`, a
45-minute gap and then a 15-minute one.

**Renewing.** *"Renew the trigger"* means *make sure exactly one exists*. List
the triggers before creating one. Two triggers carrying the same prompt double
every firing, and the transcript never shows it. A trigger that expires (both
local runtimes expire recurring jobs after 7 days) is re-armed deliberately,
and the re-arm goes in the state record.

## PAUSE: stopping at a good place

*"Stop at a good place"* is an instruction to the loop, not to the firing in
progress. A good place is a tree that is pushed, or uncommitted work named in
the state record together with the worktree holding it. It is never a rebase
half replayed, or a fix committed but not pushed. Then, in this order:

1. **Delete or disable the trigger**, listing first. A firing after the pause
   acts on a queue the pause says is frozen.
2. **Bring the state record up to date:**
   - per PR, its commit, the round it reached, the verdict and the exact next
     step;
   - the queue in landing order;
   - the blocked table;
   - every long-lived process the loop started (a dev server, a database), with
     its ports, its worktree and how to stop it;
   - the re-arm prompt, verbatim, so resuming is one command.
3. **Say where the record is**, somewhere the next reader will look: a status
   comment on the tracking issue for a person, and whatever the runtime keeps
   across sessions for an agent.

A verdict from a round in flight at the pause arrives afterwards. Record it, in
the state record and in the PR body, and act on none of it. The pause is the
person's decision that nothing more moves.

## TRIAGE: most-finished first

1. **A PR that merged** →
   [After the merge](../adversarial-review/SKILL.md#after-the-merge). It frees
   the branch and exposes the rebases the rest of the firing depends on.
2. **Your own PR stacked on the one that merged** → rebase it now, per
   [clear-branch](../clear-branch/SKILL.md#a-pr-stacked-on-the-merged-one).
   Settle the parent first, so the child is rebased once. The rebase ends in a
   force-push, so the author test in that section decides whether this step
   runs at all. The firing's own record of what it opened is the best evidence.
3. **A review that landed on an open PR** →
   [READ → VERIFY → FIX → ANSWER](../adversarial-review/SKILL.md#when-a-review-lands-on-an-open-pr).
4. **Nothing above** → the next queue item, under WORK.

**Know when CI runs.** The workflow's triggers decide it, and a common one runs
only on pull requests against `main`. Then a PR stacked on another branch has no
checks until it targets `main` and is pushed again. Report such a PR as
untested, never as passing, and run the gates locally before pushing it. Read
checks by the head commit, never by branch, which counts every run the branch
has ever had:

```bash
( sha=$(gh pr view <n> --json headRefOid --jq .headRefOid)
  [ -n "$sha" ] || { echo "no head sha; gh failed" >&2; exit 1; }
  gh api --paginate "repos/{owner}/{repo}/actions/runs?head_sha=$sha&per_page=100" \
    --jq '.workflow_runs[] | [.name, .event, .conclusion] | @tsv' )
```

The API ignores an empty `head_sha` and returns every run the repository has,
hence the guard; the parentheses keep its `exit` in a subshell. Take
`.conclusion` with `.event`: a failed run prints the same event a passing one
does. This lists GitHub Actions runs only; CI that reports commit statuses shows
in `gh pr checks <n>`.

**Dispatching a workflow by hand is a person's decision.** A manual run can
select different tests from a pull request's run, including ones that reach live
services, and it does not attach to the PR as a check.

## WORK, and what a firing may not decide

One issue or bundle at a time: [writing-tests](../writing-tests/SKILL.md), then the
[adversarial review](../adversarial-review/SKILL.md), at the round budget
`AGENTS.md` sets for autonomous work. The loop adds these rules.

- **A reviewer's FILE THIS is a claim, and filing it is acting on it.** The loop
  reads its own issue queue as input, so an unverified issue comes back firings
  later as work built on an unchecked premise. Verify the general form at
  source, against `origin/main` rather than a tree the loop has let drift,
  before filing.
- **Read an issue's comments before asking anything on it or parking it**
  (`gh issue view <n> --comments`). The body is the filing; the answer often
  arrives only in the thread.
- **Look for the option the issue did not list** before parking it on a choice.
  A parked issue costs a whole firing cycle to unpark.
- **Skipped issues go in the blocked table**: the issue, one sentence of what
  it needs, and who has to answer. Carry it forward unchanged until an answer
  arrives.
- **An engineering question can still be the user's to answer.** The
  repository's `AGENTS.md` and ADRs say which calls are, such as what money
  does or who may see what. A firing that proceeds on an assumption pins the
  guess with a test, and the test then certifies it. Park it instead.

## REPORT: the delta and the blocked table

Say what changed, what is in flight, and what is blocked on whom. A firing with
nothing to report says so in one line. The blocked table is the loop's only
channel back to the person who can unblock it, and an item that drops out of it
silently stops existing.

Update the state record first and report from it, never the other way round: a
report written from memory, with the record updated afterwards if at all, is how
a PR's next step goes missing between two firings.

## Traps

- **Nobody stands between the rounds.** The only reader is the reviewer, and it
  grades the diff; the explaining prose around the diff goes unread. Before
  writing "X refuses Y" or "nothing else covers this", mutate the source and
  watch a test go red, or probe the behaviour directly. If neither is possible,
  write the smaller sentence.
- **A passing check may be vacuous.** A missing service turns a suite into
  skips, and skips exit 0. A port probe run from the wrong shell always says
  "free" (bash's `/dev/tcp` does not exist in zsh). An assertion that a thing is
  absent holds wherever the fixture never set it up. Ask what the check could
  have observed before reading a green result as evidence.
- **A stored baseline goes off.** Over hours, other sessions land tests, so the
  suite one firing measured is not the one the next firing runs. Attribute a
  failure against a clean tree at the same base, built now, never against a
  count or a list of failures saved earlier.
- **An interrupted mutation battery leaves the mutation in the tree.** Follow
  [the battery rules](../review-loop/mutants.md#when-a-battery-is-interrupted).
- **A `gh` body written inline runs its own backticks** as command
  substitution, exits 0 and prints a URL. Write the body to a file with a
  quoted heredoc (`<<'EOF'`) and pass `--body-file` or `-F body=@file`.
- **A closing keyword can reach `main` three ways:** the branch's commit
  messages, the PR title (it becomes the squash subject) and the PR body. After
  every push or edit, run both of these:

  ```bash
  base=$(gh pr view <n> --json baseRefName --jq .baseRefName)
  { gh pr view <n> --json title --jq .title; git log --format=%B "origin/$base..HEAD"; } \
    | grep -inwE '(close[sd]?|fix(es|ed)?|resolve[sd]?):?[[:space:]]+(([-[:alnum:]._]+/[-[:alnum:]._]+)?#|GH-|https://github\.com/[-[:alnum:]._]+/[-[:alnum:]._]+/issues/)[0-9]+'
  gh pr view <n> --json closingIssuesReferences --jq '[.closingIssuesReferences[].number]'
  ```

  The first prints each line of the title and the branch's own commits that puts
  a keyword before a reference; the range starts at the PR's base, since a
  stacked branch's log from `main` includes its parent's commits. The second is
  GitHub's reading of the body: compare it with the issues the PR should close.
- **A pipe hides the status the chain was keyed on.** `make check | tail -1 &&
  git push` pushes whatever `make check` said, since `tail` succeeds. Run the
  gate as its own command and read its status, and keep the push out of the
  chain that decides it.
- **The checkout moves under you.** Read the branch and commit in one command,
  cut a worktree rather than switching ([open-branch](../open-branch/SKILL.md)),
  and never move a tree a reviewer is reading.
- **One test environment per runner.** Concurrent suites against one database or
  service share its load and its state, so one runner's load fails another's
  timing tests. Give each runner its own, as the repository's `AGENTS.md`
  describes, including each reviewer you spawn, and **repeat that instruction in
  every reviewer prompt**: a subagent inherits none of this.
- **Autonomy is over the queue, not the machine.** A branch, worktree, process
  or session another session left behind is reported, never deleted on the
  loop's own authority.
