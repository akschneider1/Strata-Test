import logging
import os
import threading
from typing import Optional

from apiflask import APIFlask
from flask import g
from werkzeug.exceptions import Unauthorized

import src.adapters.db as db
import src.adapters.db.flask_db as flask_db
import src.logging
import src.logging.flask_logger as flask_logger
from src.api.healthcheck import healthcheck_blueprint
from src.api.schemas import response_schema
from src.api.tax import tax_blueprint
from src.api.tax.tax_routes import CALCULATOR_KEY
from src.api.users import user_blueprint
from src.auth.api_key_auth import User, get_app_security_scheme
from src.tax.calculator import PolicyEngineCalculator

logger = logging.getLogger(__name__)


def create_app() -> APIFlask:
    app = APIFlask(__name__)

    src.logging.init(__package__)
    flask_logger.init_app(logging.root, app)

    db_client = db.PostgresDBClient()
    flask_db.register_db_client(db_client, app)

    configure_app(app)
    register_blueprints(app)
    register_tax_calculator(app)
    register_index(app)

    return app


def current_user(is_user_expected: bool = True) -> Optional[User]:
    current = g.get("current_user")
    if is_user_expected and current is None:
        logger.error("No current user found for request")
        raise Unauthorized
    return current


def configure_app(app: APIFlask) -> None:
    # Modify the response schema to instead use the format of our ApiResponse class
    # which adds additional details to the object.
    # https://apiflask.com/schema/#base-response-schema-customization
    app.config["BASE_RESPONSE_SCHEMA"] = response_schema.ResponseSchema

    # Set a few values for the Swagger endpoint
    app.config["OPENAPI_VERSION"] = "3.0.3"

    # Set various general OpenAPI config values
    app.info = {
        "title": "Colorado Tax Engine (prototype)",
        "description": "Calculates Colorado individual income tax returns using PolicyEngine US. Prototype: not for filing.",
        "contact": {
            "name": "Nava PBC Engineering",
            "url": "https://www.navapbc.com",
            "email": "engineering@navapbc.com",
        },
    }

    # Set the security schema and define the header param
    # where we expect the API token to reside.
    # See: https://apiflask.com/authentication/#use-external-authentication-library
    app.security_schemes = get_app_security_scheme()


def register_blueprints(app: APIFlask) -> None:
    app.register_blueprint(healthcheck_blueprint)
    app.register_blueprint(user_blueprint)
    app.register_blueprint(tax_blueprint)


def register_tax_calculator(app: APIFlask) -> None:
    """Attach the tax rules engine to the app.

    PolicyEngine takes tens of seconds to import, so when TAX_ENGINE_PRELOAD
    is set we load it in the background at startup instead of making the
    first taxpayer wait. GET /v1/engine reports when it is ready.
    """
    calculator = PolicyEngineCalculator()
    app.extensions[CALCULATOR_KEY] = calculator
    if os.getenv("TAX_ENGINE_PRELOAD", "").lower() in ("1", "true"):
        threading.Thread(target=calculator.preload, name="tax-engine-preload", daemon=True).start()


def get_project_root_dir() -> str:
    return os.path.join(os.path.dirname(__file__), "..")


def register_index(app: APIFlask) -> None:
    @app.route("/")
    @app.doc(hide=True)
    def index() -> str:
        return """
            <!Doctype html>
            <html lang="en">
                <head><title>Home</title></head>
                <body>
                    <main>
                        <h1>Home</h1>
                        <p>Visit <a href="/docs">/docs</a> to view the api documentation for this project.</p>
                    </main>
                </body>
            </html>
        """
