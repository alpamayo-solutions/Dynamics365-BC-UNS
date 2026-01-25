"""Business Central API client."""

from typing import Any

import httpx

from .config import Config, get_token_from_az_cli
from .models import (
    CreateProductionOrder,
    ExecutionEvent,
    InboxEntry,
    Item,
    ProductionOrder,
    ProductionOrderComponent,
    ProductionOrderDetail,
    RoutingLine,
    UNSTopicMapping,
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

        # Handle empty response body
        if not response.content:
            return {}

        return response.json()

    def get_companies(self) -> list[dict[str, Any]]:
        """Get list of companies."""
        url = f"{self.config.base_url}/api/v2.0/companies"
        result = self._request("GET", url)
        return result.get("value", [])

    def get_production_orders(
        self, status: str = "Released", top: int = 50
    ) -> list[ProductionOrderDetail]:
        """Get production orders filtered by status via custom API."""
        url = f"{self.config.custom_api_url}/productionOrders"
        params = {
            "$filter": f"status eq '{status}'",
            "$top": str(top),
        }
        result = self._request("GET", url, params=params)
        return [ProductionOrderDetail.model_validate(o) for o in result.get("value", [])]

    def get_routing_lines(self, order_no: str | None = None, status: str | None = None) -> list[RoutingLine]:
        """Get routing lines for a production order via custom API."""
        url = f"{self.config.custom_api_url}/prodOrderRoutingLines"
        filters = []
        if status:
            filters.append(f"status eq '{status}'")
        if order_no:
            filters.append(f"prodOrderNo eq '{order_no}'")
        params = {}
        if filters:
            params["$filter"] = " and ".join(filters)
        params["$top"] = "50"
        result = self._request("GET", url, params=params)
        return [RoutingLine.model_validate(r) for r in result.get("value", [])]

    def post_execution_event(self, event: ExecutionEvent) -> dict[str, Any]:
        """Post an execution event to the custom API."""
        url = f"{self.config.custom_api_url}/executionEvents"
        payload = event.model_dump(mode="json", by_alias=True)
        return self._request("POST", url, json=payload)

    def get_items(self, top: int = 50) -> list[dict[str, Any]]:
        """Get all items with manufacturing fields via custom API."""
        url = f"{self.config.custom_api_url}/items"
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
        # Exclude dueDate from creation - must be set via PATCH after
        payload = order.model_dump(mode="json", by_alias=True, exclude_none=True, exclude={"due_date"})
        return self._request("POST", url, json=payload)

    def update_production_order(
        self, system_id: str, updates: dict[str, Any], etag: str | None = None
    ) -> dict[str, Any]:
        """Update a production order via custom API."""
        url = f"{self.config.custom_api_url}/productionOrders({system_id})"
        headers = self._headers()
        if etag:
            headers["If-Match"] = etag
        response = self._client.request("PATCH", url, headers=headers, json=updates)
        if response.status_code >= 400:
            try:
                error_body = response.json()
                error_msg = error_body.get("error", {}).get("message", response.reason_phrase)
            except Exception:
                error_msg = response.reason_phrase or "Unknown error"
                error_body = {}
            raise BCApiError(response.status_code, error_msg, error_body)
        if response.status_code == 204:
            return {}
        return response.json()

    def get_production_order(self, order_no: str) -> ProductionOrderDetail | None:
        """Get a single production order by number via custom API."""
        url = f"{self.config.custom_api_url}/productionOrders"
        params = {"$filter": f"number eq '{order_no}'"}
        result = self._request("GET", url, params=params)
        orders = result.get("value", [])
        return ProductionOrderDetail.model_validate(orders[0]) if orders else None

    def poll_production_orders(
        self, since: str, status: str = "Released", top: int = 50
    ) -> list[ProductionOrderDetail]:
        """Poll for production orders modified since a given datetime."""
        url = f"{self.config.custom_api_url}/productionOrders"
        params = {
            "$filter": f"status eq '{status}' and systemModifiedAt gt {since}",
            "$top": str(top),
            "$orderby": "systemModifiedAt asc",
        }
        result = self._request("GET", url, params=params)
        return [ProductionOrderDetail.model_validate(o) for o in result.get("value", [])]

    def get_components(self, order_no: str) -> list[ProductionOrderComponent]:
        """Get components (BOM lines) for a production order via custom API."""
        url = f"{self.config.custom_api_url}/prodOrderComponents"
        params = {"$filter": f"prodOrderNo eq '{order_no}'"}
        result = self._request("GET", url, params=params)
        return [
            ProductionOrderComponent.model_validate(c) for c in result.get("value", [])
        ]

    def get_integration_inbox(
        self, status: str | None = None, top: int = 50
    ) -> list[InboxEntry]:
        """Get integration inbox entries via custom API."""
        url = f"{self.config.custom_api_url}/integrationInbox"
        params: dict[str, str] = {"$top": str(top)}
        if status:
            params["$filter"] = f"status eq '{status}'"
        result = self._request("GET", url, params=params)
        return [InboxEntry.model_validate(e) for e in result.get("value", [])]

    def delete_production_order(self, system_id: str) -> None:
        """Delete a production order by its SystemId (only works in sandbox)."""
        url = f"{self.config.custom_api_url}/productionOrders({system_id})"
        self._request("DELETE", url)

    def refresh_production_order(self, system_id: str) -> dict[str, Any]:
        """Refresh a production order to calculate routing and components."""
        url = f"{self.config.custom_api_url}/productionOrders({system_id})/Microsoft.NAV.Refresh"
        return self._request("POST", url)

    def get_routings(self, status: str = "Certified") -> list[dict[str, Any]]:
        """Get available routings via custom API."""
        url = f"{self.config.custom_api_url}/routings"
        params = {"$filter": f"status eq '{status}'"} if status else {}
        result = self._request("GET", url, params=params)
        return result.get("value", [])

    # UNS Topic Mapping methods

    def get_uns_topic_mappings(
        self, status: str | None = None, top: int = 100
    ) -> list[UNSTopicMapping]:
        """Get UNS topic mappings via custom API."""
        url = f"{self.config.custom_api_url}/unsTopicMappings"
        params: dict[str, str] = {"$top": str(top)}
        if status:
            params["$filter"] = f"status eq '{status}'"
        result = self._request("GET", url, params=params)
        return [UNSTopicMapping.model_validate(m) for m in result.get("value", [])]

    def get_uns_topic_mapping(self, uns_topic: str) -> UNSTopicMapping | None:
        """Get a single UNS topic mapping by topic."""
        url = f"{self.config.custom_api_url}/unsTopicMappings"
        params = {"$filter": f"unsTopic eq '{uns_topic}'"}
        result = self._request("GET", url, params=params)
        mappings = result.get("value", [])
        return UNSTopicMapping.model_validate(mappings[0]) if mappings else None

    def create_uns_topic_mapping(self, mapping: UNSTopicMapping) -> dict[str, Any]:
        """Create a new UNS topic mapping via custom API."""
        url = f"{self.config.custom_api_url}/unsTopicMappings"
        payload = mapping.model_dump(mode="json", by_alias=True, exclude_none=True)
        return self._request("POST", url, json=payload)

    def update_uns_topic_mapping(
        self, uns_topic: str, updates: dict[str, Any]
    ) -> dict[str, Any]:
        """Update a UNS topic mapping via custom API."""
        # First get the mapping to find its systemId
        existing = self.get_uns_topic_mapping(uns_topic)
        if not existing:
            raise BCApiError(404, f"UNS topic mapping '{uns_topic}' not found")
        # Use the topic as the key for the PATCH
        url = f"{self.config.custom_api_url}/unsTopicMappings('{uns_topic}')"
        return self._request("PATCH", url, json=updates)

    def delete_uns_topic_mapping(self, uns_topic: str) -> None:
        """Delete a UNS topic mapping via custom API."""
        url = f"{self.config.custom_api_url}/unsTopicMappings('{uns_topic}')"
        self._request("DELETE", url)

    def close(self):
        """Close the HTTP client."""
        self._client.close()

    def __enter__(self):
        return self

    def __exit__(self, *args):
        self.close()
