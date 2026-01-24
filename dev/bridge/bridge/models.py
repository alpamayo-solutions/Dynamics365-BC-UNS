"""Pydantic models for BC API payloads."""

from datetime import datetime
from uuid import UUID, uuid4

from pydantic import BaseModel, Field


class ExecutionEvent(BaseModel):
    """Execution event payload for the Shopfloor API."""

    message_id: UUID = Field(default_factory=uuid4, alias="messageId")
    order_no: str = Field(alias="orderNo")
    operation_no: str = Field(default="10", alias="operationNo")
    work_center: str | None = Field(default=None, alias="workCenter")
    n_parts: int = Field(default=0, alias="nParts")
    n_rejected: int = Field(default=0, alias="nRejected")
    runtime_sec: float = Field(default=0, alias="runtimeSec")
    downtime_sec: float = Field(default=0, alias="downtimeSec")
    availability: float = Field(default=0.95, ge=0, le=1)
    productivity: float = Field(default=0.90, ge=0, le=1)
    actual_cycle_time_sec: float = Field(default=0, alias="actualCycleTimeSec")
    source_timestamp: datetime = Field(
        default_factory=datetime.utcnow, alias="sourceTimestamp"
    )
    source: str = "BRIDGE-CLI"

    model_config = {"populate_by_name": True}


class ProductionOrder(BaseModel):
    """Production order from BC API."""

    id: UUID | None = None
    number: str
    description: str | None = None
    status: str | None = None
    source_no: str | None = Field(default=None, alias="sourceNo")
    quantity: float | None = None

    model_config = {"populate_by_name": True}


class RoutingLine(BaseModel):
    """Production order routing line from BC API."""

    prod_order_no: str = Field(alias="prodOrderNo")
    operation_no: str = Field(alias="operationNo")
    type: str | None = None
    no: str | None = None
    description: str | None = None
    run_time: float | None = Field(default=None, alias="runTime")
    setup_time: float | None = Field(default=None, alias="setupTime")

    model_config = {"populate_by_name": True}


class Item(BaseModel):
    """Item for BC API."""

    number: str
    display_name: str = Field(alias="displayName")
    type: str = "Inventory"
    unit_of_measure_code: str | None = Field(default=None, alias="unitOfMeasureCode")

    model_config = {"populate_by_name": True}


class WorkCenter(BaseModel):
    """Work center for BC API."""

    number: str
    name: str
    unit_of_measure_code: str | None = Field(default=None, alias="unitOfMeasureCode")

    model_config = {"populate_by_name": True}


class CreateProductionOrder(BaseModel):
    """Payload for creating a production order."""

    status: str = "Released"  # Simulated, Planned, Firm_Planned, Released, Finished
    source_type: str = Field(default="Item", alias="sourceType")
    source_no: str = Field(alias="sourceNo")
    description: str | None = None
    quantity: float = 1.0

    model_config = {"populate_by_name": True}
