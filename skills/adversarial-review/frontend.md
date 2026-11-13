# Frontend scope

The attack checklist for a diff that touches web UI: templates, components,
client scripts, styles, or their tests. Read it with [REVIEWER.md](REVIEWER.md),
which it extends.

## Attack checklist

- **Data exposure**: for every value a template or component renders, trace the
  permission that gates it on the server. Hiding an element does not stop its
  data being sent.
- **Shown versus enforced**: a control shown for an action the server refuses, or
  hidden for one it would allow. A check in the client is a convenience; the
  server's check is the gate. When the diff moves either half, check the other.
  Where a permission disables a control rather than hiding it, the predicate that
  greys it, the permission the server enforces and the data behind its options
  are three decisions, and they drift. A gate the client does own, such as a
  step a flow must pass first, holds at the point of use: no other trigger, URL
  or child component reaches past it, and it stays shut while its state loads.
- **The API contract**: every field the UI reads and sends, against the server's
  current schema. Look for a removed or renamed field, a changed type or enum
  value, a new required field, and extra keys a strict endpoint now refuses.
  Check which client version is deployed against which server. A schema file
  generated from the server's spec changes only by regeneration, and the
  question is whether the server change it reflects has landed. Conventions the
  server owns, such as sign, units, precision and time zone, hold through every
  transform: one that flips a sign has to know whether the feed already did.
- **Lists and identity**: a list collapsed to its first element where the set
  matters (`items[0]`, or a default that takes the first enrolled option), a key
  or a selected state derived from a field that isn't unique, so two rows share
  a key or both show as selected, and a list keyed by index that can reorder.
- **State across events**: listeners stacking on retry paths, handlers capturing
  a stale index or closure, a response that lands after the user moved on, a
  double submit, and state that survives navigation when it should reset. Check
  each hook's dependency list against every value its body reads. A payload that
  must match an earlier step, such as a challenge already issued, is frozen when
  that step starts, not read again at submit. A guard or wrapper subscribed to
  state the flow itself changes can redirect or unmount mid-flow, and lose a
  screen shown only once, such as recovery codes.
- **Navigation**: a guard or loader that redirects on session state, against
  every path that navigates to it. An error handler that sends the user to sign
  in with the session still set makes a loop. A marker carried in the URL
  survives every redirect and tab switch that rebuilds the URL, since losing it
  fails silently. A tab left open across a deploy requests code chunks
  that no longer exist; the recovery reloads once, never in a loop.
- **Session and cache**: a client-side cache outlives a route change and a user.
  Signing out clears it through one path, switching account drops what was keyed
  to the old one, and a request the viewer may not make is never sent.
- **The HTTP client**: interceptor order; a flag that silences the error toast
  while the error still propagates; a token refresh that runs once for many
  failed calls, and never for a failure of the refresh or sign-out call itself,
  which would loop; and an error shown as the server's message, not the
  library's ("Request failed with status code 422").
- **Every state rendered**: loading, empty, error, partial and offline; zero,
  one and many items; a very long value. An error swallowed into a blank screen
  is a finding. So is optional chaining that hides a real absence, and a step
  that renders with no data behind it.
- **Money and numbers**: amounts in a decimal type, never floats; display that
  truncates or rounds as the house rule says; formatting through the app's own
  number and time-zone settings, where it keeps them, rather than the browser's
  locale; precision per asset, sign, zero and negative zero; a number the server
  sends as a string, such as `0E-18`, kept exact through every parse and format;
  an amount that is unknown, from a failed fetch or a missing rate, never shown
  as zero; and a required-number check that refuses `0` because it is falsy.
- **Markup**: duplicate DOM ids across repeated fragments, hidden rows still
  counting for `:nth-child`, and a field with no label.
- **Injection**: user or server text rendered as HTML (`innerHTML`, a template's
  safe filter, `dangerouslySetInnerHTML`, `v-html`), and URLs built from input.
- **Accessibility**: contrast computed, not eyeballed (4.5:1 for text, 3:1 for
  large text and marks), keyboard reach, focus order, and where focus lands after
  a dialog closes.
- **Theming**: a colour fixed in code where a token belongs. Search the whole
  module for literal colours, not just the diff. A token can set more than one
  property, such as size, line height and weight, so check each one where a
  token replaces a literal.
- **Locale**: hard-coded strings, sentences assembled from pieces, dates, numbers
  and plurals outside the user's locale, and text that overflows in a longer
  language. A timestamp parsed without its offset shifts by the browser's time
  zone. Read what the locale check compares: one that reads only static keys
  passes a dynamic key, and one that checks only the base locale passes a key
  missing from the others. Look for a key reused for two meanings.
- **Leftovers**: after a move or a removal, no locale key or request left
  orphaned.
- **Cost**: work done per keystroke or per row, a new dependency's weight in the
  bundle, and layout shift.

## Runs

- A production build is not always a type check: `vite build` strips types
  without checking them. Unless the build runs the type checker, run it as its
  own step.
- Dev-only code, such as a mocked network layer or a debug panel, stays out of
  the production build: look in the built bundle.

## Tests

Beyond [the general checks](REVIEWER.md#tests-that-pass-by-construction):

- A mocked network layer that only warns on an unhandled request lets a missing
  call pass. Assert on the handler.
- Test helpers can isolate state differently: one that renders a component may
  give each test a fresh cache while one that renders a hook shares it, so hook
  tests can pass in one order and fail alone. Module state also persists between
  the tests in a file, and a timer outlives its test unless it is cleared on
  unmount.
- A test that scans the source for a pattern has blind spots, such as `//` in a
  URL read as a comment. Plant a violation and watch it fail, and keep a
  behavioural test beside it.
- A screenshot or snapshot test proves only the states it renders. Check that
  each changed state has an image, open the updated images and look at them, and
  where the author says the other screens are unchanged, check they are
  byte-identical.
- An expected colour or string taken from the component's own constants passes
  by construction.
