# A review identity a person also uses

GitHub keeps one verdict per reviewer. When [review-loop](SKILL.md) reviews
under an identity a person also reviews under, the routine's APPROVE replaces
that person's change request under the same name, and clears the block. The
structural fix is an identity of the routine's own. Until then, this guard runs
first on every open PR, every firing, and a PR it holds out gets nothing else.

## The runtime must return the posted review's id

The guard records the id of each review the routine posts before anything
else, so a runtime whose post returns no id cannot run it. Taking the id from
the reviews list afterwards could record a person's review as the routine's.
The GitHub MCP tools return none. A runtime that can post only as a draft and
then submit it fails too: at the read just before submitting, its own draft is
the latest verdict review, one the record does not show. Recording the draft's
id is no way round it: a draft left by a firing that died can be finished by a
person, and would then pass as the routine's.

## The guard

Find the identity's latest verdict review on the PR: an APPROVE or
REQUEST_CHANGES, dismissed ones included (a dismissed review is still the last
verdict given), a COMMENT whose body opens with `Verdict:`, or a `PENDING`
draft (a person's draft is reason enough to hold off). A reply on a thread
creates an empty COMMENT review, and that is not a verdict. The list is oldest
first and paged, and every reply adds to it, so read every page and take the
last row:

```bash
( set -o pipefail
  gh api --paginate "repos/{owner}/{repo}/pulls/<n>/reviews?per_page=100" \
    --jq '.[] | select(.user.login == "<identity>")
          | select(.state != "COMMENTED" or (.body | startswith("Verdict:")))
          | [.id, .state, .commit_id] | @tsv' | tail -n 1 ) || echo READ-FAILED
```

With `--paginate`, the `--jq` runs on each page alone, so the filter emits rows
and `tail` takes the last; a `last` inside the filter would give each page's
last. `pipefail` makes a failed `gh` fail the line, where `tail` alone would
exit 0 on a missing page. `READ-FAILED` follows gh's error JSON on the same
line, so match it as a substring. A failed read posts nothing on that PR this
firing, and is reported.

If that review is not the one the state record shows the routine posting
(another id, or any verdict review on a PR with no entry), a person may have
written it:
- post nothing on that PR, and drop any hold on it;
- mark it **held out** in the state record, with that review's id;
- report it, naming the PR and the review;
- where the record shows the routine's APPROVE and the head or merge-base has
  moved since, record an unwithdrawn approval
  ([Posting the review](SKILL.md#posting-the-review), step 5): it now stands
  over code nobody read, and the hold-out keeps the withdrawal from posting.

The same read runs again just before each post. A verdict review you did not
post means not submitting: the PR is held out.

## Clearing a hold-out

A PR held out stays out, firing after firing, whatever the next comparison
shows, until a person clears the mark.

- **Where the latest verdict review is a person's**, they clear it by recording
  that review's id as the routine's **baseline**, which accepts that the
  routine's next verdict replaces it. Only a submitted review can be a baseline:
  submitting a draft keeps its id, so a baseline on a draft would let the
  routine overwrite the verdict it becomes. A baseline is still a person's
  review: its body and inline comments are claims, read before the next APPROVE
  like any other reviewer's.
- **Where the latest is the routine's own**, as after a gap (below), the record
  already holds its id: they clear the mark and change nothing else.

Setting a baseline sets the review id only. A head and merge-base the routine
itself posted stay; otherwise they stay empty, and never come from the person's
review, whose commit the routine may never have read. An entry with no head
gets the full method.

An approval that could not be withdrawn while the PR was held out
([Posting the review](SKILL.md#posting-the-review), step 5) is retried once the
mark is cleared.

## What the routine posted

Under a shared identity, the login cannot tell the routine's posts from a
person's. So the state record keeps a list of every post the routine made: its
reviews, the inline comments each carried, its thread replies, the empty COMMENT
review GitHub wraps around each reply, and its conversation comments. Each entry
holds the id, and its `updated_at` or, for a review, its body hash
([taken as SKILL.md says](SKILL.md#claims-what-other-reviewers-said)).
Nothing joins the list by derivation: an inline comment is not exempt because
its review is on the list. A person can edit the routine's post, and a changed
hash or `updated_at` is then read as a stranger's claim.

Everything else under the identity is a stranger's claim: verify it as you would
any other reviewer's, and give agreement no discount.

**Complete an entry only when what reads back is what you posted.** Record the
review's id at once; then read it back:
- the review's body hash equals the hash of `review.json`'s body, computed the
  same way, and that one hash is what you record;
- its inline comments, from `pulls/<n>/reviews/<id>/comments` with every page
  read, match the `comments` you sent as a multiset of bodies;
- a reply's wrapper review is `COMMENTED` with an empty body; the reply's own
  response carries its id, `updated_at` and the wrapper's id.

A person can edit a post, or a draft of theirs can take in a reply, between the
post and the read-back. An entry that does not match, or that a firing never
finished, stays without its hash or `updated_at`, and is read as a claim.

**Seeding the list.** A person may seed it, but only with posts they know the
routine made, each with its current hash or `updated_at`. An edited post, or one
they are unsure of, stays off. The review-id field is not such a list: after a
baseline it holds a person's review. A record kept before this guard has no
review ids, so the first firing holds out every PR where the identity has a
verdict review; a person seeds the ids from reviews they know the routine
posted, and clears the marks.

## After posting, check the gap

Keep the review id the record held before this post (none if it held none).
Then read the list again, with `tail -n 2` in place of `tail -n 1`.

- **The last row must be the review you just posted.** If it is not, a person's
  review landed after yours: mark the PR held out, report both, and post nothing
  more.
- **The row before it is the verdict review just before yours** (none, if only
  one row came back). If it is not the review the record held, a person's review
  landed in the gap and yours replaced it. Whatever yours was, mark the PR held
  out and report both.
- **Undo yours only when it cleared a block:** the review in the gap was a
  REQUEST_CHANGES, and yours an APPROVE. The undo is a REQUEST_CHANGES saying the
  approval replaced that review by accident and naming it. It is the one post
  allowed on a PR held out, and it is guarded too: just before it, the latest
  verdict review must still be your APPROVE, and just after it, the two-row read
  must show your APPROVE and then the undo. If either read shows anything else,
  or the undo fails, post nothing more, and report that an APPROVE may be
  standing over a person's change request. Record the undo as the routine's
  latest review.
- **No undo for anything else.** A person's APPROVE, `Verdict:` COMMENT or draft
  in the gap stays as it is: a block would put under their name a verdict they
  never gave.
- **A failed read** cannot rule the gap out: mark the PR held out, and report
  it, naming the review you posted.
