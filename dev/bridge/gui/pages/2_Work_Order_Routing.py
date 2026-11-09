"""
Work Order Routing Page - View routing lines for production orders.
"""

import sys
from pathlib import Path

import streamlit as st

sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from bridge.client import BCApiError, BCClient
from bridge.config import get_config_with_token

st.set_page_config(
    page_title="Work Order Routing - UNS Bridge",
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
    st.title("Work Order Routing")
    st.divider()

    if st.button("Refresh", use_container_width=True):
        st.rerun()


# Main Content
st.title("Steps")

client = get_client()
if not client:
    st.stop()

# Check for selected order
selected_order = st.session_state.get("selected_order")

with client:
    # Order selection
    if not selected_order:
        st.info("No order selected. Select an order from the Orders page or choose below.")

    # Always show order selector
    try:
        orders = client.get_production_orders(status="Released", top=50)
        order_options = {f"{o.number} - {o.description or o.source_no}": o.number for o in orders}

        if order_options:
            default_idx = 0
            if selected_order and selected_order in order_options.values():
                default_idx = list(order_options.values()).index(selected_order)

            selected = st.selectbox(
                "Select Order",
                options=list(order_options.keys()),
                index=default_idx,
            )
            selected_order = order_options[selected]
            st.session_state["selected_order"] = selected_order
        else:
            st.warning("No released orders found. Create one from the Orders page.")
            if st.button("Go to Orders"):
                st.switch_page("pages/1_Work_Orders.py")
            st.stop()

    except BCApiError as e:
        st.error(f"Failed to fetch orders: {e.message}")
        st.stop()

    st.divider()

    # Fetch routing lines for selected order
    try:
        routing_lines = client.get_routing_lines(order_no=selected_order, status="Released")

        if not routing_lines:
            st.warning(f"No routing lines found for order {selected_order}")
            st.caption("This order may not have a routing defined, or the item has no production BOM/routing.")
        else:
            st.subheader(f"Routing for Order: {selected_order}")
            st.info(f"Found {len(routing_lines)} operation(s)")

            # Read-only step view: execution facts come from the Execution app, not from here.
            st.dataframe(
                [
                    {
                        "stepId": line.step_id,
                        "Seq": line.sequence_no,
                        "Place": f"{line.type or ''} {line.no or ''}".strip(),
                        "Description": line.description,
                        "Routing status": line.routing_status,
                        "Exec. finished": bool(line.execution_finished),
                        "Output": line.output_quantity,
                        "Scrap": line.scrap_quantity,
                        "Planned min": line.planned_minutes,
                        "Plan start": line.planned_start,
                        "Queue": line.queue_position,
                    }
                    for line in sorted(
                        routing_lines,
                        key=lambda r: (r.routing_reference_no or 0, r.sequence_no or 0),
                    )
                ],
                use_container_width=True,
                hide_index=True,
            )

            # Summary
            total_runtime = sum(line.run_time or 0 for line in routing_lines)
            total_setup = sum(line.setup_time or 0 for line in routing_lines)

            col1, col2, col3 = st.columns(3)
            with col1:
                st.metric("Operations", len(routing_lines))
            with col2:
                st.metric("Total Run Time", f"{total_runtime:.1f} min")
            with col3:
                st.metric("Total Setup Time", f"{total_setup:.1f} min")

    except BCApiError as e:
        st.error(f"Failed to fetch routing: {e.message}")

# Navigation
st.divider()
if st.button("Back to Orders", use_container_width=True):
    st.switch_page("pages/1_Work_Orders.py")
