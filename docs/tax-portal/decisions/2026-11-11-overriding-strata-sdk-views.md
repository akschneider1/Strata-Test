# Overriding Strata SDK views and helpers in the portal

- Status: proposed
- Date: 2026-11-11

## Context and Problem Statement

The portal builds on the Strata SDK (`strata` gem). Some SDK views and
helpers have text or layout the portal can't use as shipped: English words
fixed in the code (the step indicator's "Step … of …", the date field's
"Month / Day / Year" and month names), a work-queue row that shows a case ID
instead of the taxpayer, and a staff header with no sign-out. How should
the portal change SDK output without losing the ability to update the SDK?

The portal has four overrides today:

| What | How | File |
| --- | --- | --- |
| Staff header | Copied view | `app/views/strata/staff/_header.html.erb` |
| Step indicator | Copied view with words moved to locale keys | `app/views/strata/shared/_step_indicator.html.erb` |
| Date field labels and month names | Module prepended to `Strata::FormBuilder` that rewrites the SDK's HTML | `app/helpers/localized_memorable_date.rb` |
| Work-queue row | The SDK's own extension point (`task_row_component_class`) | `app/components/tax_return_task_row_component.rb` |

## Decision Drivers

- The SDK is pinned in `stack/versions.env` and will be updated. An override
  must not silently hide an SDK fix or break on a new SDK release.
- Spanish pages must be fully in Spanish.
- Other Strata apps in this repository would hit the same gaps.

## Considered Options

- Use an SDK extension point
- Copy the SDK view into the app
- Prepend a module that rewrites SDK output
- Fix it in the SDK and update the pin

## Decision Outcome

Chosen option: use them in this order of preference.

1. **An SDK extension point**, where one exists. It is the SDK's supported
   way to vary behavior and survives updates.
2. **Fix it in the SDK and update the pin**, for anything every Strata app
   would want (translations of fixed words are the clear case). Open the
   issue or pull request upstream even when a local override is also
   needed, and link it from the override.
3. **Copy the view**, as a stopgap, when the change is to markup. The copy
   starts with a comment saying what was changed and when to delete it.
4. **Rewrite SDK output in a prepended module**, only when the text comes
   from Ruby code with no view to copy, and only with a spec that fails if
   the SDK's output stops matching.

### Positive Consequences

- Each override says why it exists and when it can go.
- The spec on the date-field override
  (`spec/requests/tax_returns_spec.rb`, "shows the date fields and the step
  indicator in Spanish") fails if an SDK update changes the markup the
  override depends on, instead of the page quietly going back to English.

### Negative Consequences

- A copied view does not pick up SDK fixes. Someone has to compare it with
  the SDK's version on each SDK update.
- Upstream fixes take longer than local ones, so a stopgap can outlive its
  welcome.

## Pros and Cons of the Options

### Use an SDK extension point

- Good, because it is supported and survives updates.
- Bad, because few exist. Only the work-queue row had one.

### Copy the SDK view into the app

- Good, because it is plain Rails and easy to read.
- Bad, because the copy drifts from the SDK without anyone noticing.

### Prepend a module that rewrites SDK output

- Good, because it is small and keeps the SDK's markup.
- Bad, because it depends on the exact HTML the SDK emits. If that changes,
  the rewrite stops matching and the labels revert to English.

### Fix it in the SDK and update the pin

- Good, because every Strata app gets the fix and the override goes away.
- Bad, because it depends on the SDK maintainers' schedule.

## Follow-up

- Raise the fixed English words in the step indicator and the memorable
  date field with the SDK maintainers.
- When the SDK pin changes, compare the two copied views with the SDK's
  versions.
