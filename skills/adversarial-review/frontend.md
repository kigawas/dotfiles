# Frontend scope

The attack checklist for a diff that touches web UI: templates, components,
client scripts, styles, or their tests. Read it with [REVIEWER.md](REVIEWER.md),
which it extends.

## Attack checklist

- **Shown versus enforced**: a control shown for an action the server refuses, or
  hidden for one it would allow. A check in the client is a convenience; the
  server's check is the gate. When the diff moves either half, check the other.
- **The API contract**: every field the UI reads and sends, against the server's
  current schema. Look for a removed or renamed field, a changed type or enum
  value, a new required field, and extra keys a strict endpoint now refuses.
  Check which client version is deployed against which server.
- **State across events**: listeners stacking on retry paths, handlers capturing
  a stale index or closure, a response that lands after the user moved on, a
  double submit, and state that survives navigation when it should reset.
- **Every state rendered**: loading, empty, error, partial and offline; zero,
  one and many items; a very long value. An error swallowed into a blank screen
  is a finding.
- **Markup**: duplicate DOM ids across repeated fragments, hidden rows still
  counting for `:nth-child`, a field with no label, and a list keyed by index
  that can reorder.
- **Injection**: user or server text rendered as HTML (`innerHTML`, a template's
  safe filter, `dangerouslySetInnerHTML`, `v-html`), and URLs built from input.
- **Accessibility**: contrast computed, not eyeballed (4.5:1 for text, 3:1 for
  large text and marks), keyboard reach, focus order, and where focus lands after
  a dialog closes.
- **Theming**: a colour fixed in code where a token belongs. Search the whole
  module for literal colours, not just the diff.
- **Locale**: hard-coded strings, sentences assembled from pieces, dates, numbers
  and plurals outside the user's locale, and text that overflows in a longer
  language.
- **Cost**: work done per keystroke or per row, a new dependency's weight in the
  bundle, and layout shift.

## Tests

Beyond [the general checks](REVIEWER.md#tests-that-pass-by-construction):

- A screenshot or snapshot test proves only the states it renders. Check that
  each changed state has an image, open the updated images and look at them, and
  where the author says the other screens are unchanged, check they are
  byte-identical.
- An expected colour or string taken from the component's own constants passes
  by construction.
