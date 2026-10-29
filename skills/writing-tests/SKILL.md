---
name: writing-tests
description: Writing tests through the red, green, red again, green again loop. Use when building features or fixing bugs test-first (TDD), writing tests for existing code, pinning a known defect, or closing a coverage gap.
---

# Writing tests

Every test goes through a four-phase loop: **red**, **green**, **red again**, **green again**. Red again is the phase that proves a test can fail: take the behaviour out and watch the test go red. This skill is the reference for running the loop and for writing tests worth keeping. Every section applies on every cycle: consult them before and during the loop, not after.

Where the loop starts depends on the work:

- **New behaviour** starts at red: the test comes before the code, as in test-driven development (TDD).
- **A bug** starts at red on the reported failure: follow [bug-fixes.md](bug-fixes.md). It also covers a bug whose fix isn't yours to make, pinned as a **known defect**.
- **Existing behaviour** (tests for code that already works, before a refactor, or to close a coverage gap) starts at green: see "Pinning existing behaviour".

When exploring the codebase, read `GLOSSARY.md` (if it exists) so test names and interface vocabulary match the project's domain language, and respect ADRs in the area you're touching.

## What a good test is

Tests verify behavior through public interfaces, not implementation details. Code can change entirely; tests shouldn't. A good test reads like a specification: "user can checkout with valid cart" tells you exactly what capability exists, and it survives refactors because it doesn't care about internal structure.

See [tests.md](tests.md) for examples and [mocking.md](mocking.md) for mocking guidelines.

## Seams: where tests go

A **seam** is the public boundary you test at: the interface where you observe behavior without reaching inside. Tests live at seams, never against internals.

**Test only at pre-agreed seams.** Before writing any test, write down the seams under test and confirm them with the user. No test is written at an unconfirmed seam. You can't test everything, so agreeing the seams up front is how testing effort lands on the critical paths and complex logic instead of every edge case.

Ask: "What's the public interface, and which seams should we test?" Give each proposed seam a one-line note on what it catches and what it misses.

A bug fix brings its seam with it: the boundary where the misbehaviour surfaces, which is often not where the broken line is. State that seam, then follow [bug-fixes.md](bug-fixes.md) without a confirmation round: the report has already decided where it surfaces.

When the shape of that interface is itself in question (how deep the module is, where the seam belongs, what the interface should expose), call the Skill tool with "codebase-design" for the vocabulary. It is the shared source of the module, interface, depth, seam, adapter, leverage and locality terms, and it is a reference to consult, not a session to run.

## Anti-patterns

- **Implementation-coupled**: mocks internal collaborators, tests private methods, or verifies through a side channel (querying the database instead of using the interface). The tell: the test breaks when you refactor but behavior hasn't changed.
- **Tautological**: the assertion recomputes the expected value the way the code does (`expect(add(a, b)).toBe(a + b)`, a snapshot derived by hand the same way, a constant asserted equal to itself), so it passes by construction and can never disagree with the code. Expected values must come from an independent source of truth: a known-good literal, a worked example, the spec, a reference implementation's real output. Subtler forms pass by construction too: a constant imported from the module it should check, a hand-copied list beside the one it guards, the same normalisation applied to both sides of a comparison, a fake that shares the implementation's logic, a test parametrised over the collection it guards (it loses the case along with the item).
- **Horizontal slicing**: writing all tests first, then all implementation. Bulk tests verify _imagined_ behavior: you test the _shape_ of things rather than user-facing behavior, the tests go insensitive to real changes, and you commit to test structure before understanding the implementation. Work in **vertical slices** instead: one test → one implementation → repeat, each test a **tracer bullet** that responds to what the last cycle taught you.

## The loop

One slice per cycle: one seam, one test, one minimal implementation. Each phase ends on a run of the test.

1. **Red.** Write the failing test first. It fails for the right reason, on the behaviour it pins: the new symbol or argument the code lacks, the assertion that doesn't match yet, or, for a bug, the reported error. A failure in the test's own setup (an unrelated import, a missing fixture or service, a skip) is not red.
2. **Green.** Write only enough code to pass it. Don't anticipate future tests or add speculative features.
3. **Red again.** Take the behaviour back out and watch the test fail. Green proves only that the test passes; red again proves it catches the behaviour's loss.
   1. Stage the files the change touched, whole: `git add -- <changed files>`. Then `git diff -- <changed files>` prints nothing. The restore in green again copies those files back from the index and discards every unstaged change in them, the change or anyone else's work alike. Staging whole files can stage other work in them too; leave it out of the commit.
   2. Break the behaviour with the editor: revert the production change, or, for a bug, put the bug back. When red was the missing symbol, keep the symbol and break what it does (return the old value, skip the new branch), so the test fails on its assertion this time, not on the import.
   3. Run the test: it fails on its assertion, for a bug as it did at red. If it passes, check that `git diff` shows the break before you doubt the test.
