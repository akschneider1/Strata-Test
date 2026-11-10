"""Tests for the Colorado calculation.

`test_demo_households` runs the real PolicyEngine rules (slow to import, so
the calculator is shared across the module). The expected numbers were
produced by PolicyEngine US 2.116.0 for tax year 2025 and spot-checked by
hand where noted; a change means the rules or the mapping changed and
should be reviewed, not just updated.
"""

import pytest

from src.tax import calculator as c

P, D, F = c.Person, c.Dependent, c.ReturnFacts

SINGLE_W2 = F(2025, "SINGLE", P(29, wages=48000), colorado_tax_withheld=1650)
SINGLE_PARENT = F(
    2025,
    "HEAD_OF_HOUSEHOLD",
    P(34, wages=38000),
    dependents=(D(4), D(9)),
    childcare_expenses=4200,
    colorado_tax_withheld=900,
)
RETIRED_COUPLE = F(
    2025,
    "JOINT",
    P(68, pension_income=31000, social_security=24000),
    P(66, pension_income=12000, social_security=18000),
    taxable_interest=1400,
    colorado_tax_withheld=600,
)


@pytest.fixture(scope="module")
def engine() -> c.PolicyEngineCalculator:
    return c.PolicyEngineCalculator()


def test_single_filer_with_wages(engine):
    result = engine.calculate(SINGLE_W2)

    # By hand: $48,000 wages - $15,750 standard deduction = $32,250 taxable.
    # $32,250 x 4.4% = $1,419. Withheld $1,650 + $19 sales tax refund.
    assert result.amount("federal_taxable_income") == 32250
    assert result.amount("colorado_taxable_income") == 32250
    assert result.amount("tax") == 1419
    assert result.amount("tabor_sales_tax_refund") == 19
    assert result.refund == 250
    assert result.amount_owed == 0
    assert result.engine == "policyengine-us"


def test_single_parent_gets_family_credits(engine):
    result = engine.calculate(SINGLE_PARENT)

    assert result.amount("tax") == 632
    assert result.amount("earned_income_credit") == 2033
    assert result.amount("child_tax_credit") == 600
    assert result.amount("family_affordability_credit") == 3759
    assert result.amount("child_care_credit") == 483
    assert result.amount("refundable_credits") == 6894
    assert result.refund == 7162

    child_tax_credit = next(line for line in result.lines if line.id == "child_tax_credit")
    assert child_tax_credit.facts == {"qualifying_children": 2, "children_under_6": 1}
    assert child_tax_credit.source_url.startswith("https://tax.colorado.gov/")


def test_retired_couple_pension_subtraction(engine):
    result = engine.calculate(RETIRED_COUPLE)

    assert result.amount("taxable_social_security") == 24190
    assert result.amount("pension_subtraction") == 46367
    assert result.amount("colorado_taxable_income") == 0
    assert result.amount("tax") == 0
    assert result.refund == 650


def test_balance_due_when_too_little_withheld(engine):
    result = engine.calculate(F(2025, "SINGLE", P(41, wages=61000), colorado_tax_withheld=1000))

    assert result.amount("tax") == 1991
    assert result.refund == 0
    assert result.amount_owed == 1991 - 1000 - result.amount("refundable_credits")


def test_results_are_cached(engine):
    assert engine.calculate(SINGLE_W2) is engine.calculate(SINGLE_W2)


@pytest.mark.parametrize(
    "facts, message",
    [
        (F(2023, "SINGLE", P(30)), "Tax year 2023"),
        (F(2025, "WIDOW", P(30)), "Unknown filing status"),
        (F(2025, "JOINT", P(30)), "needs a spouse"),
        (F(2025, "SINGLE", P(30), spouse=P(30)), "Only a joint return"),
        (F(2025, "HEAD_OF_HOUSEHOLD", P(30)), "at least one dependent"),
    ],
)
def test_unsupported_returns_are_rejected(facts, message):
    with pytest.raises(c.UnsupportedReturnError, match=message):
        c.validate(facts)


