# Demo guide: Colorado individual income tax prototype

A prototype of what could replace Revenue Online (ROL) for individual income
tax: a taxpayer filing portal, automatic processing, and an examiner portal.
Everything in it is made up. It can't file a real return.

## What the demo is for

It answers one question for people deciding what to do about ROL: **what
could filing and reviewing a Colorado return be like if the State built it
around the taxpayer?** The goal is for the legislature to be able to set
funding and write a bill for a full replacement with working software in
front of them, not a description of it.

It is not a cost estimate or a plan. The
[legislative brief](legislative-brief.md) sets out what a bill would need to
settle, and the [product audit](product-audit.md) lists what a decision
still lacks.

There are four audiences. Each has its own short path below:
[Department executives](#department-executives-three-minutes),
[program staff](#program-staff-ten-minutes),
[taxpayers](#taxpayers-hand-them-the-phone) and
[legislators and fiscal staff](#legislators-and-fiscal-staff-five-minutes).

Three things to make sure the audience sees. Everything else is detail.

1. **The State already has the forms.** The taxpayer checks their W-2
   instead of typing it.
2. **The system works it out and explains it.** No "choose your filing
   status", no hunting for credits, and every step of the math is shown.
3. **Review is fast and on the record.** Clean returns are accepted with no
   one touching them. A flagged return shows why, and every action is
   logged.

## Start it

On your own machine:

```bash
bin/setup-env --postgres
```

```bash
bin/demo
```

Open <http://localhost:3100>. For a hosted copy (Replit and others), see
[../hosting.md](../hosting.md).

## It is fresh every time

There is nothing to prepare. Each browser gets its own private copy of the
seven demo people the first time someone chooses a person. What one visitor
does never shows up for another, so you can hand out the link to a room and
everyone can file as Maya at once.

- A copy is erased after two hours without use. Open the demo the next day
  and it starts from the beginning.
- To start again sooner, for example between two meetings on the same
  laptop, choose **Start the demo over** on the home page, then **Reset the
  demo**. It resets your copy only.
- A private or incognito window always starts fresh.
- `bin/demo reset` (or `bin/serve --reset` on a host) discards everyone's
  copies.

## Before you present

- **Give it a minute after starting the server.** You can choose a person
  once the tax rules have loaded. The home page says so while you wait. On
  a hosted copy that has been asleep, the first click can take ten seconds.
- **Point people to "About this prototype"** on the home page if they are
  exploring without you. It says what is real and what is made up.
- **Use a narrow window or a phone for the taxpayer parts**, and a wide
  window for the examiner parts.
- **Run through it once.** `bin/demo test` runs the main path in a browser
  and tells you if anything is broken.

## The people

| Person | Starts as | Shows |
| --- | --- | --- |
| Maya Torres | Nothing filed | Filing from beginning to end on a phone |
| Daniela Ruiz | Everything answered, not yet signed | Filing status and family credits worked out for her; Spanish; the 2027 rates |
| Walter and Eleanor Bennett | Filed and accepted | Retirement income Colorado doesn't tax; the status page |
| Elena Park | Filed and accepted | Someone who owes tax; what the prototype doesn't do yet (payments) |
| Jordan Lee | Filed, waiting for review | A mismatch with employer records, settled with an examiner |
| Priya Shah | Examiner | The work queue and review tools |
| Marcus Reed | Second examiner | Confirming a large change |

## A path for each audience

### Department executives: three minutes

For someone with no time. Three stops, one per point above. What they need
to leave with: this is possible, it is not finished, and here is what it
would take to find out more.

1. **Continue as Maya**, **Start my return**, and work through to **Your
   income** (the two sections before it are short). Stop on the income
   page: her W-2 is already there. *"She didn't type
   that. Her employer already sent it to the State."*
2. Log out, **Continue as Daniela**, open **See how we calculated this**.
   *"Nobody asked her for a filing status or which credits to claim. It
   worked them out and says why."* Scroll once.
3. Log out, **Continue as Priya**, **Pick up next return**. *"This one was
   stopped because his numbers don't match his employer's. It says exactly
   why. The rest never reach a person."* Open **Service measures**.

### Program staff: ten minutes

Examiners, supervisors and the people who run ROL today. They will judge
the review side, and they know things we don't. Ask more than you tell.

1. Show stop 1 of the three-minute version briefly, so they see where
   returns come from.
2. Do all of [section 3 of the full script](#3-work-a-flagged-return-as-priya-wide-window):
   the work list, why a return was stopped, asking the taxpayer, changing
   an amount, the second examiner, the history.
3. Open **Service measures**.
4. Say what is missing for their work: letters, appeals, search, working
   many returns at once, and any connection to the system they use now.
5. Ask: What would stop you using this? Which checks do you run today that
   are not here? How often do employer records and returns disagree? Their
   answers correct [rol-comparison.md](rol-comparison.md) and the
   [review rate study](review-rate-study.md).

### Taxpayers: hand them the phone

Don't present. Open the demo on a phone, choose **Continue as Maya**, hand
it over and say: "This is a made-up person. Try to file her tax return. Say
what you are thinking as you go." Give them her birth date (March 14, 1996)
and Social Security number (`000-00-1001`) on a card. Then watch, and don't
help unless they are stuck for a minute.

The [usability test kit](usability-test-kit.md) has the full script,
consent wording and what to write down. Five people is enough to find the
main problems.

### Legislators and fiscal staff: five minutes

They are deciding whether to fund it and what the bill should say. Show
that it is real, show that it copes with a law change, and be exact about
what is not built.

1. **Continue as Maya** on a phone, through to **Your income**. *"The State
   already had her W-2. She checks it. She doesn't type it."*
2. Log out, **Continue as Daniela**, **See how we calculated this**. *"A
   single parent with two children. It found four credits for her and says
   why. She did not have to know they existed."*
3. On the same page, **See what the new rates would mean for you**.
   *"Voters approved new rates for 2027. They are already in here. A change
   in the law was a change to the rules, not a new system."*
4. Log out, **Continue as Elena**. *"She owes $950. It tells her what and
   when. It can't take her payment. That is not built."*
5. Open **About this prototype** from the home page and read the "made up
   or left out" list aloud. Then hand over the
   [legislative brief](legislative-brief.md).

Don't give a cost or a date. Nobody has estimated either, and the brief
says what an estimate needs.

## The full script (about ten minutes, untimed with a real audience)

### 1. File a return as Maya (narrow window or phone)

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
   rate, and a link to where each rule comes from.
6. **Refund or payment.** Direct deposit, routing `102000021`, any account
   number.
7. **Review and sign.** Type `Maya Torres`, submit. She gets a confirmation
   number at once. The return is calculated and checked in the background,
   and the status page updates on its own, usually within a few seconds, to
   **Accepted**, with a timeline.

In a scripted run this is 15 pages, 11 typed fields and about 30 taps. How
long it takes a real person has not been measured.

### 2. See what the system works out, as Daniela

1. **Continue as Daniela** and open **See how we calculated this**.
2. The top of the page has it all at a glance: the refund, the three
   totals behind it, her filing status and her credits. The steps below
   give the reason for each line.
   She was never asked for a filing status: the page says **Head of
   household** and why. Under credits she gets the Colorado Earned Income
   Tax Credit, Child Tax Credit, Family Affordability Tax Credit and Child
   Care Expenses Tax Credit, each with the reason. Refund **$7,162**.
3. At the bottom, open **See what the new rates would mean for you**.
   Colorado voters approved graduated rates starting with 2027 returns. The
   page shows her tax at the flat rate and at the new rates, bracket by
   bracket. The point for this audience: a law changed, and the rules
   engine already handles it. (The vote was not yet certified when this was
   written.)
4. Click **Español**: the whole taxpayer portal is available in Spanish.

### 3. Work a flagged return as Priya (wide window)

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
6. **Accept with adjustments.** Because the change moves the refund by $500
   or more, the return goes to a second examiner instead of closing.
7. Log out, **Continue as Marcus**, **Pick up next return**. He sees what
   Priya proposed and clicks **Confirm**. (He could send it back with a note
   instead. Priya can't confirm her own proposal.) The History section lists
   every step and who did it. Then open **Service measures**: how many
   returns needed no review, why the rest were flagged, how long decisions
   take, and what adjustments changed.
8. As Jordan again: his return is accepted, with the change and the reason.

### 4. Optional

- **Walter:** a return filed earlier and accepted automatically. The
  calculation shows the pension and Social Security subtraction bringing
  the income Colorado taxes to zero.
- **Elena:** a return with an amount due. The status page says what she
  owes and when, and that the prototype can't take payments yet. Use it to
  be upfront about what isn't built.

## Questions you will be asked

Answer these plainly. Each has a fuller answer in the linked page.

| Question | Short answer |
| --- | --- |
| Is the tax math right? | It uses PolicyEngine, an open-source model of tax law, and matches hand checks for the demo people. It is not certified tax software. The rules sit behind one interface so a certified calculator can replace it. |
| Where do the filled-in forms come from? | In the demo they are made up. For real they would come from the W-2 and 1099 filings the Department already receives. That connection is not built. |
| How many returns would need a person? | Unknown. A test with made-up households flagged 9%, but most of that came from our own assumptions. See [review-rate-study.md](review-rate-study.md). |
| How is this different from Revenue Online? | See [rol-comparison.md](rol-comparison.md). The ROL column is our understanding from public material and has not been confirmed with Department staff. |
| Has anyone tested it with taxpayers? | No. A script for doing so is in [usability-test-kit.md](usability-test-kit.md). |
| What would it cost, and how long would it take? | Nobody has estimated that. The [legislative brief](legislative-brief.md) lists what drives the cost and what the Department and OIT would need to supply. The IRS's first-year pilot of Direct File cost about $32 million; a state service would differ. |
| Can several people try it at once? | Yes. Each browser has its own copy of the demo people. |
| What happens to people it doesn't cover? | The start page says who can use it. Part-year residents and people with other kinds of income are told so and can't continue. |
| Can I pay what I owe? | Not in the prototype. |

## What is real and what is simulated

| Real in the prototype | Simulated |
| --- | --- |
| Tax calculation: PolicyEngine US applies 2025 federal and Colorado rules, and the 2027 graduated rates | Records on file: made up, standing in for employer W-2 and 1099 filings |
| The interview, validation, save and resume, English and Spanish | Sign-in: one click, standing in for identity proofing |
| Background processing, automatic checks, examiner tasks, second approval, audit log (Strata SDK) | Refunds and payments: nothing is paid or collected |
| Encryption of SSNs and bank numbers at rest; role-based access | Thresholds in the automatic checks, and refund timings: illustrative, not Department policy |

See [rol-comparison.md](./rol-comparison.md) for how this differs from ROL
and what a full replacement would still need, and
[tax-prototype-architecture.md](./tax-prototype-architecture.md) for how it
is built.
