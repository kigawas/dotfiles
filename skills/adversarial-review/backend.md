# Backend scope

The attack checklist for a diff that touches services, APIs, data models,
background jobs, migrations, deploy configuration, or the tests of any of these.
Read it with [REVIEWER.md](REVIEWER.md), which it extends.

## Attack checklist

- **Data exposure and auth bypass**: for every returned or rendered value, trace
  the permission that gates it. Check what each guard actually enforces, not what
  its name suggests, and check the method resolution order where mixins meet
  local overrides. Endpoints are addressable without any UI linking to them:
  hand-crafted URLs, degenerate query parameters, IDs of excluded objects.
- **Shown versus enforced**: a surface offering an action the backend refuses, or
  withholding one it would allow. When a diff moves either half, check the other:
  the predicate that renders a control, the permission the endpoint enforces, and
  the query behind a form's choices are separate decisions, and they drift.
- **Merged reads**: when one surface unions several sources, verify gating per
  leg; a viewer allowed one leg must never receive another leg's rows, links or
  counts.
- **Missed call sites and mappings**: every enum member handled, every caller of
  a moved or renamed helper updated, every prefix split proven total against the
  actual values.
- **Crash paths**: a key set on one branch and read on another, `next()` on a
  possibly empty iterator, a broad `except` or `getattr` default that swallows an
  error raised inside a property, a nullable reference dereferenced.
- **Exceptions that slip a guard**: a client that translates only some failures
  into its own exception type, or a timeout exception that a broad `except`
  records as success while the work runs on. Check which type each arm actually
  raises.
- **Retries and side effects**: a side effect that leaves the transaction
  recording it. A transfer sent inside an atomic block whose record write then
  fails stays live while the record rolls back, so a retry pays twice. For every
  retry, redelivery and double submit, ask what it repeats.
- **Concurrency**: check-then-act with no lock or constraint behind it, two
  workers on one row, and a lock taken where the backend ignores it.
- **Money and other ledgers**: a write is proven by the exact change and by what
  must not move. Check rounding, precision, sign and currency.
- **Migrations**: rows that exist only after a post-migrate hook on a fresh
  database, the reverse operation, dependency pins, and agreement with any
  fixture that claims to be the source of truth.
- **Deploy compatibility**: what runs while the new version rolls out.
  - A job queued by the old version and consumed by the new: a renamed task, or
    a parameter added without a default. A schedule entry naming a task that no
    longer exists fails on every tick.
  - An API change a deployed client still calls: a removed or renamed field, a
    changed type or enum value, a new required field, a new refusal of extra
    keys, or an auth or cookie change.
  - Config or secrets the new code reads that the environment does not set yet.

  Name the deploy order the change needs.
- **Leaks through logs and errors**: a secret, token or personal datum in a log
  line, an exception message or an error response.
- **Efficiency**: a new column or `__str__` that queries per row, a query hidden
  in a property, a serializer that queries once per item.

## Runs

- **A migration**: migrate forward and backward against a fresh scratch database.
  A test suite that skips migrations proves nothing about order, seeding or
  reversibility.
- **An order-dependent failure**: it reproduces deterministically in a sequential
  run with the polluting module first. A failure that passes locally and fails in
  CI is usually this, not nondeterminism.

## Test suites

Beyond [the general checks](REVIEWER.md#tests-that-pass-by-construction):

- **Known defects**: an expected failure (xfail, skip, ignore) whose reason names
  no issue, that is not strict, or that fails in setup rather than on the defect.
  Run it, and read the failure.
- **Data**: rows a test leaves behind; dependence on seed data, test order,
  another test, a live service or the clock; IDs that can collide across runs or
  concurrent runners.
- **Artefacts**: behaviour of a local stand-in (a fake service, a test backend,
  local auth) pinned as the real system's.
- **A shared environment**: a shared stack or database holds other runners'
  evidence too. Keep your probes to well-formed data you created yourself, and
  leave shared services running and seeded as you found them. Where a finding
  needs input that would crash a shared service, show it from the code instead.
- **Harness changes**: the effect of a fixture or cleanup change on every test
  that uses it.
