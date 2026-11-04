"""Pydantic models for BC API payloads."""

from datetime import UTC, date, datetime
from uuid import UUID

from pydantic import BaseModel, Field


def utc_now() -> datetime:
    """Return current UTC time with timezone info."""
    return datetime.now(UTC)


def bc_datetime(value: datetime) -> str:
    """Format a datetime for BC OData: UTC, ISO 8601 with a ``Z`` suffix."""
    if value.tzinfo is None:
        value = value.replace(tzinfo=UTC)
    return value.astimezone(UTC).strftime("%Y-%m-%dT%H:%M:%SZ")


class RoutingLine(BaseModel):
    """Released production order routing line (one Execution app step)."""

    id: UUID | None = None
    step_id: str | None = Field(default=None, alias="stepId")
    status: str | None = None
    prod_order_no: str = Field(alias="prodOrderNo")
    routing_reference_no: int | None = Field(default=None, alias="routingReferenceNo")
    routing_no: str | None = Field(default=None, alias="routingNo")
    operation_no: str = Field(alias="operationNo")
    sequence_no: int | None = Field(default=None, alias="sequenceNo")
    previous_operation_no: str | None = Field(default=None, alias="previousOperationNo")
    next_operation_no: str | None = Field(default=None, alias="nextOperationNo")
    type: str | None = None
    no: str | None = None
    work_center_no: str | None = Field(default=None, alias="workCenterNo")
    work_center_group_code: str | None = Field(default=None, alias="workCenterGroupCode")
    description: str | None = None
    setup_time: float | None = Field(default=None, alias="setupTime")
    run_time: float | None = Field(default=None, alias="runTime")
    input_quantity: float | None = Field(default=None, alias="inputQuantity")
    planned_minutes: float | None = Field(default=None, alias="plannedMinutes")
    routing_status: str | None = Field(default=None, alias="routingStatus")
    starting_date_time: datetime | None = Field(default=None, alias="startingDateTime")
    ending_date_time: datetime | None = Field(default=None, alias="endingDateTime")
    execution_finished: bool | None = Field(default=None, alias="executionFinished")
    execution_finished_at: datetime | None = Field(default=None, alias="executionFinishedAt")
    output_quantity: float | None = Field(default=None, alias="outputQuantity")
    scrap_quantity: float | None = Field(default=None, alias="scrapQuantity")
    planned_start: datetime | None = Field(default=None, alias="plannedStart")
    planned_end: datetime | None = Field(default=None, alias="plannedEnd")
    queue_position: int | None = Field(default=None, alias="queuePosition")

    model_config = {"populate_by_name": True}

    @property
    def done(self) -> bool:
        """A step is done when the Execution app finished it or BC reports it Finished."""
        return bool(self.execution_finished) or self.routing_status == "Finished"


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
    item_no: str | None = Field(default=None, alias="itemNo")
    customer_order_no: str | None = Field(default=None, alias="customerOrderNo")
    starting_date_time: datetime | None = Field(default=None, alias="startingDateTime")
    ending_date_time: datetime | None = Field(default=None, alias="endingDateTime")
    finished_date: date | None = Field(default=None, alias="finishedDate")
    held: bool | None = None
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
