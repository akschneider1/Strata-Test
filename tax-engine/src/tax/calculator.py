"""Colorado individual income tax calculation, backed by PolicyEngine US.

This module is the only place that knows about PolicyEngine. Everything else
talks in terms of `ReturnFacts` (what the taxpayer told us) and
`Calculation` (the lines of the Colorado return, with where each came from).
A certified tax calculator could replace this module behind the same API.
"""

from __future__ import annotations

import dataclasses
import hashlib
import json
import logging
import threading
from importlib import metadata
from typing import Any

logger = logging.getLogger(__name__)

# 2025 is the year the portal files. 2027 is supported so the portal can show
# what Colorado's graduated rates would mean for a household; PolicyEngine
# projects the other 2027 amounts (deductions, credits) forward.
SUPPORTED_TAX_YEARS = (2025, 2027)

# How Colorado taxable income is taxed.
#   flat:      one rate on all taxable income (C.R.S. 39-22-104).
#   graduated: the brackets in Amendment 87 (Initiative 195), approved by
#              voters in November 2026 for tax years starting in 2027.
RATE_SCHEDULES = ("flat", "graduated")
GRADUATED_FIRST_TAX_YEAR = 2027
# Switches on PolicyEngine's model of the Amendment 87 schedule. Not
# modeled there: the measure taxes gains on a principal residence above the
# federal exclusion at a fixed 4.4%. The portal doesn't collect such gains.
GRADUATED_REFORM = {
    "gov.contrib.states.co.progressive_income_tax.in_effect": {"2027-01-01.2100-12-31": True}
}
AMENDMENT_87 = (
    "Colorado Amendment 87 (Initiative 2025-2026 #195), C.R.S. 39-22-104 (1.8)",
    "https://www.sos.state.co.us/pubs/elections/Initiatives/titleBoard/filings/2025-2026/195Final.pdf#page=3",
)

FILING_STATUSES = (
    "SINGLE",
    "JOINT",
    "SEPARATE",
    "HEAD_OF_HOUSEHOLD",
    "SURVIVING_SPOUSE",
)

# Most income a person can have and still be claimed as a qualifying relative
# (the "gross income test"). Not a PolicyEngine parameter, so it is kept here:
# 2025 amount from IRS Rev. Proc. 2024-40, section 3.25.
QUALIFYING_RELATIVE_INCOME_LIMIT = {2025: 5_200}

BOOK_2025 = "https://tax.colorado.gov/sites/tax/files/documents/Book104_2025.pdf"


@dataclasses.dataclass(frozen=True)
class Person:
    age: int
    wages: float = 0.0
    unemployment_compensation: float = 0.0
    pension_income: float = 0.0
    social_security: float = 0.0
    is_blind: bool = False


@dataclasses.dataclass(frozen=True)
class Dependent:
    age: int
    is_full_time_student: bool = False
    is_disabled: bool = False


@dataclasses.dataclass(frozen=True)
class ReturnFacts:
    tax_year: int
    filing_status: str
    filer: Person
    spouse: Person | None = None
    dependents: tuple[Dependent, ...] = ()
    taxable_interest: float = 0.0
    childcare_expenses: float = 0.0
    colorado_tax_withheld: float = 0.0
    # None means the schedule in law for the tax year.
    rate_schedule: str | None = None

    @property
    def effective_rate_schedule(self) -> str:
        if self.rate_schedule:
            return self.rate_schedule
        return "graduated" if self.tax_year >= GRADUATED_FIRST_TAX_YEAR else "flat"

    def cache_key(self) -> str:
        payload = json.dumps(dataclasses.asdict(self), sort_keys=True)
        return hashlib.sha256(payload.encode()).hexdigest()


@dataclasses.dataclass(frozen=True)
class Line:
    """One line of the calculation, in the order it appears on the return."""

    id: str
    section: str
    amount: float
    # Extra facts that explain the amount (e.g. number of qualifying children).
    facts: dict[str, Any] = dataclasses.field(default_factory=dict)
    source_title: str | None = None
    source_url: str | None = None


