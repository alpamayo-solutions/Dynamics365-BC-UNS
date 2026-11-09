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


def check_connection() -> tuple[bool, str, str | None]:
    """Check BC API connection status. Returns (connected, message, url)."""
    try:
        config = get_config_with_token()
        with BCClient(config) as client:
            companies = client.get_companies()
            if companies:
                return True, f"Connected: {config.display_target}", config.api_root
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
        st.info("Ensure .env is configured (SaaS: run `az login`; on-prem: BC_API_BASE_URL)")


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
    col1, col2, col3 = st.columns(3)

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
            col3.metric("Machine Centers", len(client.get_machine_centers()))
        except BCApiError:
            col3.metric("Machine Centers", "-")

st.divider()

# Demo Flow
st.subheader("Demo Flow")

st.markdown("""
1. **Work Orders** - View released production orders (create one if none exist)
2. **Steps** - Examine the steps (routing lines) of an order with their execution state
3. **CLI** - Write execution facts with `bridge finish`, `bridge person-time add`, `bridge note`,
   `bridge move`, `bridge plan`, or run `bridge e2e --order <no> --yes`
4. **BC UI** - Open Business Central to verify results
""")

if st.button("View Work Orders", use_container_width=True):
    st.switch_page("pages/1_Work_Orders.py")

# Footer
st.divider()
st.caption("""
**Note:** This interface is read-only. Writes go through the CLI; Business Central posts output
only when ALP Shopfloor Setup "Post Output" is on.
""")
