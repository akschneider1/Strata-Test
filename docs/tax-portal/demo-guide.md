# Demo guide: Colorado individual income tax prototype

A prototype of what could replace Revenue Online (ROL) for individual income
tax: a taxpayer filing portal, automatic processing, and an examiner portal.
Everything in it is made up. It can't file a real return.

## Start it

```bash
bin/setup-env --postgres
```

```bash
bin/demo
```

Open <http://localhost:3100>. The home page lists the demo people; click one
to sign in as them. `bin/demo reset` (in a second terminal) puts the data back
to the starting point, and `bin/demo test` runs this whole script in a browser
automatically.

## The people

| Person | Starts as | Shows |
| --- | --- | --- |
| Maya Torres | Nothing filed | Filing from scratch on a phone; accepted in seconds |
| Daniela Ruiz | Everything answered, not yet signed | Filing status and family credits worked out for her; Spanish |
| Walter and Eleanor Bennett | Filed and accepted | Retirement income Colorado doesn't tax; the status page |
| Jordan Lee | Filed, waiting for review | A mismatch with employer records, resolved with an examiner |
| Priya Shah | Examiner | The work queue and review tools |

## Script (about 10 minutes)

### 1. File a return as Maya (use a narrow browser window or a phone)

1. **Continue as Maya**, then **Start my return**. Point out the checklist:
   four sections, save and resume, later sections locked until earlier ones
   are done.
2. **About you.** One question per page. Use birth date March 14, 1996 and
   SSN `000-00-1001`. Leave a field blank once to show the error message: it
   says what to do, next to the field.
3. **Your family.** Not married, no dependents. Note what isn't asked: there
   is no "choose your filing status" question.
4. **Your income.** Her W-2 from Front Range Outfitters is already there,
   marked "On file with the Department". She confirms it instead of typing
   it. Answer No to interest and other income.
5. Back on the checklist there is now an estimated refund of **$250**. Open
   **See how we calculated this**: every line in plain language, the 4.4%
   rate, and links to the page of the Colorado filing guide each rule comes
   from.
6. **Refund or payment.** Direct deposit, routing `102000021`, any account
   number.
7. **Review and sign.** Type `Maya Torres`, submit. The return is calculated,
   checked against records and **accepted within the same request**. The
   status page shows the confirmation number and a timeline.

### 2. See what the system works out, as Daniela

1. **Continue as Daniela** and open **See how we calculated this**.
2. She was never asked for a filing status: the page says **Head of
   household** and why. Under credits she gets the Colorado Earned Income
   Tax Credit, Child Tax Credit, Family Affordability Tax Credit and Child
   Care Expenses Tax Credit, each with the reason. Refund **$7,162**.
3. Click **Español**: the whole taxpayer portal is available in Spanish.

### 3. Work a flagged return as Priya

1. Log out, **Continue as Priya**. The dashboard shows what's waiting, what
   was accepted with no review, and the process every return follows.
2. **Pick up next return** opens Jordan Lee's. The page says why it was
   flagged (he claimed $3,900 of withholding; his employer reported $2,900)
   and shows reported and on-file amounts side by side.
3. Under **Ask the taxpayer**, send a question about the difference.
4. Log out, **Continue as Jordan**. His status page shows the question.
   Answer it.
5. Back as Priya, open the return from **My returns**. Under **Change an
   amount**, set Colorado tax withheld to `2900` with a reason. The return
   is recalculated: refund $1,705 becomes **$705**. The filed return is not
   edited; the change is recorded on top of it.
6. **Accept with adjustments.** The History section lists every step and who
   did it.
   Then open **Service measures**: how many returns needed no review, why
   the rest were flagged, how long decisions take, and what adjustments
   changed.
7. As Jordan again: his return is accepted, with the change and the reason.

### 4. Walter (optional)

Sign in as Walter to see a return that was filed earlier and accepted
automatically. The calculation shows the pension and Social Security
subtraction bringing Colorado taxable income to zero.

## What is real and what is simulated

| Real in the prototype | Simulated |
| --- | --- |
| Tax calculation: PolicyEngine US applies 2025 federal and Colorado rules | Records on file: seeded, standing in for employer W-2 and 1099 filings |
| The interview, validation, save and resume, English and Spanish | Sign-in: one click, standing in for identity proofing |
| Business process, automatic checks, examiner tasks, audit log (Strata SDK) | Refunds and payments: nothing is paid or collected |
| Encryption of SSNs and bank numbers at rest; role-based access | Thresholds in the automatic checks: illustrative, not Department policy |

See [rol-comparison.md](./rol-comparison.md) for how this differs from ROL
and what a full replacement would still need, and
[tax-prototype-architecture.md](./tax-prototype-architecture.md) for how it
is built.