def test_situation_puts_spouses_in_one_marital_unit():
    situation = c.build_situation(RETIRED_COUPLE)

    assert situation["marital_units"] == {"adults": {"members": ["filer", "spouse"]}}
    assert situation["tax_units"]["tax_unit"]["filing_status"] == {"2025": "JOINT"}
    assert situation["households"]["household"]["state_name"] == {"2025": "CO"}


# -- Graduated rates (Amendment 87), tax year 2027 ---------------------------
#
# Expected amounts are PolicyEngine US 2.116.0 results. The first is also
# checked by hand below. 2027 deductions are PolicyEngine's projections.


def test_graduated_rates_for_a_middle_income_filer(engine):
    facts = F(2027, "SINGLE", P(40, wages=48000))
    graduated = engine.calculate(facts)
    flat = engine.calculate(F(2027, "SINGLE", P(40, wages=48000), rate_schedule="flat"))

    assert graduated.rate_schedule == "graduated"
    assert flat.rate_schedule == "flat"
    assert graduated.amount("colorado_taxable_income") == flat.amount("colorado_taxable_income")
    assert graduated.amount("colorado_taxable_income") == 31450
    # By hand: 25,000 x 3.7% = 925, plus 6,450 x 4.2% = 270.90, total 1,195.90.
    assert graduated.amount("tax") == 1196
    assert flat.amount("tax") == 1384

    line = next(line for line in graduated.lines if line.id == "tax")
    assert line.source_title.startswith("Colorado Amendment 87")
    assert [b for b in line.facts["brackets"] if b["income"] > 0] == [
        {"from": 0.0, "to": 25000.0, "rate": 0.037, "income": 25000.0, "tax": 925.0},
        {"from": 25000.0, "to": 100000.0, "rate": 0.042, "income": 6450.0, "tax": 271.0},
    ]
    assert len(line.facts["brackets"]) == 6


def test_graduated_rates_for_a_high_income_filer(engine):
    graduated = engine.calculate(F(2027, "SINGLE", P(40, wages=1_500_000)))
    flat = engine.calculate(F(2027, "SINGLE", P(40, wages=1_500_000), rate_schedule="flat"))

    assert flat.amount("tax") == 65956
    assert graduated.amount("tax") == 101841
    line = next(line for line in graduated.lines if line.id == "tax")
    assert line.facts["brackets"][-1] == {
        "from": 1_000_000.0,
        "to": None,
        "rate": 0.084,
        "income": 499000.0,
        "tax": 41916.0,
    }
    assert abs(sum(b["tax"] for b in line.facts["brackets"]) - graduated.amount("tax")) <= 3


def test_2025_returns_keep_the_flat_rate(engine):
    result = engine.calculate(SINGLE_W2)

    assert result.rate_schedule == "flat"
    line = next(line for line in result.lines if line.id == "tax")
    assert line.facts == {"rate": 0.044, "rate_schedule": "flat"}


def test_graduated_rates_cannot_be_applied_before_2027():
    with pytest.raises(c.UnsupportedReturnError, match="starts with tax year 2027"):
        c.validate(F(2025, "SINGLE", P(30), rate_schedule="graduated"))
    with pytest.raises(c.UnsupportedReturnError, match="Unknown rate schedule"):
        c.validate(F(2027, "SINGLE", P(30), rate_schedule="progressive"))


def test_tax_by_bracket_splits_income_across_brackets():
    brackets = c.tax_by_bracket(120_000, [0, 25_000, 100_000], [0.037, 0.042, 0.044])

    assert [(b["income"], b["tax"]) for b in brackets] == [
        (25_000.0, 925.0),
        (75_000.0, 3150.0),
        (20_000.0, 880.0),
    ]
    assert brackets[-1]["to"] is None
    assert [b["income"] for b in c.tax_by_bracket(0, [0, 25_000], [0.037, 0.042])] == [0.0, 0.0]
