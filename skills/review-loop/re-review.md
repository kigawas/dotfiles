# Re-reviewing a PR that moved

The [review-loop](SKILL.md) branch for a PR you have reviewed whose head,
merge-base or base has moved since. Everything here compares against the head
and merge-base the state record holds from your last verdict. A PR missing from
the record has nothing to compare against: give it the full method of [Reviewing
one PR](SKILL.md#reviewing-one-pr).

Where a push does not dismiss approvals, a PR you approved whose head or
merge-base moved is still approved, over code nobody read. Withdraw the approval
([SKILL.md](SKILL.md#posting-the-review)) before re-reviewing it. A base that
merely advanced, or a parent that moved, leaves the approval to the checks
below.

## Fetch both sides

What you reviewed, by the full SHAs the record keeps. Look locally first: an
earlier review usually fetched them, and a failed fetch says nothing about
whether a commit is here. A fetch takes an abbreviated SHA as a ref name and
fails, which is why the record keeps full ones.

```bash
for c in <recorded-base> <recorded-head>; do
  git cat-file -e "$c^{commit}" 2>/dev/null || git fetch origin "$c" --quiet
done
```

A commit that is neither here nor fetchable is gone, and so is the history you
reviewed: do the full method.

Then the current head and merge-base, written down at once, as for a first
review ([Diff against the true merge-base](SKILL.md#diff-against-the-true-merge-base)).

**Never recompute the old merge-base** from the PR's current base. When only the
base moved, as when a stacked PR is retargeted after its parent merges, that
gives the same range twice, and every check below passes over commits nobody
reviewed.

## Is the diff unchanged?

Compare trees first. Two commits with the same tree hold the same files,
however different their histories.

```bash
rh=$(git rev-parse --verify --quiet "<recorded-head>^{tree}") &&
nh=$(git rev-parse --verify --quiet "$HEAD_SHA^{tree}") &&
rb=$(git rev-parse --verify --quiet "<recorded-base>^{tree}") &&
nb=$(git rev-parse --verify --quiet "$BASE^{tree}") &&
[ "$rh" = "$nh" ] && [ "$rb" = "$nb" ] && echo same
```

Plain `git rev-parse X^{tree}` echoes back what it cannot resolve, so two empty
SHAs would compare equal; `--verify --quiet` prints nothing and fails.

When both match, the PR is byte-for-byte the one you reviewed, and the
reproduction stands. Post the verdict again pinned to `$HEAD_SHA`, since the
push may have dismissed your approval; an APPROVE passes the
[APPROVE gate](SKILL.md#the-approve-gate) on `$HEAD_SHA` first, since
identical trees do not carry a CI result over.

## Is it a pure rebase?

```bash
git range-diff --diff-merges=first-parent <recorded-base>..<recorded-head> "$BASE".."$HEAD_SHA"
```

`--diff-merges=first-parent` is not optional: without it, `range-diff` leaves
merge commits out, and a merge of `main` into the PR carrying a line of its own
reads as a clean `=`. `range-diff` takes the flag from git 2.48 on. On an older
git, list the merge commits in each range, one command per range:

```bash
git rev-list --merges <recorded-base>..<recorded-head>
git rev-list --merges "$BASE".."$HEAD_SHA"
```

If either prints one, this check cannot be trusted on this git: do the full
method. If neither does, run `range-diff` without the flag.

`range-diff` compares text, so it prints `=` for a binary file whose content
changed. `git diff --numstat` shows a binary file with `-` in both counts, so if
this prints anything, do the full method:

```bash
old=$(git diff --numstat <recorded-base> <recorded-head>) &&
  new=$(git diff --numstat "$BASE" "$HEAD_SHA") || echo NUMSTAT-FAILED
printf '%s\n%s\n' "$old" "$new" | awk -F'\t' '$1 == "-" && $2 == "-"'
```

- **Every line `=`, and no binary file:** a confirmed pure rebase. Re-run the
  gates on the new head, which carries whatever else merged into its base, and
  the PR's mutant battery ([mutants.md](mutants.md)): green gates show the new
  tree passes, not that the tests which caught each mutant survived the new
  base. A failing gate, a surviving mutant or a broken entry means the full
  method. Otherwise post the verdict again pinned to `$HEAD_SHA`, saying it
  carries over and why; an APPROVE passes the
  [APPROVE gate](SKILL.md#the-approve-gate) first.
- **Anything else** (`!`, `<`, `>`, or a merge commit shown as `-: ------- >`):
  not a confirmed rebase, and do the full method. `!` also appears when the base
  edited a line near the PR's own.

## The full method starts with the old reproduction

Before reading the new diff, re-run the exact reproduction or mutation that
found the original defect (the state record keeps it with the finding),
unchanged, against the new head. A push that adds tests and touches nearby code
reads like a fix, and whether it is one is the thing to prove. Once the
reproduction no longer reproduces, read the diff to confirm the fix is what
caused that: not a skip, a fixture change or a masked symptom. Then mutate the
fix before posting the verdict, and go on as for a first review.

## A stacked PR after its parent merges

GitHub retargets the child to `main`. After a squash merge the parent's commits
never become ancestors, so the child's merge-base with `main` is the *old*
`main`, and its diff wrongly carries the parent's whole content. It may also
conflict. A verdict posted then sits on a head the author is about to replace.

1. **Post nothing, unless you approved it.** Record it as waiting for its
   rebase. A child you approved gets a withdrawal instead: a retarget starts no
   CI run and may not dismiss the approval, so the child could merge onto a
   `main` no gate ran against. A withdrawal leaves the recorded merge-base in
   place, which step 2 needs.
2. **After the rebase**, run the pure-rebase check above. For a child reviewed
   while stacked, the recorded merge-base is the parent's head at the time, so
   the child's own commits are the only ones in either range.
3. **Prove the change is unchanged:**

   ```bash
   diff <(git diff --binary <recorded-base> <recorded-head> | grep -v '^index ') \
        <(git diff --binary "$BASE" "$HEAD_SHA" | grep -v '^index ')
   ```

   An `index` line names the whole file's blobs, so it differs whenever the new
   base changed that file anywhere, even outside the PR's hunks. Every other
   line, the hunk headers included, must match. No textual check sees a base
   edit outside the hunks that changes what an identical hunk means; the gates
   and the battery in step 2 are the only check on that.
4. **The verdict carries over only if step 2 confirms a pure rebase and step 3
   prints nothing.** Anything else means the full method.

## A child relying on its parent's open finding

A child whose safety rests on a finding still open on its parent gets a
REQUEST_CHANGES naming that finding, whatever its own diff shows: an approval
would stand if the parent merged unfixed. A firing that sends a parent back
applies this to the parent's open children in the same firing, since a child
reviewed first had nothing to rely on then.

Record the dependency beside the child, with the parent's head at the time, and
keep it until the parent has merged and the fix is confirmed in `main`. The fix
can land on the parent's branch under the child, or in `main` after the parent
merges. Every check of the child while the dependency is recorded confirms that
the fix covers what the child relies on, and says so. Once one does, the child
gets the verdict its own diff earned, after a check against the parent's new
head as below. A fix that does not cover it, or one dropped since, gets a
REQUEST_CHANGES naming what the child still relies on. An approved child whose
own head and merge-base have not moved keeps its approval, with nothing posted,
when the fix still covers it and the check against the parent's new head passes.

## A base that moves under an unchanged head

When the base advances and the head does not, the diff and the merge-base stay
the same, nothing dismisses an approval, and CI last ran against the old base.
Every APPROVE runs this check first, as part of the
[APPROVE gate](SKILL.md#base-the-head-merged-with-the-current-base).
Unless the base's rules require PRs to be up to date before merging, run it
again each time the base advances under a PR you approved:

```bash
T=$(git merge-tree --write-tree origin/<base> "$HEAD_SHA"); rc=$?
case "$rc:$T" in
  0:*)  M=$(git commit-tree -m 'review merge' -p origin/<base> -p "$HEAD_SHA" "$T") &&
          git worktree add --detach <path> "$M" ;;
  1:?*) echo CONFLICT ;;
  *)    echo "merge-tree failed ($rc)" ;;
esac
```

A clean merge exits 0 and prints only the tree's id. A conflict exits 1 and
still prints a tree id first. A ref that does not resolve also exits 1, but
prints nothing to stdout: that is an error, not a conflict. Run the gates and
the battery in the worktree, a merge that is never pushed. When the base tip is
still the merge-base, the merge is the head itself.

- **On a PR you approved**, all passing means the approval stands and nothing is
  posted. A conflict, a failing gate or a survivor gets a REQUEST_CHANGES naming
  the base commit it fails against: resolving a conflict could keep the
  approval, and the PR could then merge before the next firing.
- **Before a first approval**, a conflict means posting nothing and recording
  the PR as waiting, and a failing gate or battery is a blocking finding.

Record the base tip you checked, so the next firing checks only a newer one.

## Replying on threads

Reply on the threads the new head settles
(`gh api repos/{owner}/{repo}/pulls/<n>/comments/<id>/replies -f body=…`), and
leave the rest open. Resolving a thread has no REST call: it is the GraphQL
`resolveReviewThread` mutation, which takes the thread's node id
(`gh api graphql`).
