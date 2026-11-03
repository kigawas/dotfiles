# Mobile scope

The attack checklist for a diff that touches an Android, iOS or cross-platform
app. Read it with [REVIEWER.md](REVIEWER.md), which it extends. A screen's UI
code also takes [frontend.md](frontend.md)'s checks for state, accessibility and
theming.

## Attack checklist

- **The main thread**: anything that can block it, such as disk or database work,
  a lock a background thread holds, or a synchronous wait on a coroutine, queue
  or connection pool. Follow every lock the main thread can reach.
- **Lifecycle**: background, foreground and termination in quick succession;
  process death and state restore; a screen recreated by rotation, theme or
  locale change; a background task never ended, or ended twice. The OS kills a
  suspended app that holds a file lock in a shared container.
- **Threads**: mutable state reached from more than one thread, a callback
  delivered on a thread the code assumes is main, and cancellation that leaves
  native or database state open.
- **Native interop**: struct offsets and sizes on each architecture, memory freed
  on every error path and on a double close, an exception thrown while native
  state is held, and a pointer that outlives its owner.
- **Platform API semantics**: what a framework call actually does. Which thread
  runs its callback, whether the callback can run zero times or twice, which
  objects the framework holds weakly (a delegate released early), and what
  happens when the user denies a permission or a prompt. Read the platform's
  documentation and the library's source, and say in the finding which you read.
- **Persistence**: a schema migration from every shipped version, a transaction
  interrupted midway (commit, rollback, and whether the connection is still in a
  transaction), and a cache rebuilt when its format version moves. The user's
  record is never lost or half-applied.
- **Backup and transfer**: a backup restores on another device, on the other
  platform and on a later app version. Temporary files are removed on every path,
  cancel included.
- **Startup and hot paths**: work added to app start or to a screen with a
  latency budget, and a startup or baseline profile left stale where the
  repository keeps one.
- **Resources**: a colour fixed in code, layout XML, drawables or asset catalogs;
  a night or dark resource that changes something meant to stay, such as a
  launcher icon; contrast computed in the dark theme as well as the light.
- **Platform parity**: shared code that both platforms run. A change made for
  one platform must leave the other's behaviour as it was, unless the intent
  says otherwise.

## Runs

- Builds, emulators and devices are often shared with other sessions. Run the
  narrowest target that answers the question, one module's or one class's tests,
  and work only on a simulator or device the brief hands you. Leave shared build
  daemons running.
- Personal files the user keeps beside the code, such as their own data or
  purchased content, are off limits unless the brief allows them.
- A test process can lack a platform service the code uses, such as file
  coordination or the keychain. Say what that leaves to a check by hand.

## Tests

Beyond [the general checks](REVIEWER.md#tests-that-pass-by-construction):

- A test that waits on a latch, a dispatcher or the main queue can hang rather
  than fail. Look for its timeout.
- Screenshot tests: open the images the change records, light and dark, starting
  with the screens a fixed colour would break.
