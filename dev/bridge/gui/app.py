"""
UNS Bridge Connector Demo GUI

Main entry point for the Streamlit demo application.
Run with: streamlit run gui/app.py
"""

import sys
from pathlib import Path

import streamlit as st

# Add bridge package to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from bridge.client import BCApiError, BCClient
from bridge.config import get_config_with_token

st.set_page_config(
    page_title="Bridge Demo",
    page_icon="gui/assets/favicon.ico",
    layout="wide",
    initial_sidebar_state="expanded",
)


def get_client() -> BCClient | None:
    """Get BCClient instance with error handling."""
    try:
        config = get_config_with_token()
        return BCClient(config)
    except Exception as e:
        st.session_state["connection_error"] = str(e)
        return None


def check_connection() -> tuple[bool, str, str | None]:
    """Check BC API connection status. Returns (connected, message, url)."""
    try:
        config = get_config_with_token()
        with BCClient(config) as client:
            companies = client.get_companies()
            if companies:
                return True, f"Connected to {config.bc_env}", config.base_url
            return False, "No companies found", None
    except BCApiError as e:
        return False, f"API Error: {e.message}", None
    except Exception as e:
        return False, str(e), None


# Sidebar - Connection Status
with st.sidebar:
    st.title("Bridge Demo")
    st.divider()

    connected, status_msg, bc_url = check_connection()

    if connected:
        st.success(status_msg)
        if bc_url:
            st.caption(bc_url)
    else:
        st.error(status_msg)
        st.info("Ensure .env is configured and run `az login`")


# Main Content - Home Page
st.title("UNS Bridge Connector Demo")

st.markdown("""
Welcome to the **UNS Bridge Connector** demonstration interface. This tool helps
visualize and test the integration between your Unified Namespace (UNS) and
Microsoft Dynamics 365 Business Central.
""")

st.divider()

# Quick Stats
if connected:
    col1, col2, col3, col4 = st.columns(4)

    with BCClient(get_config_with_token()) as client:
        try:
            orders = client.get_production_orders(status="Released", top=100)
            col1.metric("Released Orders", len(orders))
        except BCApiError:
            col1.metric("Released Orders", "-")

        try:
            work_centers = client.get_work_centers()
            col2.metric("Work Centers", len(work_centers))
        except BCApiError:
            col2.metric("Work Centers", "-")

        try:
            mappings = client.get_uns_topic_mappings(top=100)
            active_mappings = [m for m in mappings if m.status == "Active"]
            col3.metric("Active Mappings", len(active_mappings))
        except BCApiError:
            col3.metric("Active Mappings", "-")

        try:
            inbox = client.get_integration_inbox(top=100)
            pending = [e for e in inbox if e.status == "Received"]
            col4.metric("Pending Events", len(pending))
        except BCApiError:
            col4.metric("Pending Events", "-")

st.divider()

# Demo Flow
st.subheader("Demo Flow")

st.markdown("""
Follow these steps to demonstrate the UNS Bridge integration:

1. **Work Orders** - View released production orders (create one if none exist)
2. **Work Order Routing** - Examine routing operations for the selected order
3. **Shopfloor Execution** - Post execution events with OEE metrics
4. **BC UI** - Open Business Central to verify results
""")

# Quick Actions
st.divider()
st.subheader("Quick Actions")

col1, col2 = st.columns(2)

with col1:
    if st.button("View Work Orders", use_container_width=True):
        st.switch_page("pages/1_Work_Orders.py")

with col2:
    if st.button("Post Execution Event", use_container_width=True):
        st.switch_page("pages/3_Shopfloor_Execution.py")

# Advanced section
st.divider()
with st.expander("Advanced: UNS Mapping"):
    st.markdown("View and register UNS topics for work center mapping in Business Central.")
    if st.button("Open UNS Mapping"):
        st.switch_page("pages/4_UNS_Mapping.py")

# Footer
st.divider()
st.caption("""
**Note:** This is a read-only observer interface. It does not post inventory,
output, capacity, or ledger entries. All KPIs are derived and informational.
""")
