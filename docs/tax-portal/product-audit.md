# Product audit of the demo

November 2026. The [UX audit](ux-audit.md) asked whether the pages work.
This asks a different question: **does the demo do its job?** Its job is to
show people deciding what to do about Revenue Online (ROL) what a
replacement could be like, well enough that they can decide what to do
next.

## How it was done

- Followed the demo guide step by step in a browser and noted every place
  the guide and the app disagreed.
- Checked each claim the demo and its documents make against what the
  prototype does.
- Listed the situations a taxpayer or examiner can be in and tried each one.
- Read the documents as a decision-maker would, looking for what they would
  ask next and whether there is an answer.

This is one reviewer's assessment. No decision-maker, taxpayer or examiner
has been asked.

## Verdict

The demo shows three things well: forms already filled in, the system
working out status and credits and explaining them, and review that is fast
and on the record. Those are the right three things.

It was weaker as a product than as software. It did not say who it was for
or what it wanted from them. As a shared, hosted demo it broke after one
use. Every demo person got a refund. And the documents answer "how is it
built" better than "what should we do now".

The first four of those are fixed in this pass. The last needs decisions
that are not ours to make.

## Scorecard

| Area | Before | Now | Notes |
| --- | --- | --- | --- |
| Says who it is for and what it shows | Missing | Fixed | The guide now opens with the question the demo answers and the three points to land. |
| Shows clear value | Strong | Strong | Prefill, "tell, don't ask" and the explained calculation are visible within a minute. |
| Has a story, not a feature tour | Weak | Better | Added a three-minute version with one stop per point. The ten-minute script is still a tour. |
| Guide matches the app | 3 mismatches | Fixed | A missing person, stale wording about processing, and no mention of the 2027 rates page. |
| Survives being shared | Broken | Fixed | See "The demo used itself up" below. |
| Covers the situations people are in | Partial | Partial | See the coverage table. An amount-due case is now shown. |
| Honest about limits | Good | Good | Prototype banner on every page; unmeasured promises were removed in the UX pass. |
| Has evidence it works for people | None | None | Nobody outside the project has used it. |
| Ready to support a decision | Weak | Weak | No owner, success measures, pilot definition, cost or timeline. |

## What was wrong and what changed

### The demo used itself up

Once one visitor filed as Maya, the next visitor found Maya already filed.
Once one visitor settled Jordan's return, there was nothing left to review.
On a laptop the presenter could reset from a terminal. On a hosted copy
(the plan for Replit) nobody could, so the demo worked properly for exactly
one visitor.

**Fixed.** The home page has **Start the demo over**, which puts every
person back to the start in about two seconds. "How the demo works" now
says that what you do stays until someone resets it.

Still true: two people using a shared copy at once will get in each other's
way. A reset by one interrupts the other. Separate copies per visitor would
fix that and is not built.

### Everyone got a refund

All four demo taxpayers were due money. Owing tax is common, and "how do I
pay?" is one of the first questions anyone asks about a tax system.

**Fixed, as far as showing it.** A new demo person, Elena Park, owes $950.
Her status page says what she owes, when it is due, and that the prototype
can't take payments yet. Paying is still not built.

### The guide and the app disagreed

Running the guide as written found three mismatches:

- It listed five people; the home page has more (Marcus, and now Elena).
- It said a return is "accepted within the same request". Filing now
  returns a confirmation at once and the return is processed in the
  background.
- It never mentioned the 2027 rates page, which is the most timely thing in
  the demo: a law changed, and the rules engine already handles it.

**Fixed** in [demo-guide.md](demo-guide.md), which also gained a
"before you present" list and plain answers to the questions an audience
will ask.

## Coverage: situations people are in

| Situation | In the demo? |
| --- | --- |
| Single filer, wages only, refund | Yes (Maya) |
| Family with children and credits | Yes (Daniela) |
| Married couple, retirement income | Yes (Walter and Eleanor) |
| Owes tax | Shown (Elena); can't pay |
| Numbers don't match the employer's | Yes (Jordan) |
| Return is not accepted | The examiner can do it; no demo person shows it, and the taxpayer can't fix and refile |
| Files in Spanish | Yes, taxpayer side only |
| Part-year resident, self-employed, other income | Told up front they can't use it |
| Needs to change a return after filing | No |
| Someone else files for them (preparer, family member) | No |
| Has no Social Security number | No |
| Proving who you are | No (one-click sign-in stands in) |
| Examiner: review, ask, adjust, second approval | Yes |
| Examiner: letters, appeals, search, working many returns at once | No |

## What we can show a number for

| Measure | Value | How solid |
| --- | --- | --- |
| Effort to file the simplest return | 15 pages, 11 typed fields, about 30 taps | Counted by a script. No time measured with a person |
| Share of returns needing a person | 9.3% of 1,200 made-up returns | Weak: mostly our own assumptions ([study](review-rate-study.md)) |
| Reading level of the English text | Grade 5.3 | Formula only ([UX audit](ux-audit.md)) |
| Time from filing to acceptance, clean return | A second or two in the demo | One machine, one user |
| Taxpayer satisfaction, completion rate, errors | None | Needs real users |

Direct File's case rested on satisfaction and trust figures from real
filers. We have nothing comparable, and nothing in the prototype can
produce it.

## Questions a decision-maker will ask

| Question | Can we answer today? |
| --- | --- |
| Is the math right? | Partly. It matches hand checks; it is not certified. |
| How is this better than ROL? | Not reliably. The comparison has not been checked with Department staff. |
| Will taxpayers be able to use it? | No evidence either way. |
| How many staff would review need? | No. It depends on the review rate, which needs real data. |
| What does it cost and how long does it take? | No. Nobody has estimated either. |
| Who would own it? | No one is named. |
| Does the State have the authority and the data? | Not looked at. |
| What is the smallest useful first step? | Not defined. See below. |

## Recommended next steps

These are this reviewer's recommendations, in order. None has been agreed.

1. **Name who the demo is for and what you want from them.** A go-ahead for
   user testing is a different ask from a budget request, and the demo
   should be told differently for each.
2. **Check the ROL comparison with Department staff.** Until then the
   "better than ROL" claim is our reading of public material.
3. **Run five sessions with real taxpayers**, using the
   [test kit](usability-test-kit.md). It is the cheapest evidence available
   and the thing the demo most obviously lacks.
4. **Define a pilot, on paper.** Who it would serve, how many, for which tax
   year, and what result would count as success. Direct File started with
   a deliberately narrow scope and a target it could beat. Suggested
   measures to choose from: share who finish, time to file, share accepted
   with no review, time to a decision for reviewed returns, and whether
   filers say it was easy.
5. **Get data to size review.** A sample of past returns and the
   Department's own match rates for employer forms would turn the review
   rate from a guess into an estimate.
6. **Redesign the large-refund check before any pilot.** In the study it
   flagged families with children at about three times the rate of others.

## What this audit can't tell you

Whether the audience finds the demo convincing. That takes showing it to
them and listening to what they ask.
