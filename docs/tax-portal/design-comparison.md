# How the prototype's look compares with tax.colorado.gov

November 2026. The goal: someone who goes from tax.colorado.gov into the
prototype should feel they are still in the same place. The target is the
current tax.colorado.gov. Nothing is taken from the look of Revenue Online.

## What we compared, and how

- We read the published HTML and stylesheet of tax.colorado.gov (the home
  page and the Individual Income Tax page) and took its fonts, colors,
  sizes and page structure from them.
- **We have not seen it in a browser.** The site's bot check blocked an
  automated browser and we did not work around it. So there are no
  side-by-side screenshots, and nothing here has been checked by eye
  against the live site. A person should do that before this is called
  done.
- The prototype's values come from its own stylesheet and from screenshots
  of every taxpayer page at phone, tablet and desktop width.

## The short version

tax.colorado.gov and the Colorado Design System (CoDS) are the same family.
The site is built on USWDS, as CoDS is, with the same fonts and the same
blues, and it uses components CoDS also ships (hero, card, breadcrumbs).
Most of the gap was the prototype not using what CoDS already had.

## What matches

| | tax.colorado.gov | Prototype |
| --- | --- | --- |
| Body font | Open Sans | Open Sans |
| Page title font | Museo Slab, weight 500 | Museo Slab, weight 500 |
| Page title size | 2.28rem on phones, 3.04rem on desktop | 36px and 48px (the same sizes) |
| Other headings | Open Sans, weight 600 | Open Sans, weight 600 |
| Primary color | `#001970` | `#001970` |
| Title band | Dark blue `#001049`, white title, breadcrumb above it | The same, using the CoDS hero |
| Buttons | `#001970`, white bold text, 4px corners | The same |
| Outline buttons | 2px `#001970` outline, clear background | The same |
| Links in text | `#001970`, underlined | `#001970`, underlined |
| Header | White, soft shadow underneath | The same |
| Page width | 75rem | 75rem |
| Footer | "Return to top", link columns, a line of notices | The same layout |
| Tags | 2px corners | 2px corners |

## What differs, and why

| | tax.colorado.gov | Prototype | Why |
| --- | --- | --- | --- |
| Logo | Department of Revenue logo | The service name in text | The prototype is not a Department service. Using the logo would make it look like one. If the Department agrees, it is a small change. |
| Top banner | Department notices (office closures) | "Prototype: this is a demonstration" | It must be clear this can't file a real return. |
| Text boxes and dropdowns | Square corners (plain USWDS) | 4px corners (the CoDS field) | The site has almost no forms beyond search. CoDS is the State's system for forms, so the prototype follows it. Switching to square is a one-line change. |
| Cards | 8px corners, heavier shadow, no border | 4px corners, lighter shadow, thin border (the CoDS card) | CoDS card. Close, not identical. |
| Section headings | 2.03rem to 2.54rem | 28px to 32px (one step smaller) | The prototype's pages are forms and short lists. The site's size is tuned for landing pages and crowded a phone screen. |
| Navigation | Menus for individuals, businesses, forms | Language and log out only | The prototype does one thing. |
| Search, language menu with ten languages | Yes | No search; English and Spanish | Not built. |
| Footer links | The Department's full set | Four links to tax.colorado.gov and the About page | The rest would point to pages about services the prototype doesn't offer. |
| Footer notices | Copyright, accessibility, privacy | "This is a prototype. It is not a State of Colorado website." | Linking the State's privacy notice would suggest it applies here. |
| Examiner portal | No counterpart | Same header, fields and footer; denser headings | Staff tool. |

## What was wrong before, and the fix

**Text boxes looked cut off and thin.** CoDS styles a field only when the
markup carries its own classes. The Strata form builder writes plain USWDS
classes, so fields got the bare USWDS look, and widths did not agree: a
dropdown ran the full width while the text boxes above it stopped short.
Plain fields now get the CoDS field look, at 44px tall, and wide text boxes
line up with dropdowns. Short fields (ZIP code, dates, Social Security
number) stay short on purpose: width tells people how much to type.

**The progress steps wrapped oddly.** CoDS has no step indicator, so the
USWDS one was unstyled. "of 4" dropped under the circle on some pages and
sat beside it on others. It now has one layout at every width, rounded
segments with a gap between them, and CoDS colors. A section with a single
page no longer shows a one-step progress bar.

**Names on cards looked like links.** CoDS colors every card heading as a
link. Cards that are not links now have plain headings.

All of these are in `stack/cods/_cods-compat.scss`, so every app in this
repository gets them. They are gaps to raise with the CoDS team: plain
USWDS field markup, a step indicator, a header and a footer.

## Checks run

- 150 page captures (25 pages, three widths, English and Spanish): no
  sideways scrolling, no cut-off text, no headings out of order, no
  accessibility rule violations (axe, WCAG 2.1 A and AA).
- The examiner dashboard and a return under review: no violations.
- Tap targets: the new footer links are 44px tall.
- `bundle exec rspec` (240 examples) and the browser walkthrough
  (`bin/demo test`) pass.

## Still to do

- Look at the two side by side in a browser, on a phone and a desktop.
- Ask the Department whether its logo may be used.
- Ask the CoDS team whether fields in State services should be square, as
  on tax.colorado.gov, or rounded, as in CoDS.
