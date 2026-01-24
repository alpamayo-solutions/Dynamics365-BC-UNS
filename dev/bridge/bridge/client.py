"""Business Central API client."""

from typing import Any

import httpx

from .config import Config, get_token_from_az_cli
from .models import (
    CreateProductionOrder,
    ExecutionEvent,
    Item,
    ProductionOrder,
    RoutingLine,
    WorkCenter,
)


class BCApiError(Exception):
    """Error from BC API."""

    def __init__(self, status_code: int, message: str, details: dict | None = None):
        self.status_code = status_code
        self.message = message
        self.details = details or {}
        super().__init__(f"HTTP {status_code}: {message}")


class BCClient:
    """Client for Business Central API."""

    def __init__(self, config: Config):
        self.config = config
        self._token = config.access_token
        self._client = httpx.Client(timeout=30.0)

    def _headers(self) -> dict[str, str]:
        """Get headers with authorization."""
        if not self._token:
            raise BCApiError(401, "No access token available. Run 'bridge auth' first.")
        return {
            "Authorization": f"Bearer {self._token}",
            "Content-Type": "application/json",
        }

    def _refresh_token(self) -> bool:
        """Refresh token from Azure CLI."""
        token = get_token_from_az_cli()
        if token:
            self._token = token
            return True
        return False

    def _request(
        self,
        method: str,
        url: str,
        json: dict | None = None,
        params: dict | None = None,
    ) -> dict[str, Any]:
        """Make HTTP request with auto-retry on 401."""
        response = self._client.request(
            method, url, headers=self._headers(), json=json, params=params
        )

        # Retry on 401
        if response.status_code == 401:
            if self._refresh_token():
                response = self._client.request(
                    method, url, headers=self._headers(), json=json, params=params
                )

        if response.status_code >= 400:
            try:
                error_body = response.json()
                error_msg = error_body.get("error", {}).get(
                    "message", response.reason_phrase
                )
            except Exception:
                error_msg = response.reason_phrase or "Unknown error"
                error_body = {}
            raise BCApiError(response.status_code, error_msg, error_body)

        if response.status_code == 204:
            return {}

        return response.json()

    def get_companies(self) -> list[dict[str, Any]]:
        """Get list of companies."""
        url = f"{self.config.base_url}/api/v2.0/companies"
        result = self._request("GET", url)
        return result.get("value", [])

    def get_production_orders(
        self, status: str = "Released", top: int = 50
    ) -> list[ProductionOrder]:
        """Get production orders filtered by status via custom API."""
        url = f"{self.config.custom_api_url}/productionOrders"
        params = {
            "$filter": f"status eq '{status}'",
            "$top": str(top),
        }
        result = self._request("GET", url, params=params)
        return [ProductionOrder.model_validate(o) for o in result.get("value", [])]

    def get_routing_lines(self, order_no: str) -> list[RoutingLine]:
        """Get routing lines for a production order via custom API."""
        url = f"{self.config.custom_api_url}/prodOrderRoutingLines"
        params = {
            "$filter": f"prodOrderNo eq '{order_no}'",
        }
        result = self._request("GET", url, params=params)
        return [RoutingLine.model_validate(r) for r in result.get("value", [])]

    def post_execution_event(self, event: ExecutionEvent) -> dict[str, Any]:
        """Post an execution event to the custom API."""
        url = f"{self.config.custom_api_url}/executionEvents"
        payload = event.model_dump(mode="json", by_alias=True)
        return self._request("POST", url, json=payload)

    def get_items(self, top: int = 50) -> list[dict[str, Any]]:
        """Get all items."""
        url = f"{self.config.standard_api_url}/items"
        params = {"$top": str(top)}
        result = self._request("GET", url, params=params)
        return result.get("value", [])

    def create_item(self, item: Item) -> dict[str, Any]:
        """Create an item."""
        url = f"{self.config.standard_api_url}/items"
        payload = item.model_dump(mode="json", by_alias=True, exclude_none=True)
        return self._request("POST", url, json=payload)

    def get_item(self, item_number: str) -> dict[str, Any] | None:
        """Get an item by number."""
        url = f"{self.config.standard_api_url}/items"
        params = {"$filter": f"number eq '{item_number}'"}
        result = self._request("GET", url, params=params)
        items = result.get("value", [])
        return items[0] if items else None

    def get_work_centers(self) -> list[dict[str, Any]]:
        """Get all work centers via custom API."""
        url = f"{self.config.custom_api_url}/workCenters"
        result = self._request("GET", url)
        return result.get("value", [])

    def create_work_center(self, wc: WorkCenter) -> dict[str, Any]:
        """Create a work center via custom API."""
        url = f"{self.config.custom_api_url}/workCenters"
        payload = wc.model_dump(mode="json", by_alias=True, exclude_none=True)
        return self._request("POST", url, json=payload)

    def get_work_center(self, wc_number: str) -> dict[str, Any] | None:
        """Get a work center by number via custom API."""
        url = f"{self.config.custom_api_url}/workCenters"
        params = {"$filter": f"number eq '{wc_number}'"}
        result = self._request("GET", url, params=params)
        wcs = result.get("value", [])
        return wcs[0] if wcs else None

    def create_production_order(
        self, order: CreateProductionOrder
    ) -> dict[str, Any]:
        """Create a production order via custom API."""
        url = f"{self.config.custom_api_url}/productionOrders"
        payload = order.model_dump(mode="json", by_alias=True, exclude_none=True)
        return self._request("POST", url, json=payload)

    def close(self):
        """Close the HTTP client."""
        self._client.close()

    def __enter__(self):
        return self

    def __exit__(self, *args):
        self.close()
