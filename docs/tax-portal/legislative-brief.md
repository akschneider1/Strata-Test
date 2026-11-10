# Brief for legislators and fiscal staff

**Replacing Revenue Online for individual income tax: what working software
shows, and what a funding bill would need to settle**

November 2026. Written by the team that built the prototype. It has not
been reviewed by the Department of Revenue, the Office of Information
Technology or legislative staff, and it is not legal or fiscal advice.

## In one page

- There is a working prototype of a replacement for Revenue Online (ROL)
  for individual income tax. You can use it: a taxpayer files a return on a
  phone, the system processes it, and Department staff review the returns
  that need a person. Everyone in it is made up.
- It shows three things. The State can fill in a taxpayer's income forms
  from what employers already report. The system can work out filing status
  and credits and explain the math. Review can be fast, with every action
  on the record.
- It also shows that a change in the law can be absorbed quickly. The
  graduated rates voters approved for 2027 are already in it.
- It is not a system the State could switch on. The list of what is missing
  is in this brief, and it is long.
- **The ask is to fund a full replacement.** This brief does not contain a
  cost. Nobody has estimated one, and the inputs that decide it belong to
  the Department and OIT. What it does contain is what drives the cost, the
  figures measured so far, and the questions a bill would need to answer.

## What the working software shows

Each of these can be seen in the demo in a few minutes. The
[demo guide](demo-guide.md) has a five-minute path for legislators.

| Claim | What you can see |
| --- | --- |
| Taxpayers don't have to retype what the State already has | A W-2 already on the return, marked as on file. The taxpayer confirms it. |
| The system can do the work the form leaves to the taxpayer | A single parent is never asked for a filing status or which credits to claim. The system works out four credits and says why. |
| The math can be shown | Every step in plain language, with a link to the rule it comes from. |
| It works on a phone, in English and Spanish | The whole taxpayer side, same features in both languages. |
| Clean returns need no staff time | Returns with nothing to check are accepted in seconds. |
| Review has controls | Staff see why a return was stopped. A change of $500 or more needs a second person. Every action is logged with who took it. |
| A law change is a rules change | The 2027 graduated rates, bracket by bracket, for one household. |

## What it does not show

These are limits of the evidence, not of the idea.

- **That taxpayers can use it.** Nobody outside the project has tried it.
- **That the math is certified.** The calculations come from PolicyEngine,
  an open-source model of tax law. They match hand checks for the demo
  households. The Department has not validated them.
- **That it is better than ROL.** Our comparison is drawn from public
  material and has not been checked with Department staff.
- **How many returns would need a person.** In a test with 1,200 made-up
  households, 9.3% were stopped for review. Most of that number comes from
  our own assumptions about how often employer records and returns
  disagree. See the [review rate study](review-rate-study.md).
- **That it runs in the State's environment.** It has run on a developer's
  machine and on a demo host. It has not been deployed on State systems or
  through a security authorization.

## What a full replacement includes beyond the prototype

From [rol-comparison.md](rol-comparison.md), in plain terms:

- **More kinds of returns.** Part-year residents and nonresidents,
  self-employment, itemized deductions, estimated payments, amended
  returns, prior years, and the credits and subtractions not yet covered.
- **A calculation the Department has validated**, line by line.
- **The federal return.** Bringing in federal figures instead of working
  them out from questions.
- **Proving who someone is**, recovering an account, and filing on someone
  else's behalf (preparers, powers of attorney).
- **Money.** Taking payments and issuing refunds through the State's
  financial systems.
- **Real records.** A connection to employer wage and withholding filings
  and to the Department's system of record.
- **Operations.** Fraud controls, letters, appeals, support, security
  authorization, and capacity for the filing deadline.
- **Everything else ROL does.** Business taxes, licensing and other account
  types are untouched by the prototype. "Full replacement" needs a decision
  on whether these are in scope. They are most of what ROL does.

## What drives the cost

No dollar figure is given here. These are the things an estimate would be
built from. The first table is what we have measured. The second is what
only the Department and OIT can supply.

### Measured in the prototype

| Figure | Value | How solid |
| --- | --- | --- |
| Computing needed for the tax calculation | One process handles a little over one new calculation a second, about 4,000 an hour. Each process needs 1 CPU and about 4 GB of memory. | Measured on one machine. Capacity grows by adding processes. |
| Share of returns a person must look at | 9.3% of 1,200 made-up returns | Weak. Mostly our own assumptions. This is the largest driver of staffing and the least known. |
| Effort to file the simplest return | 15 pages, 11 typed fields | Counted by a script. Not timed with people. |
| Reading level of the taxpayer text | About 5th grade | Formula only. |

