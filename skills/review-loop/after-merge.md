# After a merge

The [review-loop](SKILL.md) branch for PRs that merged since the last firing.
For each one: find its merge commit, check that what landed is what you
approved, read CI's run on `main` for it, and read the comments that came after.
`main` here stands for the branch the repository merges PRs into.

## Which merges

"Since the last firing" means since the time the previous firing listed merged
PRs, which the state record keeps in UTC, even across a pause of days. List from
an hour before that time, and skip any merge the record holds as handled: a PR
that merged just before the last listing may not have been in it.

```bash
gh pr list --state merged --base main --search "merged:>=<start>" --limit 200 \
  --json number,mergedAt,mergeCommit
```

`<start>` is an hour before the recorded time, with its offset
(`2026-09-29T05:42:00Z` for a listing recorded at 06:42Z). The default limit of
30 is one a long pause can pass. A PR merged into another branch, such as a
stacked child into its parent, gets no run on `main`, so the listing keeps to
`main`. Record this listing's time, and add every merge the record holds with a
check still outstanding.

## Find the merge commit

Take its full SHA from `gh pr view <n> --json mergeCommit`, and never guess one.
For a rebase merge it is the last of the rebased commits. Then decide how the PR
merged, from the commit's own evidence:

```bash
TZ=UTC0 git log -1 --date=format-local:'%Y-%m-%dT%H:%M:%SZ' \
  --format='%P %ad %cd' <merge-commit>
gh pr view <n> --json mergedAt
```

- **Two parents:** a merge commit. Its first parent is the tip `main` had before.
- **A squash** only when it has one parent, its author date is the same instant
  as its committer date, and both are within a minute of `mergedAt`, and its
  subject is not the subject of any of the PR's own commits.
- **Anything else is a rebase merge.** A rebased commit keeps its own author
  date, as git's rebase does (not yet measured on a GitHub rebase merge).

Both the squash and the rebase readings need the PR's commits in full:
`gh api repos/{owner}/{repo}/pulls/<n> --jq .commits` gives their count, and
`gh api --paginate repos/{owner}/{repo}/pulls/<n>/commits` each message whole
(`.commit.message`, whose first line is the subject). Never take a subject from
`messageHeadline`, which GitHub cuts short past 72 characters. A listing shorter
than the count, as past 250 commits, supports neither reading, and the
comparison below stays outstanding.

## Check that what landed is what you approved

For a PR you approved, replay the approved head onto the tip `main` had just
before the merge, and compare the result with what landed. For a squash, that
tip is the merge commit's parent; for a merge commit, its first parent:

```bash
for c in <merge-commit> <approved-head>; do
  git cat-file -e "$c^{commit}" 2>/dev/null || git fetch origin "$c" --quiet
done
T=$(git merge-tree --write-tree <merge-commit>^ <approved-head>); rc=$?
case "$rc:$T" in
  0:*)  git diff --quiet "$T" <merge-commit>; d=$?
        [ "$d" = 0 ] && echo SAME; [ "$d" = 1 ] && echo MISMATCH
        [ "$d" -gt 1 ] && echo FAILED ;;
  1:?*) echo MISMATCH ;;   # the replay conflicts
  *)    echo FAILED ;;     # a commit that does not resolve, or git failed
esac
```

For a rebase merge of N commits, the tip before it is `<merge-commit>~N`. N is
established only by one run of consecutive commits on `main`, ending at the
merge commit, that matches every one of the PR's commits, oldest first, by
author, author date and subject; N is that run's length. A run covering only
some of them does not count: a smaller N moves the replay's tip past the PR's
own earlier commits, and a difference in them would be absorbed. Whether
GitHub's rebase merge keeps a commit that was empty to begin with is not yet
measured; if it drops one, no run covers every commit. Where N cannot be
established, the comparison stays outstanding.

`SAME` means what landed is exactly the approved change on the `main` it met.
`FAILED` measures nothing, and the comparison stays outstanding: `merge-tree`
exits 1 for a ref it cannot resolve as for a conflict, but prints nothing. A
`MISMATCH`, a conflict in the replay or a difference, is a finding: raise it on
the merged PR, then record the merge as handled with the mismatch named, so a
later window that reaches it does not raise it twice.

## Read CI's run on `main`

Where CI runs on pushes to `main`, read its run for the merge commit:
`gh run list --commit <merge-commit> --event push`. Pass the full 40-character
SHA: an abbreviated one finds no run, and an empty one lists every run the
repository has. A red run there
blocks nothing and pages no one, so this routine may be its only reader. Each
merge can match its approval while two merges break each other. Any run that
completed with a conclusion other than `success` is a finding, cancelled and
timed out included, since a suite that hangs past its job's timeout ends grey
rather than red. File an issue naming the run, after a search for duplicates.

A run still going, no run found, or a run this runtime cannot read is recorded
against the merge as unread. A skip directive such as `[skip ci]` in the head
commit's message is the one normal reason for no run.

## A check that cannot finish stays outstanding

An unknown merge commit, a comparison that could not run and an unread run are
each recorded against the merge as outstanding, by name. Every firing retries
the outstanding checks of every merge the record holds, however old. A firing
that finds a merge a day old or more, after that retry, names each check still
outstanding in its report and among the record's open follow-ups, as needing a
person, and in its own words: "the landed tree was never compared with the
approval" is not the same news as "CI's run is unread". The merge then counts
as handled, and no firing retries it. The hand-off rests on the merge's age, so
a firing cut short, or a pause, leaves the next firing to make it.

## A PR that merged without your approval

There is nothing to compare. If your last verdict on it was REQUEST_CHANGES,
check whether the defect landed, and if it did, file it as an issue. If it was a
withdrawal, report the merge to a person: a head nobody reviewed landed. An
unwithdrawn approval leaves the recorded verdict at APPROVE, so the comparison
above runs: a newer head shows as a mismatch. One that stood over a claim never
answered is reported with the merge too, naming the claim.

## Comments after the merge

You hold no branch for a PR you only reviewed, so clear-branch does not apply.
What does is the second half of adversarial-review's
[After the merge](../adversarial-review/SKILL.md#after-the-merge):
READ-REVIEWER-COMMENT → DECIDE-NEXT-STEP. Reviewers post after a merge as often
as before, and a claim the code refutes earns a reply with `file:line` evidence.
This routine never authors code, so where DECIDE-NEXT-STEP would cut a fix
branch, a confirmed defect becomes an issue, after a search for duplicates.
