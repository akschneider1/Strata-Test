# Lessons from IRS Direct File

Source: *The Life and Death of Direct File: A Leadership Case Study for High
Stakes Launches*, Merici Vinton with Melanie Girod and Omar Morales, UC
Berkeley Executive Fellowship in Applied Technology Policy, 2026. Page
numbers below refer to that report.

Read it knowing what it is. The lead author was Direct File's deputy and the
15 people interviewed backed the project. It is strong on how a team got a
launch through a large agency. It says little about why the service was shut
down, nothing from critics, and almost nothing about back-office processing
or fraud, which is half of this prototype.

## What happened, in brief

- The IRS launched a free, government-run filing service in January 2024.
  Over two filing seasons more than 400,000 people used it, and 94% rated it
  excellent or above average (p. 4).
- The 2024 pilot cost $24.6 million at the IRS plus $7.2 million at the U.S.
  Digital Service. 140,803 returns were accepted, against a target of
  100,000. The IRS estimated filers saved $5.6 million in preparation fees
  (pp. 22–23).
- In 2025 it covered 25 states and 296,531 accepted returns. The share of
  submissions accepted rose from 73.4% to 87.9% (p. 24).
- In March 2025 the team was told to stop work. The code was published as
  open source in May 2025, and Treasury later confirmed the shutdown (p. 25).

## Where the prototype already follows the report

| The report | This prototype |
| --- | --- |
| Build a prototype instead of writing a report. The IRS spent its $15 million study budget on a working prototype; the report calls this the "game-changing decision" (p. 11). | A working demo came first: `bin/demo`. |
| Show an experience good enough that it is "difficult for stakeholders to say no", not "an online PDF of the 1040" (p. 10). | A question-based interview that fills in the form. |
| Importing data the agency already holds was what taxpayers most wanted (pp. 21–22). | Income forms are prefilled from records on file; the taxpayer confirms or corrects them. |
| "Taxes are the product": accurate, secure, and quick to update when the law changes (p. 33). | All tax rules sit in `tax-engine` behind one small API. |
| Plain language in English and Spanish, built together (p. 18). | Both languages, same features. Spanish has not had a professional review. |
| Pick a realistic scope that still covers many filers (p. 13). | Common households only, stated in the docs. |
| Publish the code (p. 25). | This repository. |

## Where the prototype falls short

Each row names what the report did and what we would need to do.

| The report | Where we are | What it would take |
| --- | --- | --- |
| **Design with users.** 195 taxpayers took part in interviews and usability tests; research approval was cut from six weeks to 10 days (p. 14). | No taxpayer or examiner has used the prototype. | Run sessions with the [usability test kit](usability-test-kit.md). Needs participants and a way to recruit them. |
| **Deploy where it will run, early.** Direct File worked on the team's own cloud and then could not be deployed on IRS infrastructure; this nearly cancelled the launch (pp. 15–17). | It runs on a developer machine. The deploy workflows are installed but switched off, and the container scans report findings. | Deploy to the State's own environment (or the AWS `dev` environment as a first step) well before anything depends on it. Clear the scan findings first. |
| **Appoint a service owner.** One person accountable for the whole service who makes most daily decisions (p. 31), with executives who remove obstacles and give cover (pp. 27–28). | Nobody at the Department owns this. | A named owner at the Department and a named executive sponsor. |
| **Decide from data.** A team whose only job was to study usage and recommend fixes; one fix cut rejected returns by 25% (pp. 21, 33). | The examiner portal has a service measures page built from data the app already stores. Nothing tracks where taxpayers give up during the interview. | Decide what may be tracked during the interview, then add it. |
| **Join support to the product team.** Support agents sat with the product team and reported problems as they saw them; live chat served 10% of users (pp. 14, 22–23). | An examiner can ask a taxpayer a question about a filed return. There is no help for someone stuck before filing. | A support channel and a route from support staff to the people who change the product. |
| **Go beyond compliance on accessibility.** Tested with people who use assistive technology and with the American Council of the Blind (p. 33). | Automated checks on the main pages. | Sessions with people who use screen readers, magnification and voice control. |
| **Control the launch.** Four waves, starting with agency employees. The first filer hit a bug that was fixed before anyone else saw it (pp. 20–21, 33). | No way to limit who can file. | A switch to open filing to a named group, then in limited windows, then to everyone. |

## Lessons about lasting, not just launching

These are our reading of the report. The report does not state them as
lessons.

- **A service with no mandate has no protection.** Direct File was "not a
  Presidential campaign promise, nor mandated by Congress" (p. 4). A new
  administration ended it within months. Ask early what would give a
  Colorado service footing in statute or in the budget.
- **Do not rest the case on money saved.** The pilot cost about $32 million
  and saved filers an estimated $5.6 million (p. 23). The argument that
  carried it was satisfaction and trust: 86% of users said it raised their
  trust in the IRS (p. 7). Decide and write down what success means here
  before anyone asks.
- **Tell people it exists.** Outreach "had not been a priority until late
  into the tax season" (p. 22). In 2025, with mixed public messages about
  whether the service still existed, the share of users who said it raised
  their trust fell to 68% (p. 25).
- **Time lost before the decision is not recovered.** The decision to build
  took 18 months of memos (pp. 9, 26). The report's advice is to start small
  pilots early and change course often.
- **No surprises.** Engineers' warnings about deployment were slow to reach
  leadership, who kept telling the Commissioner the project was on track.
  Afterwards the team kept a "no-surprises" tracker, shared weekly (pp. 17,
  28).
- **The code is still there.** The IRS published Direct File so that states
  could "build from the platform if they so choose" (p. 25). We have not
  evaluated it for reuse. That is worth doing before building more.

## What the report cannot tell us

- How a state examines, adjusts and accepts returns after filing. That part
  of this prototype has no counterpart in the report.
- How Direct File handled fraud and identity.
- What critics of Direct File thought was wrong with it.
- Whether its results would hold at a state's scale and budget.