Computing is unlikely to be what decides the cost. People are: the team
that builds and runs the service, and the staff who review returns.

### Needed from the Department and OIT

- How many individual returns are filed each year, how many through ROL,
  and how they arrive at the deadline.
- What the State pays now for ROL and the systems behind it, and when those
  contracts end or renew.
- How many returns staff review today, and how often employer records and
  returns disagree. This turns the review rate from a guess into an
  estimate.
- Whether the replacement must connect to the current system of record or
  replace it.
- Whether business taxes and other account types are in scope.
- The State's requirements for security authorization, hosting and identity
  proofing, and what each costs to meet.
- Whether the work would be done by State staff, vendors, or both.

One outside reference point, with caution: the IRS spent about $32 million
on the first-year pilot of Direct File, which accepted about 141,000
returns in 12 states. A state service differs in scope, scale and what it
can reuse, including Direct File's own published code. It is a reference,
not an estimate. See [direct-file-lessons.md](direct-file-lessons.md).

## Questions a bill would need to settle

These are questions for bill drafters and the Department's counsel. We have
not researched current law on any of them.

1. **Authority to use employer filings.** May the Department use the wage
   and withholding reports it already receives to fill in a taxpayer's
   return and show them to that taxpayer? If the law is silent, should the
   bill say so?
2. **One-time and ongoing money.** Building the service is one cost.
   Running it, and updating it every year the law changes, is another.
   Direct File had money to build and no settled funding to continue.
3. **Scope.** Individual income tax only, or all of ROL? In stages?
4. **A staged start.** Should the bill require a limited first season, with
   a set group of taxpayers, before the service opens to everyone? Direct
   File began with 12 states and a narrow set of returns and widened from
   there.
5. **What must be reported back, and when.** For example: how many people
   finished, how long it took, how many returns needed review, how long a
   decision took, and what filers said about it. Naming the measures in the
   bill is what lets a later legislature judge the result.
6. **Who is accountable.** A named owner in the Department for the whole
   service, not only for the contract.
7. **The current contract.** How the transition relates to the existing ROL
   agreement, and how long both would run together.
8. **Language and accessibility.** Whether Spanish, and accessibility
   beyond the legal minimum, are requirements of the service from the
   first day.
9. **Openness.** Whether the code and the tax rules in it must be public,
   as Direct File's were.
10. **Free to use.** Whether the bill guarantees taxpayers can file at no
    charge.

## What Direct File's history suggests

Drawn from a 2026 case study by members of the Direct File team. They were
supporters of the project, and the study should be read that way.

- **A service that is not in law has no protection.** Direct File was "not
  a Presidential campaign promise, nor mandated by Congress". It was shut
  down within months of a change of administration, with high satisfaction
  scores. A mandate in statute and money in the base budget are what it
  lacked.
- **Don't rest the case on money saved.** The pilot cost about $32 million
  and saved filers an estimated $5.6 million in fees. What carried it was
  that 94% of users rated it highly and most said it raised their trust in
  the agency. Decide what success means and write it down.
- **Working software moved the decision; memos did not.** The IRS spent 18
  months on whether to build. A prototype settled it.
- **Start small and widen.** The first users were agency employees. The
  first filer hit a bug that was fixed before anyone else saw it.
- **Deploy in the real environment early.** Direct File worked on the
  team's own systems and then nearly failed to launch on the agency's.

## What we suggest happens next

In order. None of this has been agreed with anyone.

1. Show the demo to Department leadership and program staff, and correct
   what this brief gets wrong about ROL.
2. Ask the Department and OIT for the inputs listed above. With them, a
   fiscal note becomes possible.
3. Put the prototype in front of five to ten taxpayers. A script is in the
   [usability test kit](usability-test-kit.md).
4. Decide scope: individual income tax first, or all of ROL.
5. Draft the bill around the ten questions above.

## Where to look

- The demo itself, and [how to show it](demo-guide.md).
- [What the prototype lacks](product-audit.md), stated plainly.
- [How it differs from ROL](rol-comparison.md).
- [How it is built](tax-prototype-architecture.md).
