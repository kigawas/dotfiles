---
description: The PR is merged; confirm it landed, clean up its worktree and branch, then pick the next task
argument-hint: "[PR number] [notes]"
---
The PR is merged. Clean up with the clear-branch skill; if it isn't loaded, read `~/.agents/skills/clear-branch/SKILL.md`. Confirm the work landed before removing anything. If a check fails, report it and stop, leaving the worktree and branch in place.

Then update the local default branch with `git merge --ff-only origin/<default>`, but only where its checkout is on that branch with a clean tree. Otherwise leave it: the prune already moved `origin/<default>`, which is what new branches start from. Don't stash, reset or switch to make the merge possible. Then tell me what's next.

$ARGUMENTS
