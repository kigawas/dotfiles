---
name: adversarial-review
description: Run a fix → adversarial-review → re-fix loop that converges. Use when handing a diff to the adversarial-reviewer, when a review lands on an open PR from a human or another AI tool, and after a PR merges, to triage its reviewer comments.
---

# Adversarial review loop

This skill is the loop *around* a review. What the reviewer does (method, attack
checklist, verdicts, output contract) is [REVIEWER.md](REVIEWER.md), shared by
every runtime. The reviewer you spawn has to be running that contract, or the
verdicts below do not mean what this skill says.

The repository's `AGENTS.md` (or `CLAUDE.md`) owns its policy: the gates to run,
whose word commits, pushes and opens a PR, and the round budget for autonomous
work. Where it is silent, use the defaults below.

## Goal

Land a tight, reviewed PR. The failure mode is a loop that never ends: each
round's findings widen the diff, and the next round grades the wider diff and
finds more. Severity falls each round while scope grows, so the loop converges
on quality and diverges on scope. Rebuilding from the first commit plus the
confirmed findings is what ships such work, and the rebuild can be large. Size is
never the problem. Scope discovered a round at a time is.

## The delivery workflow

`FIX → REVIEW-AND-FIX (two rounds) → PR`

1. **FIX**: implement at the size set by loop rule 1, in a worktree cut from a
   freshly fetched base, so the tree the reviewer reads stays put.
