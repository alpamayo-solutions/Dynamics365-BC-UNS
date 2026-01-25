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
st.title("Routing Lines")

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
        routing_lines = client.get_routing_lines(order_no=selected_order)

        if not routing_lines:
            st.warning(f"No routing lines found for order {selected_order}")
            st.caption("This order may not have a routing defined, or the item has no production BOM/routing.")
        else:
            st.subheader(f"Routing for Order: {selected_order}")
            st.info(f"Found {len(routing_lines)} operation(s)")

            # Display routing lines
            for line in routing_lines:
                with st.container():
                    col1, col2, col3, col4, col5 = st.columns([1, 2, 2, 2, 2])

                    with col1:
                        st.markdown(f"**Op {line.operation_no}**")
                    with col2:
                        st.text(line.type or "-")
                        st.caption(line.no or "-")
                    with col3:
                        st.text(line.description or "-")
                    with col4:
                        runtime = line.run_time or 0
                        setup = line.setup_time or 0
                        st.text(f"Run: {runtime:.1f} min")
                        st.text(f"Setup: {setup:.1f} min")
                    with col5:
                        if st.button("Post Event", key=f"post_{line.operation_no}", use_container_width=True):
                            st.session_state["selected_operation"] = line.operation_no
                            st.session_state["selected_work_center"] = line.no
                            st.switch_page("pages/3_Shopfloor_Execution.py")

                    st.divider()

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
col1, col2 = st.columns(2)
with col1:
    if st.button("Back to Orders", use_container_width=True):
        st.switch_page("pages/1_Work_Orders.py")
with col2:
    if st.button("Post Event", use_container_width=True, key="nav_post_event"):
        st.switch_page("pages/3_Shopfloor_Execution.py")
