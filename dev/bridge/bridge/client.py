"""Business Central API client (SaaS or on-prem/container, see config.py)."""

from typing import Any

import httpx

from .config import Config, get_token_from_az_cli
from .models import (
    CreateProductionOrder,
    Item,
    ProductionOrderComponent,
    ProductionOrderDetail,
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


def _odata_str(value: str) -> str:
    """Quote a string literal for an OData $filter."""
    return "'" + value.replace("'", "''") + "'"


class BCClient:
    """Client for the Business Central standard and Shopfloor APIs."""

    def __init__(self, config: Config):
        self.config = config
        self._token = config.access_token
        self._company_id = config.bc_company
        auth = None
        if not config.is_saas and config.username:
            auth = httpx.BasicAuth(config.username, config.password or "")
        self._client = httpx.Client(timeout=60.0, auth=auth)

    # -- plumbing ---------------------------------------------------------

    def _headers(self) -> dict[str, str]:
        headers = {"Content-Type": "application/json", "Accept": "application/json"}
        if self.config.is_saas:
            if not self._token:
                raise BCApiError(401, "No access token available. Run 'az login' first.")
            headers["Authorization"] = f"Bearer {self._token}"
        return headers

    def _refresh_token(self) -> bool:
        if not self.config.is_saas:
            return False
        token = get_token_from_az_cli()
        if token:
            self._token = token
            return True
        return False

    def _send(
        self,
        method: str,
        url: str,
        json: dict | None = None,
        params: dict | None = None,
        extra_headers: dict[str, str] | None = None,
    ) -> httpx.Response:
        def do() -> httpx.Response:
            headers = self._headers()
            if extra_headers:
                headers.update(extra_headers)
            try:
                return self._client.request(method, url, headers=headers, json=json, params=params)
            except httpx.TransportError as e:
                raise BCApiError(503, f"Cannot reach {self.config.api_root}: {e}") from e

        response = do()
        if response.status_code == 401 and self._refresh_token():
            response = do()
        return response

    def _request(
        self,
        method: str,
        url: str,
        json: dict | None = None,
        params: dict | None = None,
        extra_headers: dict[str, str] | None = None,
    ) -> dict[str, Any]:
        """Make an HTTP request; raise BCApiError on >= 400."""
        response = self._send(method, url, json=json, params=params, extra_headers=extra_headers)
        if response.status_code >= 400:
            try:
                error_body = response.json()
                error_msg = error_body.get("error", {}).get("message", response.reason_phrase)
            except Exception:
                error_msg = response.reason_phrase or "Unknown error"
                error_body = {}
            raise BCApiError(response.status_code, error_msg, error_body)
        if response.status_code == 204 or not response.content:
            return {}
        return response.json()

    # -- company ------------------------------------------------------------

    def get_companies(self) -> list[dict[str, Any]]:
        """List companies (standard API, no company needed)."""
        result = self._request("GET", f"{self.config.api_root}/v2.0/companies")
        return result.get("value", [])

    @property
    def company_id(self) -> str:
        """BC_COMPANY, or the company whose name is exactly BC_COMPANY_NAME."""
        if not self._company_id:
            self._company_id = self.resolve_company_id(self.config.bc_company_name or "")
        return self._company_id

    def resolve_company_id(self, name: str) -> str:
        """Resolve a company GUID by exact name. Company names are unique in BC."""
        if not name:
            raise BCApiError(400, "Set BC_COMPANY (GUID) or BC_COMPANY_NAME.")
        result = self._request(
            "GET",
            f"{self.config.api_root}/v2.0/companies",
            params={"$filter": f"name eq {_odata_str(name)}"},
        )
        companies = result.get("value", [])
        if not companies:
            raise BCApiError(404, f"No company named '{name}'. Run 'bridge companies'.")
        return companies[0]["id"]

    @property
    def standard_api_url(self) -> str:
        return self.config.standard_api_url(self.company_id)

    @property
    def custom_api_url(self) -> str:
        return self.config.custom_api_url(self.company_id)

    def _list(self, entity: str, params: dict[str, str] | None = None) -> list[dict[str, Any]]:
        result = self._request("GET", f"{self.custom_api_url}/{entity}", params=params)
        return result.get("value", [])

    # -- order book (read) --------------------------------------------------

    def get_production_orders(
        self, status: str = "Released", top: int = 50
    ) -> list[ProductionOrderDetail]:
        rows = self._list(
            "productionOrders", {"$filter": f"status eq '{status}'", "$top": str(top)}
        )
        return [ProductionOrderDetail.model_validate(o) for o in rows]

    def poll_production_orders(
        self, since: str, status: str = "Released", top: int = 50
    ) -> list[ProductionOrderDetail]:
        """Production orders modified since a given UTC datetime."""
        rows = self._list(
            "productionOrders",
            {
                "$filter": f"status eq '{status}' and systemModifiedAt gt {since}",
                "$top": str(top),
                "$orderby": "systemModifiedAt asc",
            },
        )
        return [ProductionOrderDetail.model_validate(o) for o in rows]

    def get_production_order_raw(self, order_no: str) -> dict[str, Any] | None:
        rows = self._list("productionOrders", {"$filter": f"number eq {_odata_str(order_no)}"})
        if len(rows) > 1:
            # Same number in several statuses: prefer Released, the only status execution writes to.
            released = [r for r in rows if r.get("status") == "Released"]
            rows = released or rows
        return rows[0] if rows else None

    def get_production_order(self, order_no: str) -> ProductionOrderDetail | None:
        row = self.get_production_order_raw(order_no)
        return ProductionOrderDetail.model_validate(row) if row else None

    def get_routing_lines_raw(
        self,
        order_no: str | None = None,
        status: str | None = None,
        step_id: str | None = None,
        top: int = 200,
    ) -> list[dict[str, Any]]:
        filters = []
        if status:
            filters.append(f"status eq '{status}'")
        if order_no:
            filters.append(f"prodOrderNo eq {_odata_str(order_no)}")
        if step_id:
            filters.append(f"stepId eq {_odata_str(step_id)}")
        params = {"$top": str(top)}
        if filters:
            params["$filter"] = " and ".join(filters)
        return self._list("prodOrderRoutingLines", params)

    def get_routing_lines(
        self, order_no: str | None = None, status: str | None = None, top: int = 200
    ) -> list[RoutingLine]:
        rows = self.get_routing_lines_raw(order_no=order_no, status=status, top=top)
        return [RoutingLine.model_validate(r) for r in rows]

    def get_step(self, step_id: str) -> RoutingLine:
        """The released routing line for a stepId; 404 when none."""
        rows = self.get_routing_lines_raw(step_id=step_id, status="Released")
        if not rows:
            raise BCApiError(404, f"Step {step_id} not found among released routing lines.")
        return RoutingLine.model_validate(rows[0])

    def get_components(self, order_no: str) -> list[ProductionOrderComponent]:
        rows = self._list("prodOrderComponents", {"$filter": f"prodOrderNo eq {_odata_str(order_no)}"})
        return [ProductionOrderComponent.model_validate(c) for c in rows]

    def get_items(self, top: int = 50) -> list[dict[str, Any]]:
        return self._list("items", {"$top": str(top)})

    def get_work_centers(self) -> list[dict[str, Any]]:
        return self._list("workCenters")

    def get_work_center(self, wc_number: str) -> dict[str, Any] | None:
        rows = self._list("workCenters", {"$filter": f"number eq {_odata_str(wc_number)}"})
        return rows[0] if rows else None

    def get_machine_centers(self) -> list[dict[str, Any]]:
        return self._list("machineCenters")

    def get_routings(self, status: str = "Certified") -> list[dict[str, Any]]:
        params = {"$filter": f"status eq '{status}'"} if status else None
        return self._list("routings", params)

    def get_employees(self, top: int = 50) -> list[dict[str, Any]]:
        """Employees from the standard API (``number`` = PREKIT employee_id)."""
        result = self._request("GET", f"{self.standard_api_url}/employees", params={"$top": str(top)})
        return result.get("value", [])

    # -- execution writes ---------------------------------------------------
    # Every write is one command row with an idempotency key; a repeat returns
    # 201 with result = "Duplicate" (orderNotes: the existing row).

    def post_step_finish(self, payload: dict[str, Any]) -> dict[str, Any]:
        return self._request("POST", f"{self.custom_api_url}/stepFinishes", json=payload)

    def post_person_time(self, payload: dict[str, Any]) -> dict[str, Any]:
        return self._request("POST", f"{self.custom_api_url}/personTimes", json=payload)

    def get_person_times(self, session_id: str) -> list[dict[str, Any]]:
        return self._list("personTimes", {"$filter": f"sessionId eq {_odata_str(session_id)}"})

    def post_order_note(self, payload: dict[str, Any]) -> dict[str, Any]:
        return self._request("POST", f"{self.custom_api_url}/orderNotes", json=payload)

    def get_order_notes(self, order_no: str | None = None, note_id: str | None = None) -> list[dict[str, Any]]:
        filters = []
        if order_no:
            filters.append(f"orderNo eq {_odata_str(order_no)}")
        if note_id:
            filters.append(f"noteId eq {_odata_str(note_id)}")
        return self._list("orderNotes", {"$filter": " and ".join(filters)} if filters else None)

    def delete_order_note(self, system_id: str) -> None:
        self._request(
            "DELETE", f"{self.custom_api_url}/orderNotes({system_id})", extra_headers={"If-Match": "*"}
        )

    def post_step_move(self, payload: dict[str, Any]) -> dict[str, Any]:
        return self._request("POST", f"{self.custom_api_url}/stepMoves", json=payload)

    def patch_step_plan(self, routing_line_id: str, fields: dict[str, Any]) -> dict[str, Any]:
        """PATCH the execution fine plan of a step (routing line SystemId)."""
        return self._request(
            "PATCH",
            f"{self.custom_api_url}/stepPlans({routing_line_id})",
            json=fields,
            extra_headers={"If-Match": "*"},
        )

    # -- test data setup ----------------------------------------------------

    def create_item(self, item: Item) -> dict[str, Any]:
        payload = item.model_dump(mode="json", by_alias=True, exclude_none=True)
        return self._request("POST", f"{self.standard_api_url}/items", json=payload)

    def get_item(self, item_number: str) -> dict[str, Any] | None:
        result = self._request(
            "GET",
            f"{self.standard_api_url}/items",
            params={"$filter": f"number eq {_odata_str(item_number)}"},
        )
        items = result.get("value", [])
        return items[0] if items else None

    def create_work_center(self, wc: WorkCenter) -> dict[str, Any]:
        payload = wc.model_dump(mode="json", by_alias=True, exclude_none=True)
        return self._request("POST", f"{self.custom_api_url}/workCenters", json=payload)

    def create_production_order(self, order: CreateProductionOrder) -> dict[str, Any]:
        # dueDate cannot be set on creation; it is PATCHed afterwards.
        payload = order.model_dump(mode="json", by_alias=True, exclude_none=True, exclude={"due_date"})
        return self._request("POST", f"{self.custom_api_url}/productionOrders", json=payload)

    def update_production_order(
        self, system_id: str, updates: dict[str, Any], etag: str | None = None
    ) -> dict[str, Any]:
        return self._request(
            "PATCH",
            f"{self.custom_api_url}/productionOrders({system_id})",
            json=updates,
            extra_headers={"If-Match": etag or "*"},
        )

    def delete_production_order(self, system_id: str) -> None:
        """Delete a production order by its SystemId (sandbox only)."""
        self._request(
            "DELETE",
            f"{self.custom_api_url}/productionOrders({system_id})",
            extra_headers={"If-Match": "*"},
        )

    def refresh_production_order(self, system_id: str) -> dict[str, Any]:
        """Refresh a production order to calculate routing and components."""
        return self._request(
            "POST", f"{self.custom_api_url}/productionOrders({system_id})/Microsoft.NAV.Refresh"
        )

    def close(self):
        self._client.close()

    def __enter__(self):
        return self

    def __exit__(self, *args):
        self.close()
