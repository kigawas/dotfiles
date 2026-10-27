# The mutant battery

Each load-bearing claim a PR makes gets a mutant: a one-line change to the real
code that makes the claim false, and that a named test should catch. Green gates
on a later head show that the tree passes, not that those tests still exist, so
[review-loop](SKILL.md) keeps the mutants and runs them again whenever it
carries a verdict over ([re-review.md](re-review.md)).

## Each entry

One entry per mutant:
- the file;
- the exact text to replace, and its replacement;
- the tests that should catch it;
- the failure each should show: the assertion it trips.

## The script

Keep the battery as a script, so a later firing runs the same mutants rather
than a paraphrase of them.

- **Before replacing**, check that the text occurs exactly once. A text that
  occurs twice is changed at both places, or at the first only, and either way
  the verdict is about a mutant nobody chose.
- **Before mutating**, check that each test the entry names still exists, such
  as `pytest --collect-only -q <ids>` exiting 0.
- **For each mutant**, back the file up with `cp`, run its tests, restore the
  file, and check the file's hash against the original. For Python, run with
  `PYTHONDONTWRITEBYTECODE=1` after purging `__pycache__`: a stale `.pyc` runs
  the *previous* mutant ([REVIEWER.md](../adversarial-review/REVIEWER.md),
  method step 5).
- **A mutant is caught only when the runner reports failed tests, and a test the
  entry names fails with the failure the entry expects.** Anything else means a
  broken entry, not a kill:
  - **Any other exit status.** pytest exits 1 for failed tests. A collection
    error exits 2 when a file is named and 4 when a test id is, and a test id
    that no longer exists exits 4 too, running nothing. A script that counts any non-zero exit as a kill
    reads a renamed test, or a mutant that breaks an import, as caught.
  - **An exception the entry did not name**, such as a `NameError` from a
    replacement that no longer fits the code. The mutant then crashes the code
    rather than making the claim false.

## Where the entries live

Put the entries in the review body, under a collapsed `<details>` block, and
record that review's id in the state record as the one holding the PR's battery.
A re-review may start in a fresh session with no local files, and rebuilds the
script from them. It finds them by that id, not by which review is latest. Never
edit a posted review: the id finds the review, not its text, so an edit goes
unseen. Until a review of the PR posts a battery, the state record keeps the
entries instead; the review that posts one replaces them, so the record never
holds both.

A carry-over or a withdrawal need not repeat the battery, and must not reset
the chain: the record still names the review that holds it. If the record has
neither entries nor a review, write the PR's one or two load-bearing mutants
now.

## Rewriting an entry against a moved base

In a check against a base that moved under an unchanged head
([re-review.md](re-review.md#a-base-that-moves-under-an-unchanged-head)), an
entry may be broken on the merge, or its text no longer found exactly once.
Rewrite it only to find the same code again where the base moved or renamed it:
its text, its replacement, and a renamed test's id. Its expected failure stays
an assertion on the claim.

- Never drop an entry.
- Never let a rewrite accept a crash in place of that assertion, or mutate other
  code that trips the same assertion.
- An entry whose code the base removed, or that no such rewrite gets caught, is
  a survivor.

Everywhere else, a broken entry means the full method.

## When a battery is interrupted

A battery is `mutate → run → restore` in a loop, the shape that runs long enough
to hit a tool's timeout. When the call dies mid-iteration, the restore never
runs, and nothing announces it: the tree still carries the mutation.

- Restore from the `cp` backup, never `git checkout <path>`, which restores from
  the index and destroys unstaged work.
- Keep the selection narrow enough that the whole battery finishes inside one
  call.
- **Grep the source for the mutation before reading any result as evidence, and
  again before committing.**
