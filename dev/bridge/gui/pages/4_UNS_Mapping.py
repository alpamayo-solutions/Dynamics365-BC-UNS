"""
UNS Mapping Page - Manage UNS topic to work center mappings.
"""

import sys
from pathlib import Path

import streamlit as st

sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from bridge.client import BCApiError, BCClient
from bridge.config import get_config_with_token
from bridge.models import UNSTopicMapping

st.set_page_config(
    page_title="UNS Mapping - UNS Bridge",
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
    st.title("UNS Mapping")
    st.divider()

    status_filter = st.selectbox(
        "Status Filter",
        ["All", "Active", "Inactive"],
        index=0,
    )

    if st.button("Refresh", use_container_width=True):
        st.rerun()


# Main Content
st.title("UNS Topic Mappings")

st.markdown("""
View registered UNS topics and their work center mappings.
The bridge registers topics; ERP users map them to work centers in Business Central.
""")

client = get_client()
if not client:
    st.stop()

with client:
    # Fetch mappings
    try:
        filter_status = None if status_filter == "All" else status_filter
        mappings = client.get_uns_topic_mappings(status=filter_status, top=100)
    except BCApiError as e:
        if e.status_code == 404:
            mappings = []
            st.info("UNS Topic Mappings API not available. Ensure the BC extension is deployed.")
        else:
            st.error(f"Failed to fetch mappings: {e.message}")
            mappings = []

    # Stats
    col1, col2, col3 = st.columns(3)
    with col1:
        st.metric("Total Mappings", len(mappings))
    with col2:
        active = len([m for m in mappings if m.status == "Active"])
        st.metric("Active", active)
    with col3:
        unmapped = len([m for m in mappings if not m.work_center_no])
        st.metric("Unmapped Topics", unmapped)

    st.divider()

    # Mappings table
    st.subheader("Existing Mappings")

    if not mappings:
        st.info("No mappings found. Create one below.")
    else:
        for mapping in mappings:
            with st.container():
                col1, col2, col3, col4, col5 = st.columns([4, 2, 2, 2, 2])

                with col1:
                    st.markdown(f"**`{mapping.uns_topic}`**")
                    if mapping.description:
                        st.caption(mapping.description)

                with col2:
                    if mapping.work_center_no:
                        st.text(mapping.work_center_no)
                    else:
                        st.caption("Not mapped in ERP")

                with col3:
                    if mapping.status == "Active":
                        st.markdown("Active")
                    else:
                        st.markdown("*Inactive*")

                with col4:
                    # Toggle status button
                    if mapping.status == "Active":
                        if st.button("Deactivate", key=f"toggle_{mapping.uns_topic}", use_container_width=True):
                            try:
                                client.update_uns_topic_mapping(mapping.uns_topic, {"status": "Inactive"})
                                st.rerun()
                            except BCApiError as e:
                                st.error(f"Failed: {e.message}")
                    else:
                        if st.button("Activate", key=f"toggle_{mapping.uns_topic}", use_container_width=True):
                            try:
                                client.update_uns_topic_mapping(mapping.uns_topic, {"status": "Active"})
                                st.rerun()
                            except BCApiError as e:
                                st.error(f"Failed: {e.message}")

                with col5:
                    if st.button("Delete", key=f"delete_{mapping.uns_topic}", use_container_width=True):
                        try:
                            client.delete_uns_topic_mapping(mapping.uns_topic)
                            st.success(f"Deleted mapping for {mapping.uns_topic}")
                            st.rerun()
                        except BCApiError as e:
                            st.error(f"Failed: {e.message}")

                st.divider()

    # Create new mapping
    st.subheader("Register New Topic")
    st.caption("Register a UNS topic. Work center mapping is done by ERP users in Business Central.")

    with st.form("create_mapping"):
        col1, col2 = st.columns(2)

        with col1:
            uns_topic = st.text_input(
                "UNS Topic",
                placeholder="mb/v1/nw/edge/fill/k5/assy",
                help="Full UNS topic path (e.g., mb/v1/nw/edge/fill/k5/assy)",
            )

            description = st.text_input(
                "Description",
                placeholder="Assembly station K5",
                help="Human-readable description of this topic",
            )

        with col2:
            source_system = st.text_input(
                "Source System",
                placeholder="EdgeNode-K5",
                help="Identifier of the source system/device",
            )

        new_status = st.radio(
            "Status",
            ["Active", "Inactive"],
            horizontal=True,
        )

        if st.form_submit_button("Register Topic", type="primary", use_container_width=True):
            if not uns_topic:
                st.error("UNS Topic is required")
            else:
                new_mapping = UNSTopicMapping(
                    uns_topic=uns_topic,
                    work_center_no=None,
                    status=new_status,
                    description=description if description else None,
                    source_system=source_system if source_system else None,
                )

                try:
                    client.create_uns_topic_mapping(new_mapping)
                    st.success(f"Registered topic: {uns_topic}")
                    st.rerun()
                except BCApiError as e:
                    st.error(f"Failed to register topic: {e.message}")

# Quick reference
st.divider()
with st.expander("UNS Topic Naming Convention"):
    st.markdown("""
    **Recommended UNS topic structure:**

    ```
    <enterprise>/<site>/<area>/<line>/<cell>/<asset>
    ```

    **Examples:**
    - `mb/v1/nw/edge/fill/k5/assy` - Assembly at cell K5
    - `mb/v1/nw/edge/pack/line1` - Packaging line 1
    - `acme/plant1/prod/line2/station3` - Station 3 on line 2

    **Topic Wildcards:**
    - Topics should be specific to a single work center
    - Avoid wildcards (+, #) in mapped topics
    """)

# Navigation
st.divider()
col1, col2 = st.columns(2)
with col1:
    if st.button("Shopfloor Execution", use_container_width=True):
        st.switch_page("pages/3_Shopfloor_Execution.py")
with col2:
    if st.button("Home", use_container_width=True):
        st.switch_page("app.py")
