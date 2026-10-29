# Fixing a bug test-first

The loop in [SKILL.md](SKILL.md), with the bug as the behaviour: red reproduces
it, and red again puts it back. One check a feature does not need, the
**silent-pass sweep**, finds tests that were passing because of the bug. When
the fix isn't yours to make, pin the bug as a known defect instead (below).

1. **Reproduce where the misbehaviour surfaces**, not where the broken line is.
   A button enabled when it should be disabled is a component test, even when
   the wrong predicate lives in a helper.
2. **Red on the reported failure.** The test fails the way the report
   describes: an error response fails on the error, a wrong total fails on the
   total. A test that fails for some other reason is not a reproduction.
3. **Make the smallest fix** that turns it green.
4. **Red again, then green again**, by the steps in [SKILL.md](SKILL.md): put
   the bug back, and the test fails as it did when you reproduced the bug.
   Then restore the fix, and the test passes.
5. **Silent-pass sweep.** Run the whole suite. A fix that tightens a check (a
   guard that always passed, a validation that never fired) breaks the tests
   that relied on the slack. Change their inputs to fit the corrected
   behaviour and keep their assertions, unless an assertion pinned the bug
   itself: then correct its expected value. Say in the commit message why
   each test changed: each is evidence of the bug's reach.
6. **Name the bug in the test**, in its docstring or title, citing the issue,
   so the next reader knows why it exists.

Then check the test against "After the green" in [SKILL.md](SKILL.md).

## Known defects

When the fix belongs to another repo or team, or waits on a decision, pin the
bug as a **known defect**: a test of the correct behaviour that fails until the
fix lands.

1. **Reproduce where the misbehaviour surfaces**, as in step 1 above.
2. **Assert the outcome a fix would give**, and mark the test as an expected
   failure that must fail, citing the issue: pytest's
   `@pytest.mark.xfail(strict=True, reason="#123")`, or the framework's
   equivalent. Strict, so that the fix turns the suite red and someone removes
   the marker.
3. **Red on the defect.** Run the test with the marker ignored
   (`pytest --runxfail`): it fails on the assertion that pins the defect, not
   in setup.
4. **Pair it with a control**: a test of the legitimate path through the same
   code, such as the owner's own call or an allowed role, taken through the
   whole loop. A green control shows the setup works, so the known defect's
   failure is the defect's.
5. **Show it flips.** Where the test can stand in for the fix's outcome (an
   allowed caller in place of the refused one), make that change: the run
   reports an unexpected pass, and strict turns it into a failure, which shows
   the rest of the test holds once the defect is fixed. Then restore it.
6. **When the fix lands**, the unexpected pass fails the suite. Remove the
   marker, keep the test, and close the issue.
