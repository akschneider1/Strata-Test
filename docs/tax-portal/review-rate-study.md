# Review rate study

How many returns would the automatic checks send to an examiner? That
share decides how many examiners the service needs, so it matters more to
capacity than any server.

**This study does not answer that question for Colorado.** It runs made-up
households through the real checks. It shows how the rules behave and where
to look. The real answer needs the Department's own return and
information-return data.

## How to run it

Start the tax engine (`bin/demo` does), then:

```bash
cd tax-portal && bin/rails "tax:review_rate[1200]"
```

It files that many made-up returns through the real pipeline (tax engine,
then `ReturnProcessing::Screen`) inside a database transaction that is
rolled back, so nothing is left behind. The same seed gives the same
population. With the real engine, 1,200 returns took about 16 minutes on a
development machine.

Every assumption is in `tax-portal/config/review_rate_study.yml`: the mix of
households, the spread of wages, what employers withhold, and how often
taxpayers differ from the records on file. None of those figures is
measured. Change them and run it again.

## Result with the placeholder assumptions

1,200 returns, tax year 2025, PolicyEngine US 2.116.0:

| | Returns | Share |
| --- | ---: | ---: |
| Filed | 1,200 | |
| Sent to an examiner | 112 | 9.3% |
| Accepted with no review | 1,088 | 90.7% |

By reason (a return can have more than one):

| Reason | Returns | Share of all returns | Where it comes from |
| --- | ---: | ---: | --- |
| Withholding claimed with no record on file | 39 | 3.3% | The assumed 3% who add a form by hand |
| Large refund for the income reported | 33 | 2.8% | **The rule itself.** No assumption about taxpayer behavior |
| Withholding higher than the payer reported | 28 | 2.3% | The assumed 2% |
| Income lower than the payer reported | 16 | 1.3% | The assumed 1.5% |
| Dependent claimed on another return | 1 | 0.1% | The assumed 0.5% of returns with children |
| Record on file disputed | 1 | 0.1% | The assumed 0.5% |

By household:

| Household | Returns | Sent to an examiner |
| --- | ---: | ---: |
| Single parent | 160 | 19.4% |
| Couple with children | 179 | 15.1% |
| Retired, single | 59 | 8.5% |
| Couple, no children | 230 | 7.4% |
| Retired couple | 61 | 6.6% |
| Single, no children | 511 | 5.5% |

## What this tells us

1. **Most of the 9.3% is our own guesswork.** About three quarters of the
   flags come straight from the assumed rates at which taxpayers differ from
   the records. Double those rates and the review rate roughly doubles. The
   real rates are in the Department's W-2 and 1099 matching data, and nowhere
   else.
2. **One rule flags families for being eligible.** "Large refund for the
   income reported" fired on 2.8% of all returns without any misreporting.
   Households with children were sent to an examiner at 17% (58 of 339),
   against 6% for everyone else (54 of 861). The likely cause is that
   Colorado's refundable credits for families (earned income, child tax and
   family affordability credits) produce exactly the pattern the rule looks
   for: a refund that is large next to a low income. We did not break the
   flags down by household and reason, so treat the cause as likely, not
   shown. As written, the rule would delay refunds for the families the
   credits are meant to reach. It should be redesigned before any pilot, for
   example by comparing the refund with what the credits explain.
3. **At this rate, every 100,000 returns means about 9,300 reviews.** The
   prototype's examiner tools were built and tested for one return at a
   time. Staffing, not servers, is the capacity question.

## What it would take to know the real rate

- A file of prior-year returns, with personal details removed, to replace
  the made-up households.
- The Department's information-return match results: how often reported
  wages and withholding differ from what payers filed, and by how much.
- A decision on each rule's threshold. The values in
  `tax-portal/app/services/return_processing/screen.rb` are illustrative.

The study reads its population from one file, so swapping in real
distributions is a change to that file. Reading actual returns would need a
loader, which has not been written.
