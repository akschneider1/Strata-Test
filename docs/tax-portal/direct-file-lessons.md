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
| **Deploy where it will run, early.** Direct File worked on the team's own cloud and then could not be deployed on IRS infrastructure; this nearly cancelled the launch (pp. 15–17). | It has still only run on a developer machine. The engine is now sized for what it needs, the portal is wired to it in the infra config, and [docs/hosting.md](../hosting.md) covers demo hosting elsewhere. None of that has been deployed. The container scans still report findings. | Deploy to the State's own environment (or the AWS `dev` environment as a first step) well before anything depends on it. Clear the scan findings first. |
| **Appoint a service owner.** One person accountable for the whole service who makes most daily decisions (p. 31), with executives who remove obstacles and give cover (pp. 27–28). | Nobody at the Department owns this. | A named owner at the Department and a named executive sponsor. |
| **Decide from data.** A team whose only job was to study usage and recommend fixes; one fix cut rejected returns by 25% (pp. 21, 33). | The examiner portal has a service measures page, and `bin/rails tax:review_rate` estimates how many returns the checks would flag (see [review-rate-study.md](review-rate-study.md)). Nothing tracks where taxpayers give up during the interview, and the study runs on made-up households. | Run the study on real return data. Decide what may be tracked during the interview, then add it. |
| **Join support to the product team.** Support agents sat with the product team and reported problems as they saw them; live chat served 10% of users (pp. 14, 22–23). | An examiner can ask a taxpayer a question about a filed return. There is no help for someone stuck before filing. | A support channel and a route from support staff to the people who change the product. |
| **Go beyond compliance on accessibility.** Tested with people who use assistive technology and with the American Council of the Blind (p. 33). | Automated checks on every taxpayer page at phone, tablet and desktop width, and an expert review of layout and wording ([ux-audit.md](ux-audit.md)). Still no testing with people. | Sessions with people who use screen readers, magnification and voice control. |
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
  could "build from the platform if they so choose" (p. 25). See the next
  section for what is in it.

## What is in the Direct File code

From a read of <https://github.com/IRS-Public/direct-file> (last commit June
2026). We read the code and documents; we did not build or run it.

Know these first:

- It is public domain (CC0), so anything in it can be copied.
- The repository is archived. Its README says the code "may contain
  unpatched or unknown vulnerabilities" and "should not be used in
  production systems".
- It covers federal returns for tax year 2024. This prototype is a Colorado
  return for tax year 2025.
- Code touching taxpayer data or sensitive systems was removed before
  publication, so some parts are incomplete.
- It is a Java and Scala backend with a React client. This prototype is
  Rails and Python.

| Part | What it is | Use for us |
| --- | --- | --- |
| Design documents (`docs/design/`) | The content style guide (about 1,000 lines, with an A–Z word list), design guidelines, taxpayer research findings, and moderation guides for research sessions | **Use now.** Check our wording against the style guide and word list. Their moderation guides are fuller than our [usability test kit](usability-test-kit.md). |
| Spanish text (`df-client-app/src/locales/es.yaml`) | About 27,000 lines of Spanish reviewed for a live tax service | **Use now.** A reference for tax terms in Spanish until ours is professionally reviewed. |
| Tax rules (`backend/src/main/resources/tax/`) | About 3,000 facts in 36 XML files: filing status, dependents, standard deduction, Social Security, earned income and child credits, child care credit, written with IRS Chief Counsel | **Use as a reference.** Our filing status and dependent rules are simplified and say so. Theirs are the full federal tests. Good source for the questions we would need to ask. |
| Test scenarios (`docs/testing/`, backend test resources) | Worked households with expected results, and a written testing strategy built around the facts that decide eligibility | **Use as a reference** for our own test households and edge cases (for example, a taxpayer born on January 1). |
| Fact Graph (`fact-graph-scala/`) | A rules engine that reasons over a partly finished return, running on both server and browser. About 30,000 lines of Scala | **Not now.** It solves a real problem we have (what to ask next, what is still missing), but adopting it means taking on an unmaintained Scala codebase. Revisit if the interview outgrows the Strata flow. |
| State API (`state-api/`) | How a finished federal return was handed to a state's own filing tool, with the taxpayer's consent | **Study the data format.** The federal service behind it is gone, so there is nothing to connect to. The export format shows what states asked for from a federal return, which is what our federal figures would need to cover. |
| Data import design (`docs/adr/data-import-system.md`) | How they planned to fetch records the IRS already holds: one hub, one module per source system, a short timeout so the taxpayer never waits | **Use as a reference** when connecting our records-on-file service to real Department data. |
| Decision records (`docs/adr/`) | Accessibility targets and methods, encryption of taxpayer data, error messages, resubmission | **Use as a reference** for the same decisions here. |

Nothing in it covers a state examiner's work, so the review half of this
prototype has no counterpart there either.

## What the report cannot tell us

- How a state examines, adjusts and accepts returns after filing. That part
  of this prototype has no counterpart in the report.
- How Direct File handled fraud and identity.
- What critics of Direct File thought was wrong with it.
- Whether its results would hold at a state's scale and budget.