@dataclasses.dataclass(frozen=True)
class Calculation:
    tax_year: int
    filing_status: str
    lines: tuple[Line, ...]
    refund: float
    amount_owed: float
    engine: str
    engine_version: str
    rate_schedule: str = "flat"

    def amount(self, line_id: str) -> float:
        for line in self.lines:
            if line.id == line_id:
                return line.amount
        raise KeyError(line_id)


class UnsupportedReturnError(ValueError):
    """The facts describe a return this prototype cannot calculate."""


def _dollars(value: Any) -> float:
    """Sum a PolicyEngine result array and round to whole dollars.

    Colorado returns are filed in whole dollars (DR 0104 instructions).
    """
    return float(round(float(value.sum())))


def _source(page: int, title: str) -> tuple[str, str]:
    return (
        f"2025 Colorado Individual Income Tax Filing Guide (104 Book): {title}",
        f"{BOOK_2025}#page={page}",
    )


class PolicyEngineCalculator:
    """Runs Colorado returns through PolicyEngine US."""

    engine = "policyengine-us"

    def __init__(self) -> None:
        self._simulation_cls: Any = None
        # The tax rules with the graduated schedule switched on. Building it
        # takes about 20 seconds, so it is built once, when first needed.
        self._graduated_system: Any = None
        self._preloading_graduated = False
        self._load_lock = threading.Lock()
        self._cache: dict[str, Calculation] = {}
        self._cache_lock = threading.Lock()
        self.engine_version = metadata.version("policyengine-us")

    @property
    def is_loaded(self) -> bool:
        if self._preloading_graduated and self._graduated_system is None:
            return False
        return self._simulation_cls is not None

    def load(self) -> None:
        """Import PolicyEngine (slow: tens of seconds). Safe to call repeatedly."""
        with self._load_lock:
            if self._simulation_cls is None:
                logger.info("loading policyengine-us %s", self.engine_version)
                from policyengine_us import Simulation

                self._simulation_cls = Simulation
                logger.info("policyengine-us loaded")

    def preload(self) -> None:
        """Load everything a request could need, so no taxpayer waits for it."""
        self._preloading_graduated = True
        self.load()
        self._graduated_rules()

    def calculate(self, facts: ReturnFacts) -> Calculation:
        validate(facts)
        key = facts.cache_key()
        with self._cache_lock:
            cached = self._cache.get(key)
        if cached is not None:
            return cached

        self.load()
        result = self._run(facts)
        with self._cache_lock:
            if len(self._cache) > 2000:
                self._cache.clear()
            self._cache[key] = result
        return result

    # -- internals ---------------------------------------------------------

    def _graduated_rules(self) -> Any:
        with self._load_lock:
            if self._graduated_system is None:
                from policyengine_core.reforms import Reform
                from policyengine_us import CountryTaxBenefitSystem

                logger.info("building tax rules with the graduated rate schedule")
                reform = Reform.from_dict(GRADUATED_REFORM, country_id="us")
                self._graduated_system = reform(CountryTaxBenefitSystem())
            return self._graduated_system

    def _run(self, facts: ReturnFacts) -> Calculation:
        year = facts.tax_year
        schedule = facts.effective_rate_schedule
        if schedule == "graduated":
            sim = self._simulation_cls(
                situation=build_situation(facts), tax_benefit_system=self._graduated_rules()
            )
        else:
            sim = self._simulation_cls(situation=build_situation(facts))

        def calc(variable: str) -> float:
            return _dollars(sim.calculate(variable, year))

        def count(variable: str) -> int:
            return int(sim.calculate(variable, year).sum())

        lines: list[Line] = []

        def add(
            line_id: str,
            section: str,
            amount: float,
            source: tuple[str, str] | None = None,
            **line_facts: Any,
        ) -> None:
            title, url = source if source else (None, None)
            lines.append(Line(line_id, section, amount, line_facts, title, url))

        # Federal starting point. Colorado starts from federal taxable income
        # (C.R.S. 39-22-104), so we show how that number is reached.
        agi = calc("adjusted_gross_income")
        federal_taxable_income = calc("taxable_income")
        add("total_income", "federal", calc("irs_gross_income"))
        add("taxable_social_security", "federal", calc("tax_unit_taxable_social_security"))
        add("federal_agi", "federal", agi)
        add(
            "federal_deductions",
            "federal",
            max(agi - federal_taxable_income, 0.0),
            standard_deduction=calc("standard_deduction"),
        )
        add("federal_taxable_income", "federal", federal_taxable_income, None)

        # Additions and subtractions.
        add("additions", "colorado_income", calc("co_additions"), _source(8, "Additions"))
        pension_subtraction = calc("co_pension_subtraction")
        subtractions = calc("co_subtractions")
        add(
            "pension_subtraction",
            "colorado_income",
            pension_subtraction,
            _source(18, "Subtractions"),
        )
        add(
            "other_subtractions",
            "colorado_income",
            max(subtractions - pension_subtraction, 0.0),
            _source(18, "Subtractions"),
        )
        add("subtractions", "colorado_income", subtractions, _source(18, "Subtractions"))
        add("colorado_taxable_income", "colorado_income", calc("co_taxable_income"), None)

        # Tax.
        parameters = sim.tax_benefit_system.parameters(f"{year}-01-01")
        tax = calc("co_income_tax_before_non_refundable_credits")
        if schedule == "graduated":
            scale = parameters.gov.contrib.states.co.progressive_income_tax.rate
            add(
                "tax",
                "tax",
                tax,
                AMENDMENT_87,
                rate_schedule=schedule,
                brackets=tax_by_bracket(
                    calc("co_taxable_income"),
                    [float(t) for t in scale.thresholds],
                    [float(r) for r in scale.rates],
                ),
            )
        else:
            rate = float(parameters.gov.states.co.tax.income.rate)
            source = _source(11, "Line 12") if year == 2025 else None
            add("tax", "tax", tax, source, rate=rate, rate_schedule=schedule)
        add("alternative_minimum_tax", "tax", calc("co_amt"))
        add("nonrefundable_credits", "tax", calc("co_non_refundable_credits"))
        net_tax = max(calc("co_income_tax_before_refundable_credits") + calc("co_amt"), 0.0)
        add("net_tax", "tax", net_tax)

        # Refundable credits: we work out which ones the household qualifies for.
        children_under_6 = sum(1 for d in facts.dependents if d.age < 6)
        children_under_17 = sum(1 for d in facts.dependents if d.age < 17)
        add(
            "earned_income_credit",
            "credits",
            calc("co_eitc"),
            _source(25, "Refundable credits"),
            federal_eitc=calc("eitc"),
        )
        add(
            "child_tax_credit",
            "credits",
            calc("co_ctc"),
            _source(25, "Refundable credits"),
            qualifying_children=count("co_ctc_eligible_children_count"),
            children_under_6=children_under_6,
        )
        add(
            "family_affordability_credit",
            "credits",
            calc("co_family_affordability_credit"),
            _source(25, "Refundable credits"),
            children_under_17=children_under_17,
        )
        add(
            "child_care_credit",
            "credits",
            calc("co_cdcc") + calc("co_low_income_cdcc"),
            _source(25, "Refundable credits"),
            childcare_expenses=facts.childcare_expenses,
        )
        add(
            "tabor_sales_tax_refund",
            "credits",
            calc("co_sales_tax_refund"),
            _source(25, "Refundable credits"),
        )
        add("care_worker_credit", "credits", calc("co_care_worker_credit"))
        refundable = calc("co_refundable_credits")
        add("refundable_credits", "credits", refundable)

        # Payments and result.
        withheld = float(round(facts.colorado_tax_withheld))
        add("colorado_tax_withheld", "payments", withheld)
        balance = net_tax - refundable - withheld
        refund = max(-balance, 0.0)
        owed = max(balance, 0.0)
        add("refund", "result", refund)
        add("amount_owed", "result", owed)

        return Calculation(
            tax_year=year,
            filing_status=facts.filing_status,
            lines=tuple(lines),
            refund=refund,
            amount_owed=owed,
            engine=self.engine,
            engine_version=self.engine_version,
            rate_schedule=schedule,
        )


