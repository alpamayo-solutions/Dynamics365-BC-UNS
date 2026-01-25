"""Pydantic models for BC API payloads."""

from datetime import date, datetime, timezone
from uuid import UUID, uuid4

from pydantic import BaseModel, Field, field_serializer


def utc_now() -> datetime:
    """Return current UTC time with timezone info."""
    return datetime.now(timezone.utc)


class ExecutionEvent(BaseModel):
    """Execution event payload for the Shopfloor API."""

    message_id: UUID = Field(default_factory=uuid4, alias="messageId")
    order_no: str = Field(alias="orderNo")
    operation_no: str = Field(default="10", alias="operationNo")
    work_center: str | None = Field(default=None, alias="workCenter")
    qty_produced: int = Field(default=0, alias="qtyProduced")
    qty_rejected: int = Field(default=0, alias="qtyRejected")
    runtime_sec: float = Field(default=0, alias="runtimeSec")
    downtime_sec: float = Field(default=0, alias="downtimeSec")
    availability: float = Field(default=0.95, ge=0, le=1)
    productivity: float = Field(default=0.90, ge=0, le=1)
    actual_cycle_time_sec: float = Field(default=0, alias="actualCycleTimeSec")
    source_timestamp: datetime = Field(default_factory=utc_now, alias="sourceTimestamp")
    source: str = "BRIDGE-CLI"

    model_config = {"populate_by_name": True}

    @field_serializer("source_timestamp")
    def serialize_timestamp(self, value: datetime) -> str:
        """Serialize datetime to ISO format with Z suffix for BC OData."""
        if value.tzinfo is None:
            value = value.replace(tzinfo=timezone.utc)
        return value.strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z"


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

    status: str | None = None
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
    due_date: date | None = Field(default=None, alias="dueDate")

    model_config = {"populate_by_name": True}


class ProductionOrderDetail(BaseModel):
    """Production order with full details from BC API."""

    id: UUID | None = None
    number: str
    description: str | None = None
    status: str | None = None
    source_type: str | None = Field(default=None, alias="sourceType")
    source_no: str | None = Field(default=None, alias="sourceNo")
    quantity: float | None = None
    due_date: date | None = Field(default=None, alias="dueDate")
    starting_date: date | None = Field(default=None, alias="startingDate")
    ending_date: date | None = Field(default=None, alias="endingDate")
    location_code: str | None = Field(default=None, alias="locationCode")
    last_modified_date_time: datetime | None = Field(
        default=None, alias="lastModifiedDateTime"
    )
    system_modified_at: datetime | None = Field(default=None, alias="systemModifiedAt")

    model_config = {"populate_by_name": True}


class ProductionOrderComponent(BaseModel):
    """Production order component (BOM line) from BC API."""

    status: str | None = None
    prod_order_no: str = Field(alias="prodOrderNo")
    prod_order_line_no: int | None = Field(default=None, alias="prodOrderLineNo")
    line_no: int | None = Field(default=None, alias="lineNo")
    item_no: str | None = Field(default=None, alias="itemNo")
    description: str | None = None
    unit_of_measure_code: str | None = Field(default=None, alias="unitOfMeasureCode")
    quantity_per: float | None = Field(default=None, alias="quantityPer")
    expected_quantity: float | None = Field(default=None, alias="expectedQuantity")
    remaining_quantity: float | None = Field(default=None, alias="remainingQuantity")
    location_code: str | None = Field(default=None, alias="locationCode")
    bin_code: str | None = Field(default=None, alias="binCode")
    flushing_method: str | None = Field(default=None, alias="flushingMethod")
    routing_link_code: str | None = Field(default=None, alias="routingLinkCode")
    due_date: date | None = Field(default=None, alias="dueDate")

    model_config = {"populate_by_name": True}


class InboxEntry(BaseModel):
    """Integration inbox entry from BC API."""

    message_id: UUID = Field(alias="messageId")
    message_type: str | None = Field(default=None, alias="messageType")
    order_no: str | None = Field(default=None, alias="orderNo")
    operation_no: str | None = Field(default=None, alias="operationNo")
    status: str | None = None
    received_at: datetime | None = Field(default=None, alias="receivedAt")
    processed_at: datetime | None = Field(default=None, alias="processedAt")
    error: str | None = None
    warning: str | None = None

    model_config = {"populate_by_name": True}


class UNSTopicMapping(BaseModel):
    """UNS topic to work center mapping from BC API."""

    uns_topic: str = Field(alias="unsTopic")
    work_center_no: str | None = Field(default=None, alias="workCenterNo")
    status: str = "Active"
    description: str | None = None
    source_system: str | None = Field(default=None, alias="sourceSystem")
    valid_from: date | None = Field(default=None, alias="validFrom")
    valid_to: date | None = Field(default=None, alias="validTo")
    created_at: datetime | None = Field(default=None, alias="createdAt")
    created_by: str | None = Field(default=None, alias="createdBy")

    model_config = {"populate_by_name": True}
