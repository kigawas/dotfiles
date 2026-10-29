# Fixing a bug test-first

The loop in [SKILL.md](SKILL.md), with the bug as the behaviour: red reproduces
it, and red again puts it back. One check a feature does not need, the
**silent-pass sweep**, finds tests that were passing because of the bug.

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
