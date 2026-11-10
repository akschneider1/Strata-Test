# How the prototype differs from Revenue Online

This compares the prototype with filing an individual income tax return
(form DR 0104) in Revenue Online (ROL).

> The ROL column is our understanding from public Department of Revenue
> material, not from a study of the system. **Confirm each row with
> Department staff before using this in a decision.**

| | Revenue Online (as we understand it) | This prototype |
| --- | --- | --- |
| How you enter the return | Fill in the lines of the form, copying numbers from your federal return and W-2s | Answer plain questions; the system fills in the form |
| Income forms | Typed in by the taxpayer | Prefilled from what employers and payers reported; the taxpayer confirms or corrects |
| Filing status and credits | Chosen and claimed by the taxpayer | Worked out from the answers and explained |
| Seeing the math | The completed form | Every step in plain language, with the source of each rule |
| Phone use | Desktop-oriented | Designed at phone width first |
| Languages | English | English and Spanish, same features |
| After filing | "Where's My Refund" lookup | Status page with a timeline; questions from an examiner are answered in the same place |
| Review | Handled in the Department's back-office system | Flag reasons, on-file comparison, recalculation and audit history on one page |
| Tax rules | Inside the vendor system | One service with a small API, using open-source rules, replaceable |

## Practices taken from IRS Direct File

Direct File's design guidelines and decision records are public. The
prototype applies these:

- **Do the hard work to make it easy.** Ask what people know (were you
  married on December 31?) and derive what they don't (filing status).
- **Simplify and automate.** Show the taxpayer the data the agency already
  has, with its source, and let them confirm or correct it.
- **Provide transparency.** Explain the calculation instead of hiding it.
- **Anticipate mistakes.** One question per page, specific error messages,
  a review page, and nothing lost if a step fails.
- **Content is the design.** Plain language, written for a phone.
- **Filing in other languages should be just as easy as in English.**
- **Beyond 508 compliance.** Automated accessibility checks run on the main
  pages as part of the walkthrough test.
- **Protect taxpayer data.** Sensitive fields encrypted, masked on screen,
  and kept out of URLs, logs and the audit trail.

## What a full replacement would still need

The prototype shows the shape of a replacement, not its full scope.

- **Scope of returns.** Part-year and nonresidents, self-employment and
  other income, itemized deductions, estimated payments, amended returns,
  the remaining credits and subtractions, prior years.
- **Certified calculation.** PolicyEngine is an open-source policy model,
  not certified tax software. A production system needs a calculation the
  Department has validated line by line; the engine sits behind one API so
  it can be swapped.
- **Federal data.** The prototype derives federal figures from the
  interview. A real system would import the federal return (for example
  through IRS Modernized e-File and the fed/state program).
- **Identity and accounts.** Identity proofing, account recovery, and
  filing on behalf of someone else (preparers, powers of attorney).
- **Payments and refunds.** Collecting balances due and issuing refunds
  through the State's financial systems.
- **Real records.** Connecting to actual employer withholding and
  information-return data, and to the Department's system of record.
- **Operations.** Fraud controls, correspondence, appeals, security
  authorization, load at filing deadline, and support.
- **Everything else ROL does.** Business taxes, licensing and other account
  types are untouched.
- **Research.** The questions and wording here are a first draft; Direct
  File tested theirs with taxpayers and tax counsel, and the Spanish needs
  professional review.
