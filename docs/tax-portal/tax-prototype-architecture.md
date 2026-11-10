# Tax prototype architecture

Two applications, both generated from Nava Strata templates with
`bin/new-app` and styled with the Colorado Design System.

```text
 Taxpayer (phone)          Examiner
       │                      │
       ▼                      ▼
 ┌──────────────────────────────────────┐        ┌────────────────────────┐
 │ tax-portal (Rails + Strata SDK)      │  HTTP  │ tax-engine (Flask)     │
 │  taxpayer portal   examiner portal   │ ─────▶ │  POST /v1/returns/     │
 │  interview flow    tasks, cases      │        │        calculate       │
 │  business process, audit log         │ ◀───── │  PolicyEngine US       │
 └──────────────────────────────────────┘ lines  └────────────────────────┘
                  │ Postgres
```

## tax-engine

`POST /v1/returns/calculate` takes what the taxpayer told us (people, ages,
filing status, income by type, withholding) and returns each line of the
Colorado return with the facts and the source behind it, plus the refund or
amount owed. `src/tax/calculator.py` is the only code that knows about
PolicyEngine; replacing it with another calculator would not change the API.
Responses include the engine name and version, which the portal stores with
every calculation.

## tax-portal

| Piece | Where | Strata SDK feature |
| --- | --- | --- |
| The return | `app/models/tax_return.rb` | `Strata::ApplicationForm`, Strata attributes |
| Interview | `app/flows/tax_return_flow.rb`, `app/views/tax_returns/edit_*` | Multi-page form flow, form builder |
| Filing status rules | `app/models/filing_status.rb` | |
| Prefill | `app/services/records_on_file.rb`, `WageRecord`, `IncomeDocument` | |
| Engine client | `app/services/tax_engine/` | |
| Processing | `app/business_processes/tax_return_business_process.rb`, `app/services/return_processing/` | `Strata::BusinessProcess`, events |
| Case | `app/models/tax_return_case.rb` | `Strata::Case` |
| Examiner queue | `app/controllers/tasks_controller.rb`, `ReviewTask` | `Strata::Task`, task views |
| Examiner review | `app/controllers/tax_return_cases_controller.rb` | Staff controller |
| History | `Strata::AuditLog` calls in `return_processing/` | Audit log |

### How a return is processed

```text
file_return ─submitted─▶ calculate_return ─▶ screen_return ─┬─cleared─▶ finalize_return ─▶ end
 (taxpayer)                 (system)           (system)     └─flagged─▶ review_return ─┬─approved──────────────▶ finalize_return
                                                                          (examiner)  └─information requested─▶ provide_information
                                                                              ▲                                    (taxpayer)
                                                                              └──────────── information provided ───────┘
```

Events are delivered synchronously, so a return with no flags is accepted
inside the taxpayer's submit request. If a step fails (for example the tax
engine is down), the submission is rolled back and the taxpayer is asked to
try again.

The automatic checks are in `app/services/return_processing/screen.rb`:
income lower or withholding higher than the payer reported, a record on file
the taxpayer disputes, withholding with no record on file, a dependent
claimed on another return, and a refund that is large for the income.

A filed return is never edited. An examiner's change is a
`ReturnAdjustment`; the case keeps both the filed and the adjusted
calculation.

### Data protection

- SSNs and bank account numbers use Active Record encryption
  (`config/initializers/active_record_encryption.rb`). Deployed environments
  must supply the keys as secrets.
- Pundit policies: taxpayers reach only their own return
  (`TaxReturnPolicy`); only examiners reach `/staff` (`StaffPolicy`).
- Amounts and personal data are not written to application logs or audit
  line data.
- Demo sign-in exists only when `DEMO_MODE=true` and never in production.

## Tests

| Command | Covers |
| --- | --- |
| `bin/new-app --verify tax-engine` | Four households through the real PolicyEngine rules; API routes |
| `bin/new-app --verify tax-portal` | Models, filing status, checks, workflow, both portals' requests (fake engine) |
| `bin/demo test` | Both apps together in a browser, with accessibility scans |
