"""
Shopfloor Execution Page - Post execution events with OEE metrics.
"""

import json
import sys
from pathlib import Path

import streamlit as st

sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from bridge.client import BCApiError, BCClient
from bridge.config import get_config_with_token
from bridge.models import ExecutionEvent

st.set_page_config(
    page_title="Shopfloor Execution - UNS Bridge",
    page_icon="gui/assets/favicon.ico",
    layout="wide",
)


def get_client() -> BCClient | None:
    """Get BCClient instance with error handling."""
    try:
        config = get_config_with_token()
        return BCClient(config)
    except Exception as e:
        st.error(f"Connection error: {e}")
        return None


# Sidebar
with st.sidebar:
    st.title("Shopfloor Execution")
    st.divider()

    if st.button("Clear Form", use_container_width=True):
        for key in ["event_submitted", "last_event_result"]:
            if key in st.session_state:
                del st.session_state[key]
        st.rerun()


# Main Content
st.title("Post Execution Event")

client = get_client()
if not client:
    st.stop()

# Get prefilled values from session state
selected_order = st.session_state.get("selected_order", "")
selected_operation = st.session_state.get("selected_operation", "10")
selected_work_center = st.session_state.get("selected_work_center", "")

with client:
    # Fetch orders and work centers for dropdowns
    try:
        orders = client.get_production_orders(status="Released", top=50)
        # Create display -> value mapping for orders
        order_options = {
            f"{o.number} - {o.description or o.source_no or ''}": o.number
            for o in orders
        }

        work_centers = client.get_work_centers()
        # Create display -> value mapping for work centers
        wc_options = {
            f"{wc.get('number', '')} - {wc.get('name', '')}": wc.get("number", "")
            for wc in work_centers
            if wc.get("number")
        }
    except BCApiError as e:
        st.error(f"Failed to fetch data: {e.message}")
        order_options = {}
        wc_options = {}

    # Event form
    with st.form("event_form"):
        st.subheader("Event Details")

        col1, col2 = st.columns(2)

        with col1:
            # Order selection
            if order_options:
                order_display_list = list(order_options.keys())
                order_values = list(order_options.values())
                default_idx = order_values.index(selected_order) if selected_order in order_values else 0
                selected_order_display = st.selectbox("Order Number", options=order_display_list, index=default_idx)
                order_no = order_options[selected_order_display]
            else:
                order_no = st.text_input("Order Number", value=selected_order)

            operation_no = st.text_input("Operation Number", value=selected_operation)

        with col2:
            # Work center selection
            if wc_options:
                wc_display_list = ["(none)"] + list(wc_options.keys())
                wc_values = [""] + list(wc_options.values())
                default_idx = wc_values.index(selected_work_center) if selected_work_center in wc_values else 0
                selected_wc_display = st.selectbox("Work Center", options=wc_display_list, index=default_idx)
                work_center = "" if selected_wc_display == "(none)" else wc_options[selected_wc_display]
            else:
                work_center = st.text_input("Work Center", value=selected_work_center)

            source = st.text_input("Source", value="BRIDGE-GUI")

        st.divider()
        st.subheader("Quantities")

        col1, col2 = st.columns(2)
        with col1:
            qty_produced = st.number_input("Quantity Produced", min_value=0, value=10)
        with col2:
            qty_rejected = st.number_input("Quantity Rejected", min_value=0, value=0)

        st.divider()
        st.subheader("OEE Metrics")

        col1, col2 = st.columns(2)
        with col1:
            availability_pct = st.slider(
                "Availability",
                min_value=0,
                max_value=100,
                value=95,
                step=1,
                format="%d%%",
                help="Equipment availability (uptime / planned production time)",
            )
            availability = availability_pct / 100.0

        with col2:
            productivity_pct = st.slider(
                "Productivity (Performance)",
                min_value=0,
                max_value=100,
                value=90,
                step=1,
                format="%d%%",
                help="Performance efficiency (actual output / theoretical output)",
            )
            productivity = productivity_pct / 100.0

        # Calculate OEE
        quality = 1.0 - (qty_rejected / qty_produced) if qty_produced > 0 else 1.0
        oee = availability * productivity * quality
        st.metric("Calculated OEE", f"{oee:.1%}")

        st.divider()
        st.subheader("Time Metrics")

        col1, col2 = st.columns(2)
        with col1:
            runtime_sec = st.number_input("Runtime (seconds)", min_value=0.0, value=600.0)
            actual_cycle_time = st.number_input("Actual Cycle Time (seconds)", min_value=0.0, value=60.0)
        with col2:
            downtime_sec = st.number_input("Downtime (seconds)", min_value=0.0, value=0.0)

        st.divider()

        # Submit button
        submitted = st.form_submit_button("Post Event", type="primary", use_container_width=True)

        if submitted:
            if not order_no:
                st.error("Order number is required")
            elif not work_center:
                st.error("Work center is required")
            else:
                # Create event
                event = ExecutionEvent(
                    order_no=order_no,
                    operation_no=operation_no or "10",
                    work_center=work_center if work_center else None,
                    qty_produced=int(qty_produced),
                    qty_rejected=int(qty_rejected),
                    runtime_sec=float(runtime_sec),
                    downtime_sec=float(downtime_sec),
                    availability=float(availability),
                    productivity=float(productivity),
                    actual_cycle_time_sec=float(actual_cycle_time),
                    source=source,
                )

                try:
                    result = client.post_execution_event(event)
                    st.session_state["event_submitted"] = True
                    st.session_state["last_event_result"] = {
                        "message_id": str(event.message_id),
                        "payload": event.model_dump(mode="json", by_alias=True),
                        "response": result,
                    }
                    st.success(f"Event posted successfully! Message ID: {event.message_id}")
                except BCApiError as e:
                    st.error(f"Failed to post event: {e.message}")

    # Show last event details
    if st.session_state.get("event_submitted"):
        st.divider()
        st.subheader("Last Posted Event")

        result = st.session_state.get("last_event_result", {})

        with st.expander("View JSON Payload", expanded=True):
            st.json(result.get("payload", {}))

        with st.expander("View API Response"):
            st.json(result.get("response", {}))

# Navigation
st.divider()
col1, col2, col3 = st.columns(3)
with col1:
    if st.button("Work Orders", use_container_width=True):
        st.switch_page("pages/1_Work_Orders.py")
with col2:
    if st.button("Work Order Routing", use_container_width=True):
        st.switch_page("pages/2_Work_Order_Routing.py")
with col3:
    if st.button("UNS Mapping", use_container_width=True):
        st.switch_page("pages/4_UNS_Mapping.py")
