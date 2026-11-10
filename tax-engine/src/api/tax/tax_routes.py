import logging
from typing import Any

from apiflask import HTTPError
from flask import current_app

import src.api.response as response
from src.api.tax import tax_schemas
from src.api.tax.tax_blueprint import tax_blueprint
from src.auth.api_key_auth import api_key_auth
from src.tax import calculator

logger = logging.getLogger(__name__)

CALCULATOR_KEY = "tax_calculator"


def get_calculator() -> calculator.PolicyEngineCalculator:
    return current_app.extensions[CALCULATOR_KEY]


def to_facts(params: dict[str, Any]) -> calculator.ReturnFacts:
    spouse = params.get("spouse")
    return calculator.ReturnFacts(
        tax_year=params["tax_year"],
        filing_status=params["filing_status"],
        filer=calculator.Person(**params["filer"]),
        spouse=calculator.Person(**spouse) if spouse else None,
        dependents=tuple(calculator.Dependent(**d) for d in params.get("dependents", [])),
        taxable_interest=params["taxable_interest"],
        childcare_expenses=params["childcare_expenses"],
        colorado_tax_withheld=params["colorado_tax_withheld"],
    )


@tax_blueprint.post("/v1/returns/calculate")
@tax_blueprint.input(tax_schemas.ReturnFactsSchema, arg_name="params")
@tax_blueprint.output(tax_schemas.CalculationSchema)
@tax_blueprint.auth_required(api_key_auth)
def calculate_return(params: dict[str, Any]) -> response.ApiResponse:
    """Calculate a Colorado individual income tax return (form DR 0104).

    Takes what the taxpayer told us and returns each line of the return,
    which credits the household qualifies for, and the refund or amount owed.
    Amounts are never logged.
    """
    try:
        result = get_calculator().calculate(to_facts(params))
    except calculator.UnsupportedReturnError as error:
        raise HTTPError(422, message=str(error)) from error

    logger.info(
        "Calculated return",
        extra={
            "tax_year": result.tax_year,
            "filing_status": result.filing_status,
            "engine_version": result.engine_version,
        },
    )
    return response.ApiResponse(message="Success", data=result)


@tax_blueprint.get("/v1/engine")
@tax_blueprint.output(tax_schemas.EngineStatusSchema)
def engine_status() -> response.ApiResponse:
    """Which rules engine is running and whether it has finished loading."""
    calc = get_calculator()
    return response.ApiResponse(
        message="Success",
        data={
            "engine": calc.engine,
            "engine_version": calc.engine_version,
            "ready": calc.is_loaded,
            "supported_tax_years": list(calculator.SUPPORTED_TAX_YEARS),
            "qualifying_relative_income_limits": {
                str(year): limit
                for year, limit in calculator.QUALIFYING_RELATIVE_INCOME_LIMIT.items()
            },
        },
    )
