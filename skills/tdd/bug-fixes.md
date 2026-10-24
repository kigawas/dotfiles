# Fixing a bug test-first

The loop in [SKILL.md](SKILL.md), plus two checks a feature does not need: the
**revert-check** proves the test catches the bug, and the **silent-pass sweep**
finds tests that were passing because of it.

1. **Reproduce where the misbehaviour surfaces**, not where the broken line is.
   A button enabled when it should be disabled is a component test, even when
   the wrong predicate lives in a helper.
2. **Red on the reported failure.** The test fails the way the report
   describes: an error response fails on the error, a wrong total fails on the
   total. A test that fails for some other reason is not a reproduction.
3. **Make the smallest fix** that turns it green.
4. **Revert-check.** Prove the test catches the bug:
   1. Stage the files the fix touched, whole: `git add -- <fixed files>`.
      Then `git diff -- <fixed files>` prints nothing. The restore below
      copies those files back from the index and discards every unstaged
      change in them, the fix or anyone else's work alike. Staging whole
      files can stage other work in them too; leave it out of the commit.
   2. Put the bug back with the editor and run the test: it fails as it did
      when you reproduced the bug. If it passes, check that `git diff` shows
      the bug back before you doubt the test.
   3. Restore with `git checkout -- <fixed files>`. `git diff -- <fixed files>`
      prints nothing again, and the test passes.
5. **Silent-pass sweep.** Run the whole suite. A fix that tightens a check (a
   guard that always passed, a validation that never fired) breaks the tests
   that relied on the slack. Change their inputs to fit the corrected
   behaviour and keep their assertions, unless an assertion pinned the bug
   itself: then correct its expected value. Say in the commit message why
   each test changed: each is evidence of the bug's reach.
6. **Name the bug in the test**, in its docstring or title, citing the issue,
   so the next reader knows why it exists.

Then check the test against "After the green" in [SKILL.md](SKILL.md).
