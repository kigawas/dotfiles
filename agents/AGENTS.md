# User instructions

## This file

- Update this file when a general pattern recurs, or when the user asks you to.

## Editing files

- Change existing files with a targeted edit tool that replaces exact text. Use a whole-file write tool only for new files or full rewrites.
- Don't change text files with Python, sed, or other scripts, so each change shows as a reviewable diff. Exception: non-text or malformed text files.

## Git

- Stage explicit file paths with `git add <path>`. Don't use `git add -A`, which stages unrelated in-flight changes.

## Compaction

- When compacting, keep important discussion and progress. Discard mechanical data, such as file-read output.

## Memory

- If your tool keeps a memory across sessions, record progress there after each checkpoint, such as a commit, a push, a merged PR or a finished plan step. Record what's done, what's next and any open decision. Update the existing progress entry rather than adding another.

## GitHub

- Different GitHub accounts own different repos. Before writing an issue or comment to a **public** repo with `gh`, ask the user to confirm which GitHub account to use, and save the answer in the project's instruction file (`AGENTS.md` or `CLAUDE.md`). Private repos need no confirmation, since GitHub limits access to them.

## Web requests

- Always send `curl` requests with a browser User-Agent.
- If the site rejects the browser User-Agent, or requires specific request details such as a contact email in the User-Agent, tell the user.

## Sessions

- By default, send messages to the session that belongs to the same repo. Ask the user when the session name is ambiguous.
- Save session names and IDs to memory: this session's once it has a name, and each peer's when you first message it. Names repeat across repos, so address a known peer by its ID.
