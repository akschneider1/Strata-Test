# UX audit of the taxpayer portal

November 2026. Covers everything a taxpayer sees: the home page, the
interview, "How we calculated this", the 2027 rates page, review and sign,
and the status page, in English and Spanish. The examiner portal was not
part of this audit; a later pass covered it (see
[Follow-up review](#follow-up-review-11-november-2026)).

This is an expert review plus automated checks. **Nobody outside the project
has used the portal yet.** The findings below are what a reviewer and a
script can see. Whether people understand the questions is a different test;
see [What this audit can't tell you](#what-this-audit-cant-tell-you).

## How it was done

- Every page was opened at three widths: phone (390 px), tablet (768 px) and
  desktop (1280 px), in both languages, as four demo people. That is 150
  page captures, before and after the fixes.
- A script checked each capture for sideways scrolling, text cut off or
  pushed off screen, heading order, tap targets smaller than 44 px, form
  fields that make phones zoom in, and accessibility rules (axe, WCAG 2.1 A
  and AA plus best practices).
- A reviewer looked at the screenshots and read every string against the
  Direct File content style guide.
- Reading level was measured with the Flesch-Kincaid grade formula on the
  English text. It is a rough guide: names such as "Social Security" push
  the number up without being hard to read.

## Results at a glance

| Check | Before | After |
| --- | ---: | ---: |
| Pages with sideways scrolling | 0 | 0 |
| Accessibility rule violations | 0 | 0 |
| Headings out of order | 0 | 0 |
| Text cut off or off screen | 0 | 0 |
| Form fields that zoom on phones | 0 | 0 |
| Tap targets under 44 px, phone and tablet captures | 608 | 281 |
| Reading grade of the running text | 5.9 | 5.3 |
| Strings at grade 9 or above | 16 | 10 |
| Strings at grade 12 or above | 8 | 1 |

The one string still at grade 12 is the legal declaration above the
signature, which is kept word for word and now has a plain sentence before
it.

## What was wrong and what changed

### Serious: would stop or mislead someone

| Finding | Where | Fix |
| --- | --- | --- |
| The home page promised things nobody has measured: "It takes most people about 15 minutes" and "Most returns are accepted in minutes". | Home, start page | Removed. |
| On a phone, the demo people were three screens down, below a long introduction in very large type. | Home, phone | The demo comes first. The introduction is shorter and in normal type. |
| No instructions: nothing said what happens after you pick a person, how to switch, or that nothing is sent to the Department. | Home | Added "How the demo works", three short steps. |
| After a fresh start the home page showed no demo people for about a minute, with no explanation. | Home | A notice says the demo is getting ready, and the page updates on its own. |
| "Sign in" led to a form that creates an empty account with no return. A dead end in a demo. | Home | Not shown in a demo. |
| On desktop the demo cards were narrow, and every button wrapped onto two lines. | Home, desktop | One row per person: name and description, with the button beside it on wide screens and below it on phones. |
| In Spanish on desktop, "Sesión iniciada como…" ran into the site title. | Header | The name sits next to "Log out"; "Signed in as" is kept for screen readers. |
| A dependent credit explanation read "You have 1 and your income is within the limit." | Calculation page | Now "Children under 6 on your return: 1." |

### Moderate: slows people down

| Finding | Where | Fix |
| --- | --- | --- |
| Demo people were in alphabetical order, not the order of the story. | Home | Maya, Daniela, Walter, Jordan, then Priya and Marcus. |
| Demo descriptions used tax shorthand ("one W-2", "withholding", "the automatic checks flag"). | Home | Each now says who the person is and what you will see. |
| Buttons and form fields were 40 px tall on phones, under the 44 px a thumb needs. | Every form | 44 px below desktop width, in the shared design-system fixes so every app gets it. |
| Stand-alone links ("Review or change", "Change", "See how we calculated this") were 18 to 22 px tall. | Checklist, review, status | More padding around them. |
| "Can't start yet" wrapped onto two lines on a phone and squeezed the section heading. | Checklist, phone | Shorter tag ("Not ready yet") that stays on one line, with "Finish the sections above first." under it. |
| The menu button said "MENU" on Spanish pages. | Header | Translated. |
| Dates were written three ways, one with a leading zero and one in 24-hour time, and none named the time zone. | Review, status | One format: "November 9, 2026 at 10:06 PM, Mountain time"; a shorter one in the timeline. Spanish dates use Spanish month names. |
| Every credit carried a long link, "Where this rule comes from: 2025 Colorado Individual Income Tax Filing Guide (104 Book): Refundable credits", five times over. | Calculation page | The link reads "Where this rule comes from". The full source is in its tooltip and read out to screen readers. |
| Two wordings for one thing: "Colorado tax withheld" and "Colorado tax already taken out of your pay". | Income, calculation, review | "Colorado tax withheld" everywhere, explained once where it first appears: tax already taken out of your pay or benefits. |

### Plain language

| Before | After |
| --- | --- |
| Federal adjusted gross income | Income after federal adjustments (the official name is in the explanation) |
| Federal taxable income | Income the federal government taxes |
| Colorado additions | Income Colorado adds back |
| Total Colorado subtractions | Total income Colorado doesn't tax |
| Colorado taxable income | Income Colorado taxes |
| State sales tax refund (TABOR) | State sales tax refund ("often called the TABOR refund" in the explanation) |
| Your tax before refundable credits | Your tax after those credits |
| Birth date and SSN | Birth date and Social Security number |
| Residency | Where you lived |
| Enter this to continue | Enter an answer to continue |
| - Select - | Choose one |
| Because your numbers differ from what the payer reported, someone at the Department may review your return before it's accepted. | Your numbers are different from what the payer reported. A person at the Department may check your return before it is accepted. |

The signature step now starts with: "By signing, you are saying that
everything on this return is true and complete, as far as you know. The
legal wording is:" followed by the declaration, unchanged.

Every English change has a matching Spanish change.

## Left as it is, and why

| Finding | Why it stays |
| --- | --- |
| 281 tap targets are still under 44 px on phone and tablet captures. About 200 of them are the same two things on every page: the site title link and the "Skip to main content" link (42 px). The rest are text links at 42 px and a few plain radio buttons. | All are above the 24 px that WCAG 2.2 AA requires. Making the title and skip link taller means changing the design system's header. |
| Names on the income and dependent cards are blue, which can look like links. | That is the Colorado Design System's card heading style. It should be raised with the design system, not overridden in one app. |
| On desktop the content sits in a column on the left with space on the right. | It keeps lines to a readable length. |
| "Allow 7 to 10 days" and "3 to 4 weeks" for refunds. | These are placeholders in a prototype; a real service would use the Department's own figures. They should not be read as commitments. |
| The legal declaration reads at grade 13. | It is legal text. It now has a plain sentence before it. |
| A return that isn't accepted is a dead end. | The message now says so plainly. Reopening a return is a feature, not a wording fix. |

## Follow-up review, 11 November 2026

A second pass walked the demo as an executive would, including the examiner
portal, which the audit above did not cover. What changed is described in
[design-comparison.md](design-comparison.md) and the
[demo guide](demo-guide.md). Checks after that pass:

| Check | Result |
| --- | --- |
| Accessibility rules (axe, WCAG 2.1 A and AA plus best practices) on 28 page states: home, about, the interview with its error states, calculation, 2027 rates, review, three status pages, and six examiner pages | 0 violations |
| Headings out of order, or more than one page title | 0 |
| Sideways scrolling at 640 px (the same as 200% zoom on a laptop) | Only the examiner work queue, by 139 px. Its table comes from the Strata SDK. |
| Links and buttons under 24 px tall | Breadcrumb links in the title band, "Back to checklist", and text links in examiner lists. WCAG 2.1 AA sets no minimum; 2.2 AA asks for 24 px. |
| Spanish pages with English words | None on the pages checked. The step indicator and date fields are now translated. |

Still open from that pass: the examiner work queue's width and table style,
the step indicator repeating the section name on desktop, and a blank
Social Security number showing its error only after the birth date is
fixed. All three come from the Strata SDK; see
[decisions/2026-11-11-overriding-strata-sdk-views.md](decisions/2026-11-11-overriding-strata-sdk-views.md).

## What this audit can't tell you

- Whether taxpayers understand the questions and trust the filled-in forms.
  That takes sessions with real people; the script is in
  [usability-test-kit.md](usability-test-kit.md).
- Whether the portal works with a screen reader, magnification or voice
  control in practice. The automated rules pass, which is a floor, not a
  finding.
- Whether the Spanish reads naturally to Spanish speakers in Colorado. It
  has not had a professional review.
- How it behaves on real phones and slow connections. The checks ran in a
  desktop browser set to phone and tablet sizes.

## Repeating the checks

`bin/demo test` runs the browser walkthrough with accessibility scans on the
main pages. The fuller crawl used for this audit (every page, three widths,
two languages) was a one-off script and is not in the repository.