4. **Green again.** Restore with `git checkout -- <changed files>`. `git diff -- <changed files>` prints nothing again, and the test passes.

When a slice adds several tests, repeat red again and green again one break at a time, until every new test has gone red.

**Broken code runs for real.** Before a break, ask what the broken code will write: against a shared database or a live service, it writes real rows. Break only code whose writes stay yours: a test database, a fake, the test's own records. Where the code can't be broken safely, or isn't yours to edit, change the test's expected value instead, and say so: that proves the assertion runs and is exact, not that it catches the loss.

In Python, run red again with `PYTHONDONTWRITEBYTECODE=1`, or clear `__pycache__` after the restore. A break of the same length, restored within the same second, otherwise keeps running from the bytecode cache.

## Pinning existing behaviour

A test for code that already works passes the moment it is written. It starts at green, and red again is its only proof that it can fail.

1. **Green on exact values.** Assert the exact values, errors and state today's code produces. Read each one before you pin it: a value that looks wrong is a bug, so pin it by [bug-fixes.md](bug-fixes.md) instead.
2. **Red again and green again**, as in the loop: break the behaviour the test pins, watch the test fail on its assertion, then restore.

## Throughout

- **Read the test count on every run.** Count failed and passed tests, not failed files or the exit code. A broken import or a missing service fails a whole file, stops collection, skips tests or runs none, so the exit code can read red or green while no test ran. The one such error that counts as red is the import of the new symbol, in its first red.
- **Compare names, not counts.** When one run is measured against another (before and after a change, a branch against its base), compare which tests fail, not how many: a change can fix three and break two. Run the base fresh, in a throwaway `git worktree add --detach <path> <base>`. A list of failures saved from an earlier run is no baseline, since flaky tests come and go.
- **Fix the code, not the test.** To turn a run green, change the code. Change an existing assertion only when the behaviour it pins is meant to change, and say why in the commit message. A test copied from upstream or a reference implementation stays as it is; add a new test beside it.
- **Pin before you change.** Before changing or refactoring code, check that tests pin the behaviour that must survive. Where none does, pin it first.
- **Refactoring is not part of the loop.** Do it once the slice is green again, as its own change, with the suite green before and after.

## After the green

Red again can't show that the test pins the right thing. Before calling the slice done, run the whole suite, then attack the test. A check that changes the test sends it through red again and green again once more:

- **The first gate to fire is the target.** Set up enough valid state that every earlier check passes. A "refused: insufficient funds" test against an account that doesn't exist passes on the wrong refusal.
- **The assertion is specific.** Assert the exact error, value and state the behaviour produces. "It raised" or "an error is present" passes on any failure.
- **What must stay, stays.** An operation that clears, moves or cancels is naturally tested for doing so, and that test also passes when it does too much. Put the neighbouring state in the fixture and assert it survives. Run an idempotent operation twice and assert the second run changes nothing.
- **Every outcome, not the boundary.** For loops and concurrency, assert each result. A limit test that checks only that call 11 is refused misses a limit that fires at call 3: assert calls 1 to 10 pass too. For concurrent calls, assert the exact number accepted and the reason for every refusal.
- **The arguments, not the call.** Where a mock stands in for a system boundary ([mocking.md](mocking.md)), assert what it was called with: "was called" passes when the argument is wrong.
- **The wiring.** A test on a helper doesn't prove the decorator, middleware or provider in front of it applies the helper. Propose one test through the real entry point as a seam.
- **The changed lines are covered.** Run coverage with branches and read it for the lines the change touched. A changed line no test reaches is untested, and a drop in coverage counts as red. Reach each line through a seam: a line no seam reaches is a seam question, or dead code.

## When the seam is hard to reach

Propose extracting the logic into a small pure module, and that module as the seam: logic that is hard to reach through its interface marks a seam worth deepening (see "codebase-design" above). Once the user confirms it, extract between slices, as a refactor under a green suite, then write the red test against the module. If you test one layer down instead, propose that layer as the seam the same way, test the exact code path the change drives, and say in the test which layer it stands in for.