def tax_by_bracket(
    taxable_income: float, thresholds: list[float], rates: list[float]
) -> list[dict[str, float | None]]:
    """How much of the taxable income falls in each bracket, and the tax on it.

    Shown to the taxpayer as the explanation of a graduated tax. The total is
    PolicyEngine's; this only splits it by bracket.
    """
    brackets: list[dict[str, float | None]] = []
    for index, (start, rate) in enumerate(zip(thresholds, rates, strict=True)):
        end = thresholds[index + 1] if index + 1 < len(thresholds) else None
        upper = taxable_income if end is None else min(taxable_income, end)
        income = max(upper - start, 0.0)
        brackets.append(
            {
                "from": start,
                "to": end,
                "rate": rate,
                "income": float(round(income)),
                "tax": float(round(income * rate)),
            }
        )
    return brackets


def validate(facts: ReturnFacts) -> None:
    if facts.tax_year not in SUPPORTED_TAX_YEARS:
        raise UnsupportedReturnError(f"Tax year {facts.tax_year} is not supported")
    if facts.filing_status not in FILING_STATUSES:
        raise UnsupportedReturnError(f"Unknown filing status {facts.filing_status}")
    if facts.rate_schedule is not None and facts.rate_schedule not in RATE_SCHEDULES:
        raise UnsupportedReturnError(f"Unknown rate schedule {facts.rate_schedule}")
    if facts.effective_rate_schedule == "graduated" and facts.tax_year < GRADUATED_FIRST_TAX_YEAR:
        raise UnsupportedReturnError(
            f"The graduated rate schedule starts with tax year {GRADUATED_FIRST_TAX_YEAR}"
        )
    needs_spouse = facts.filing_status == "JOINT"
    if needs_spouse and facts.spouse is None:
        raise UnsupportedReturnError("A joint return needs a spouse")
    if not needs_spouse and facts.spouse is not None:
        raise UnsupportedReturnError("Only a joint return includes a spouse's income")
    if facts.filing_status in ("HEAD_OF_HOUSEHOLD", "SURVIVING_SPOUSE") and not facts.dependents:
        raise UnsupportedReturnError(f"{facts.filing_status} needs at least one dependent")


