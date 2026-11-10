import dataclasses

import pytest

from src.api.tax.tax_routes import CALCULATOR_KEY
from src.tax import calculator as c


class FakeCalculator:
    """Stands in for PolicyEngine so route tests stay fast."""

    engine = "fake"
    engine_version = "0"
    is_loaded = True

    def __init__(self):
        self.seen: list[c.ReturnFacts] = []

    def calculate(self, facts: c.ReturnFacts) -> c.Calculation:
        c.validate(facts)
        self.seen.append(facts)
        line = c.Line(
            "tax", "tax", 1419.0, {"rate": 0.044}, "104 Book", "https://tax.colorado.gov/"
        )
        return c.Calculation(
            facts.tax_year,
            facts.filing_status,
            (line,),
            250.0,
            0.0,
            self.engine,
            self.engine_version,
        )


@pytest.fixture
def fake_calculator(app, monkeypatch):
    fake = FakeCalculator()
    monkeypatch.setitem(app.extensions, CALCULATOR_KEY, fake)
    return fake


BODY = {
    "tax_year": 2025,
    "filing_status": "SINGLE",
    "filer": {"age": 29, "wages": 48000},
    "colorado_tax_withheld": 1650,
}


def test_calculate_return(client, api_auth_token, fake_calculator):
    response = client.post("/v1/returns/calculate", json=BODY, headers={"X-Auth": api_auth_token})

    assert response.status_code == 200
    data = response.get_json()["data"]
    assert data["refund"] == 250.0
    assert data["engine"] == "fake"
    assert data["lines"][0] == {
        "id": "tax",
        "section": "tax",
        "amount": 1419.0,
        "facts": {"rate": 0.044},
        "source_title": "104 Book",
        "source_url": "https://tax.colorado.gov/",
    }
    facts = fake_calculator.seen[0]
    assert dataclasses.asdict(facts.filer)["wages"] == 48000
    assert facts.spouse is None
    assert facts.dependents == ()


def test_calculate_requires_auth(client, fake_calculator):
    response = client.post("/v1/returns/calculate", json=BODY)

    assert response.status_code == 401
    assert fake_calculator.seen == []


def test_calculate_rejects_invalid_body(client, api_auth_token, fake_calculator):
    body = BODY | {"filing_status": "WIDOW", "filer": {"age": -1}}
    response = client.post("/v1/returns/calculate", json=body, headers={"X-Auth": api_auth_token})

    assert response.status_code == 422


def test_calculate_rejects_unsupported_return(client, api_auth_token, fake_calculator):
    body = BODY | {"filing_status": "JOINT"}
    response = client.post("/v1/returns/calculate", json=body, headers={"X-Auth": api_auth_token})

    assert response.status_code == 422
    assert "needs a spouse" in response.get_json()["message"]


def test_engine_status(client, fake_calculator):
    response = client.get("/v1/engine")

    assert response.status_code == 200
    assert response.get_json()["data"] == {
        "engine": "fake",
        "engine_version": "0",
        "ready": True,
        "supported_tax_years": [2025],
        "qualifying_relative_income_limits": {"2025": 5200},
    }
