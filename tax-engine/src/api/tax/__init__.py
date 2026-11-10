from src.api.tax.tax_blueprint import tax_blueprint

# import routes module to register the API routes on the blueprint
import src.api.tax.tax_routes  # noqa: F401 E402 isort:skip

__all__ = ["tax_blueprint"]
