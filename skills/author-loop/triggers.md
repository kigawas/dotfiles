# Triggers by runtime

[author-loop](SKILL.md) and [review-loop](../review-loop/SKILL.md) say "the
trigger" and "the state record" without naming a tool. This is the map.

| Runtime | Arm | List | Stop | The state record |
| --- | --- | --- | --- | --- |
| A Claude Code session (CLI or desktop) | `CronCreate` | `CronList` | `CronDelete` | a file outside every worktree |
| A Claude Code cloud scheduled task, formerly a routine | `/schedule`, or the `RemoteTrigger` tool's `create` | `/schedule list`, or `list` | the on/off switch on its page; confirm with `RemoteTrigger`'s `get` that `enabled` is false | a tracking issue |
| A pi session with [`@gridport/pi-extensions`](https://github.com/gridport/pi-extensions) | the `loop` tool's `create` | `list` | `delete` | a file outside every worktree |

A worktree is removed at cleanup, so a record kept in one goes with it.

## Every runtime

- **Name the skill in plain words** in the prompt ("Run one firing of the
  review-loop skill"). pi sends a firing as a plain message, without expanding
  `/skill:name`. Claude Code runs a `/name` in a firing only for a skill the
  model may invoke on its own.
- **A firing waits for an idle session.** One that comes due while the agent is
  busy fires once it is idle, and missed firings collapse into one. So a long
  firing delays the next, and a firing cannot assume an hour has passed.

## Local sessions: Claude Code and pi

- **The trigger lives in the session.** It stops when the session ends. Claude
  Code restores it on `--resume` or `--continue`, and a job armed as durable is
  saved to the project's `.claude/scheduled_tasks.json` and survives restarts,
  but runs only in that folder. pi keeps it across `/reload`, but not across a
  restart, `/new`, `/resume` or `/fork`.
- **A recurring job expires 7 days after it was created.** Claude Code fires it
  one last time first. Re-arm before then, deliberately, and record the re-arm.
  pi refuses to arm the same prompt twice, so delete the old job before
  creating its replacement.
- **Claude Code runs a recurring job late**, by up to half the gap between runs
  and at most 30 minutes: an hourly job runs 0 to 30 minutes after its minute.
  The minute in the cron expression is not the time it runs; `CronList` gives
  that.
- **After Esc in pi**, pending firings wait 5 minutes, so the session stays
  yours to type into.

## Cloud scheduled tasks (Claude Code)

- **Each run starts a fresh session from a fresh clone.** No local file
  survives between runs, so the state record lives in a tracking issue: its body,
  plus comments once it grows. A body or comment holds at most 65,536
  characters, and a write past that fails, so the firing cannot record what it
  did. Once the body passes about 40,000 characters, move the oldest rows the
  next firing no longer needs into a new comment, and link it from the body.
- **A run never sees the skills on your machine.** A task outside a project
  loads the skills committed to the cloned repository. One created from a
  project loads none of them, only skills enabled for the claude.ai account.
  Put the skill where the run loads it, or write everything into the prompt.
- **A run acts on GitHub as you**: its reviews, comments and PRs carry your
  user. For review-loop that is a
  [shared identity](../review-loop/shared-identity.md), unless the run gets a
  token of its own through the environment's variables.
- **Cron hours are UTC** unless the expression starts with `CRON_TZ=`, and the
  shortest interval is one hour.
- **Pausing disables the task** rather than trusting a session's end to stop it.
  To resume, enable the same task again: creating a new one beside a disabled one
  is the duplicate that renewing guards against. Record the task's id with the
  re-arm prompt.
- **A run may have no `gh`.** The GitHub MCP tools stand in, and they differ in
  ways that matter: a review posted through them returns no review id, which
  review-loop's [shared-identity guard](../review-loop/shared-identity.md) needs.
