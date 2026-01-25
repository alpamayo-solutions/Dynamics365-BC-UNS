"""
Work Orders Page - View and create production orders.
"""

import sys
from pathlib import Path

import streamlit as st

sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from bridge.client import BCApiError, BCClient
from bridge.config import get_config_with_token
from bridge.models import CreateProductionOrder

st.set_page_config(
    page_title="Work Orders - UNS Bridge",
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
    st.title("Work Orders")
    st.divider()

    status_filter = st.selectbox(
        "Status Filter",
        ["Released", "Planned", "Firm_Planned", "Finished"],
        index=0,
    )

    if st.button("Refresh", use_container_width=True):
        st.rerun()


# Main Content
st.title("Production Orders")

client = get_client()
if not client:
    st.stop()

# Fetch orders
try:
    with client:
        orders = client.get_production_orders(status=status_filter, top=50)

        if not orders:
            st.warning(f"No {status_filter} production orders found.")

            # Offer to create one
            st.divider()
            st.subheader("Create a Production Order")

            with st.form("create_order"):
                items = client.get_items(top=50)
                item_options = {f"{i['number']} - {i.get('displayName', '')}": i['number'] for i in items}

                if not item_options:
                    st.error("No items available. Create items first via CLI: `bridge setup items`")
                    st.stop()

                selected_item = st.selectbox("Item", options=list(item_options.keys()))
                quantity = st.number_input("Quantity", min_value=1, value=100)
                description = st.text_input("Description", value="Demo order")
                order_status = st.selectbox("Status", ["Released", "Planned", "Firm_Planned"])

                if st.form_submit_button("Create Order", type="primary"):
                    item_no = item_options[selected_item]
                    order = CreateProductionOrder(
                        status=order_status,
                        source_no=item_no,
                        quantity=float(quantity),
                        description=description,
                    )

                    try:
                        result = client.create_production_order(order)
                        order_no = result.get("number", "Unknown")
                        system_id = result.get("id")

                        # Refresh to calculate routing
                        if system_id:
                            try:
                                client.refresh_production_order(system_id)
                            except BCApiError:
                                pass

                        st.success(f"Created order: {order_no}")
                        st.rerun()
                    except BCApiError as e:
                        st.error(f"Failed to create order: {e.message}")
        else:
            # Display orders in a table
            st.info(f"Found {len(orders)} {status_filter} order(s)")

            # Orders table
            for order in orders:
                col1, col2, col3, col4, col5 = st.columns([2, 3, 2, 2, 2])

                with col1:
                    st.markdown(f"**{order.number}**")
                with col2:
                    st.text(order.description or order.source_no or "-")
                with col3:
                    st.text(f"{order.quantity or 0:.0f} units")
                with col4:
                    if order.due_date:
                        st.text(order.due_date.strftime("%Y-%m-%d"))
                    else:
                        st.text("-")
                with col5:
                    if st.button("Select", key=f"select_{order.number}", use_container_width=True):
                        st.session_state["selected_order"] = order.number
                        st.session_state["selected_order_detail"] = {
                            "number": order.number,
                            "description": order.description,
                            "source_no": order.source_no,
                            "quantity": order.quantity,
                            "status": order.status,
                        }
                        st.success(f"Selected order: {order.number}")

            # Show selected order details
            if "selected_order" in st.session_state:
                st.divider()
                st.subheader(f"Selected: {st.session_state['selected_order']}")

                detail = st.session_state.get("selected_order_detail", {})
                col1, col2 = st.columns(2)
                with col1:
                    st.write(f"**Item:** {detail.get('source_no', '-')}")
                    st.write(f"**Quantity:** {detail.get('quantity', 0):.0f}")
                with col2:
                    st.write(f"**Status:** {detail.get('status', '-')}")
                    st.write(f"**Description:** {detail.get('description', '-')}")

                col1, col2 = st.columns(2)
                with col1:
                    if st.button("View Routing", use_container_width=True):
                        st.switch_page("pages/2_Work_Order_Routing.py")
                with col2:
                    if st.button("Post Event", use_container_width=True):
                        st.switch_page("pages/3_Shopfloor_Execution.py")

                # Show components/materials
                with st.expander("Materials (Components)"):
                    try:
                        components = client.get_components(st.session_state["selected_order"])
                        if not components:
                            st.info("No components found for this order.")
                        else:
                            for comp in components:
                                col1, col2, col3, col4 = st.columns([3, 2, 2, 2])
                                with col1:
                                    st.text(comp.item_no or "-")
                                    if comp.description:
                                        st.caption(comp.description)
                                with col2:
                                    st.text(f"Qty: {comp.expected_quantity or 0:.2f}")
                                with col3:
                                    st.text(f"Remaining: {comp.remaining_quantity or 0:.2f}")
                                with col4:
                                    st.text(comp.flushing_method or "-")
                    except BCApiError as e:
                        st.error(f"Failed to load components: {e.message}")

            # Create order section
            st.divider()
            with st.expander("Create New Order"):
                with st.form("create_order_expanded"):
                    items = client.get_items(top=50)
                    item_options = {f"{i['number']} - {i.get('displayName', '')}": i['number'] for i in items}

                    if not item_options:
                        st.error("No items available.")
                    else:
                        selected_item = st.selectbox("Item", options=list(item_options.keys()))
                        quantity = st.number_input("Quantity", min_value=1, value=100)
                        description = st.text_input("Description", value="Demo order")
                        order_status = st.selectbox("Status", ["Released", "Planned", "Firm_Planned"])

                        if st.form_submit_button("Create Order", type="primary"):
                            item_no = item_options[selected_item]
                            order = CreateProductionOrder(
                                status=order_status,
                                source_no=item_no,
                                quantity=float(quantity),
                                description=description,
                            )

                            try:
                                result = client.create_production_order(order)
                                order_no = result.get("number", "Unknown")
                                system_id = result.get("id")

                                if system_id:
                                    try:
                                        client.refresh_production_order(system_id)
                                    except BCApiError:
                                        pass

                                st.success(f"Created order: {order_no}")
                                st.rerun()
                            except BCApiError as e:
                                st.error(f"Failed to create order: {e.message}")

except BCApiError as e:
    st.error(f"API Error: {e.message}")
except Exception as e:
    st.error(f"Error: {e}")
