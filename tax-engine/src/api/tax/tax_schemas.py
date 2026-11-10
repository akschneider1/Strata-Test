from apiflask import fields, validators

from src.api.schemas import request_schema
from src.tax import calculator

MONEY = validators.Range(min=0, max=10_000_000)
AGE = validators.Range(min=0, max=125)


def money(description: str) -> fields.Float:
    return fields.Float(load_default=0.0, validate=[MONEY], metadata={"description": description})


class PersonSchema(request_schema.OrderedSchema):
    age = fields.Integer(
        required=True, validate=[AGE], metadata={"description": "Age at the end of the tax year"}
    )
    wages = money("Wages, salaries and tips (Form W-2 box 1)")
    unemployment_compensation = money("Unemployment compensation (Form 1099-G box 1)")
    pension_income = money("Taxable pensions and annuities (Form 1099-R box 2a)")
    social_security = money("Social Security benefits (Form SSA-1099 box 5)")
    is_blind = fields.Boolean(load_default=False)


class DependentSchema(request_schema.OrderedSchema):
    age = fields.Integer(required=True, validate=[AGE])
    is_full_time_student = fields.Boolean(load_default=False)
    is_disabled = fields.Boolean(load_default=False)


class ReturnFactsSchema(request_schema.OrderedSchema):
    tax_year = fields.Integer(
        required=True, validate=[validators.OneOf(calculator.SUPPORTED_TAX_YEARS)]
    )
    filing_status = fields.String(
        required=True, validate=[validators.OneOf(calculator.FILING_STATUSES)]
    )
    filer = fields.Nested(PersonSchema, required=True)
    spouse = fields.Nested(PersonSchema, load_default=None, allow_none=True)
    dependents = fields.List(
        fields.Nested(DependentSchema), load_default=list, validate=[validators.Length(max=20)]
    )
    taxable_interest = money("Taxable interest (Form 1099-INT box 1)")
    childcare_expenses = money("Child care expenses paid so the filer could work")
    colorado_tax_withheld = money("Colorado income tax withheld (Form W-2 box 17 and 1099s)")


class LineSchema(request_schema.OrderedSchema):
    id = fields.String(metadata={"description": "Stable identifier for the line"})
    section = fields.String()
    amount = fields.Float(metadata={"description": "Whole dollars"})
    facts = fields.Dict(metadata={"description": "Values that explain the amount"})
    source_title = fields.String(allow_none=True)
    source_url = fields.String(allow_none=True)


class CalculationSchema(request_schema.OrderedSchema):
    tax_year = fields.Integer()
    filing_status = fields.String()
    lines = fields.List(fields.Nested(LineSchema))
    refund = fields.Float()
    amount_owed = fields.Float()
    engine = fields.String(metadata={"description": "Rules engine that produced the result"})
    engine_version = fields.String()


class EngineStatusSchema(request_schema.OrderedSchema):
    engine = fields.String()
    engine_version = fields.String()
    ready = fields.Boolean(
        metadata={"description": "False while the rules engine is still loading"}
    )
    supported_tax_years = fields.List(fields.Integer())
