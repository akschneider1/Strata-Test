# How the prototype's look compares with tax.colorado.gov

November 2026. The goal: someone who goes from tax.colorado.gov into the
prototype should feel they are still in the same place. The target is the
current tax.colorado.gov. Nothing is taken from the look of Revenue Online.

## What we compared, and how

- We saved the HTML, stylesheets, fonts and images that tax.colorado.gov
  serves for its home page and its Individual Income Tax page, and opened
  that saved copy in a browser at phone and desktop width. The values below
  were measured from it, and the layout was compared by eye.
- **We have not seen the live site in a browser.** Its bot check blocks
  automated browsers and we did not disguise ours to get past it. The saved
  copy ran with scripts off, so anything the site does with scripts (menus
  opening, search) was not seen. A person should still look at the two side
  by side.
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
| Links in text | `#173bb3`, underlined | `#173bb3`, underlined |
| Text boxes | 1px `#565c65` border, 4px corners (the search box) | 1px `#565c65` border, 4px corners |
| Breadcrumb on phones | A back arrow and the page above | The same |
| Header | White, soft shadow underneath | The same |
| Page width | 90rem (1440px) | 90rem |
| Footer | "Return to top", link columns, a line of notices | The same layout |
| Tags | 2px corners | 2px corners |

## What differs, and why

| | tax.colorado.gov | Prototype | Why |
| --- | --- | --- | --- |
| Logo | Department of Revenue logo | The service name in text | The prototype is not a Department service. Using the logo would make it look like one. If the Department agrees, it is a small change. |
| Top banner | Department notices (office closures) | "Prototype: this is a demonstration" | It must be clear this can't file a real return. |
| Cards | 8px corners, heavier shadow, no border | 4px corners, lighter shadow, thin border (the CoDS card) | CoDS card. Close, not identical. |
| Section headings | 32px on phones, 40px on desktop | 28px and 32px (one step smaller) | The prototype's pages are forms and short lists. The site's size is tuned for landing pages and crowded a phone screen. |
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

**The start page was one long column.** Seven people, then how the demo
works, then what is different, with a third of the screen empty. At desktop
width the people are now on the left and "How the demo works" sits beside
them in a USWDS summary box (CoDS has none). The first person in each group
has the filled button; the rest are outlined and the same width. Plain
paragraphs had the browser's tight line spacing and now match lists. A
signed-in person's own return no longer shows a "Home" breadcrumb, because
Home sends them back to that same page.

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

- Look at the live site and the prototype side by side in a browser, on a
  phone and a desktop.
- Ask the Department whether its logo may be used.