def build_situation(facts: ReturnFacts) -> dict[str, Any]:
    """Translate return facts into a PolicyEngine household."""
    year = str(facts.tax_year)

    def adult(person: Person) -> dict[str, Any]:
        return {
            "age": {year: person.age},
            "employment_income": {year: person.wages},
            "unemployment_compensation": {year: person.unemployment_compensation},
            "taxable_pension_income": {year: person.pension_income},
            "social_security_retirement": {year: person.social_security},
            "is_blind": {year: person.is_blind},
        }

    people: dict[str, Any] = {"filer": adult(facts.filer)}
    people["filer"]["taxable_interest_income"] = {year: facts.taxable_interest}
    adults = ["filer"]
    if facts.spouse is not None:
        people["spouse"] = adult(facts.spouse)
        adults.append("spouse")

    dependents = []
    for index, dependent in enumerate(facts.dependents, start=1):
        name = f"dependent_{index}"
        people[name] = {
            "age": {year: dependent.age},
            "is_tax_unit_dependent": {year: True},
            "is_full_time_student": {year: dependent.is_full_time_student},
            "is_disabled": {year: dependent.is_disabled},
        }
        dependents.append(name)

    members = adults + dependents
    marital_units = {"adults": {"members": adults}}
    for name in dependents:
        marital_units[f"{name}_unit"] = {"members": [name]}

    return {
        "people": people,
        "tax_units": {
            "tax_unit": {
                "members": members,
                "filing_status": {year: facts.filing_status},
                "tax_unit_childcare_expenses": {year: facts.childcare_expenses},
            }
        },
        "marital_units": marital_units,
        "families": {"family": {"members": members}},
        "spm_units": {"spm_unit": {"members": members}},
        "households": {"household": {"members": members, "state_name": {year: "CO"}}},
    }