2. **Round 1**: spawn the reviewer fresh with the full [prompt shape](#prompt-shape).
   Verify each finding at source (rule 6). Fix only the confirmed, in-scope ones,
   each red first (rule 7); out-of-scope findings become issues (rule 3).
3. **Round 2**: a fresh spawn again. Say it is round 2 and what round 1 found,
   and tell it to re-derive from the code rather than grade the fixes. A `SHIP`,
   or findings that are precision only, ends the loop. Substantive findings with
   grown scope mean a rebuild (rule 8), not a round 3.
4. **PR**: run the repository's gates after the last edit, reading the pass
   count, then open the PR if `AGENTS.md` gives you that word. By default a loop
   that ended on anything but `SHIP` presents the diff and waits. Record a
   disposition in the PR body for any finding deliberately deferred.

Two rounds is the budget, not a target; a clean round 1 goes straight to PR.

**A batch of small fixes** earns one loop over the batch rather than one each. Fix
them all first, one commit per issue and test-first, with each commit touching
files of its own, test files included. Spawn one reviewer over the batch and ask
for a verdict per commit. Then cherry-pick each commit onto its own branch from
the base, one PR per issue. Seven issues looped separately cost up to twenty-one
rounds; as one batch they cost two. The trade is depth per change: fair for small
fixes, wrong for a refactor.

## When a review lands on an open PR

`READ → VERIFY → FIX → ANSWER`

1. **READ** all three streams: review bodies (`gh api
   repos/{owner}/{repo}/pulls/<n>/reviews`), thread comments (`…/pulls/<n>/comments`)
   and the conversation (`…/issues/<n>/comments`), every page (`gh api
   --paginate`): each defaults to 30 a page. A `CHANGES_REQUESTED` body often
   names what it is blocking on, while the substance, its `file:line` and a
   suggested fix sit in one inline thread. A nit riding on an approval is the
   least scrutinised finding of all; read it with the same care.
2. **VERIFY** at source (rule 6). A finding accepted wrongly here costs a commit,
   and that is the commit that ships. Two outcomes the rule does not name:
   - A fix can be right for a reason other than the one offered. Apply it, and
     put the reason that holds in the reply; the next reader inherits the reason.
   - A finding can name one line of a pattern. Find every occurrence before
     fixing anything. Fix it whole, or file it whole: a half-corrected claim
     leaves the tree disagreeing with itself.
3. **FIX** the confirmed findings, red first, then run the gates after the last
   edit. Fix what the finding names; a fix that grows a new mechanism, or reaches
   past the PR's stated blast radius, is a rebuild or an issue. The commit has not
   earned its own `SHIP`, so without the user's word, present the fix rather than
   pushing it.
4. **ANSWER** on the thread, not in the conversation:
   `gh api repos/{owner}/{repo}/pulls/<n>/comments/<comment_id>/replies -f body='…'`.
   An inline thread with nothing under it reads as a finding ignored. Then post
   one conversation comment for the round, saying what changed and **what did
   not**. A refused finding gets the same reply, carrying `file:line` evidence in
   place of a fix.

## After the merge

`CLEAN → READ-REVIEWER-COMMENT → DECIDE-NEXT-STEP`

1. **CLEAN**: once the PR shows merged, remove the worktree, prune, and delete
   the local branch, in that order. A branch that reads `gone` is a hint, not
   proof the work landed; confirm against the merged PR first.
2. **READ-REVIEWER-COMMENT**: reviews land after the merge too, from humans and
   other AI tools. Read all three streams above; `gh pr view <n> --comments`
   shows reviews and conversation, but not thread comments. When `gh` refuses on
   quota, `gh api repos/...` spends the REST bucket, which is separate from the
   GraphQL bucket the porcelain spends; `gh api -i` shows which bucket a call
   charged in `X-RateLimit-Resource`.
3. **DECIDE-NEXT-STEP**: give every comment a disposition before any code. A
   confirmed defect becomes an issue or a fix branch that re-enters the delivery
   workflow at FIX. A claim the code refutes gets a reply with the evidence. A
   preference gets noted, or nothing. A note too small for its own PR gets a
   reply saying where it will be folded in. When a follow-up lands, comment on
   the *merged* PR naming the fix, since that is the PR the reviewer reads.

## Loop rules

1. **Establish the real size before round 1.** Expect the issue to be wrong about
   its own size: a filed one-line fix can break production, and a stated fix can
   be unavailable. Re-scope deliberately at the start rather than letting later
   rounds discover it.
2. **State the blast radius to both sides.** The reviewer's prompt and the
   re-fix prompt carry the same sentence about what the diff may touch.
   Otherwise an out-of-scope discovery and an in-scope defect come back looking
   identical.
3. **Ask for out-of-scope findings as FILE THIS**, in a separate list with
   evidence: issues, not commits.
4. **Spawn fresh, never as a fork.** The reviewer derives correctness from the
   code, not from the author's assumptions.
5. **Give the reviewer an exit condition.** It will always find *something*. Ask
   it to separate "would hold a commit" from "would read better", and treat a
   clean `SHIP` as a real outcome.
6. **Verify findings at source before acting.** A reviewer can cite code that
   exists only on its own branch, or read a stale claim back as fact. Apply the
   same test to the fix you write in response; that is where the next round's
   defect usually comes from.
7. **Every fix is red first.** Write the test that fails on the current tree,
   watch it fail, then change production code. A finding fixed without one comes
   back next round as unpinned; keep the mutant the reviewer named as the
   acceptance check.
8. **Prefer a rebuild over another round.** If a round still returns substantive
   findings *and* the scope has grown, reset to the first good commit and reapply
   only the confirmed findings.
9. **Re-verify anything sourced from outside the repository.** A memory, a past
   session, a hand-off note: these were true once, and nothing says when they
   stopped being true. The same holds for a claim about another system (what a
   client sends, what a vendor answers): the reviewer cannot reach it, so survey
   or measure it yourself and put the evidence in the PR body.

## Knowing when to stop

Track two numbers across rounds: the **severity ceiling** (the worst finding
each round) and the **scope** (files and lines in the diff). A falling ceiling
with flat scope is convergence: keep going while the ceiling is substantive, and
ship once what remains is precision. A flat or rising ceiling with growing scope
is divergence: stop and rebuild. A run of `FIX-FIRST` verdicts on a claim-dense
document is not by itself a reason to loop; ask whether the findings still change
what a reader would do.

## Prompt shape

Give the reviewer the diff (`git diff --cached` or a ref range), a one-paragraph
intent, the blast radius, the relevant ADRs and a ranked attack list. Ask for
`SHIP` / `FIX-FIRST` / `REWORK`, findings ranked by severity with `file:line`
evidence, and a separate FILE THIS list. On a later round, say which round it is
and what earlier rounds found, and tell it to re-derive rather than grade the
fixes: a rewritten claim is not a verified one.

**Pin what it reads.** Give the hash of each file under review (`git rev-parse
:<path>` for a staged blob, `git hash-object <file>` otherwise) and ask the
reviewer to re-check it at the end. A tree that moves under a reviewer, often
through the author's own edit, turns its verdict into one about text nobody read.

**When the diff is documentation**, point the reviewer at the claims to verify,
one by one, and tell it to skip rewordings that would merely read better.

### Where the reviewer comes from

- **Claude Code and pi** spawn the `adversarial-reviewer` subagent. Both
  definitions are thin: their body tells the reviewer to read REVIEWER.md first,
  so the contract arrives because the reviewer complies, not because the runtime
  inlines it. A repository's own `adversarial-reviewer` definition overrides the
  user-level one.
- **Codex** has no named subagent. Put the contract, the per-review context and
  the diff to review in the prompt:

  ```bash
  { cat ~/.agents/skills/adversarial-review/REVIEWER.md review-context.md
    echo "Review the diff from: git diff origin/main...HEAD"; } | codex review -
  ```

  `review-context.md` holds the intent, blast radius, ADRs and attack list.
  Without it the reviewer cannot tell an out-of-scope discovery from an in-scope
  defect, which is rule 2 failing before the review starts.
