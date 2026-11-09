"""Configuration management for Bridge CLI.

Two connection modes:

- SaaS (default): ``BC_TENANT`` + ``BC_ENV``, bearer token from ``az account get-access-token``.
- On-prem / container: ``BC_API_BASE_URL`` (e.g. ``http://bcserver:7048/BC/api``), with basic auth
  ``BC_USERNAME`` / ``BC_PASSWORD`` when set (NavUserPassword).

The company is ``BC_COMPANY`` (GUID). When it is unset, ``BC_COMPANY_NAME`` is resolved to the
first matching company via ``/v2.0/companies`` (see ``BCClient.company_id``).
"""

import os
import subprocess
from functools import lru_cache
from pathlib import Path

from dotenv import load_dotenv
from pydantic import BaseModel

SAAS_API_HOST = "https://api.businesscentral.dynamics.com"


def find_project_root() -> Path:
    """Find the project root by looking for a .env file above this package."""
    current = Path(__file__).resolve().parent
    while current != current.parent:
        if (current / ".env").exists():
            return current
        current = current.parent
    # Fallback: repo root (dev/bridge/bridge -> repo)
    return Path(__file__).resolve().parent.parent.parent.parent


class Config(BaseModel):
    """Configuration loaded from environment."""

    bc_tenant: str | None = None
    bc_env: str | None = None
    bc_company: str | None = None
    bc_company_name: str | None = None
    api_base_url: str | None = None
    username: str | None = None
    password: str | None = None
    access_token: str | None = None

    @property
    def is_saas(self) -> bool:
        return not self.api_base_url

    @property
    def api_root(self) -> str:
        """Root of the BC API, ending in ``/api`` (no trailing slash)."""
        if self.api_base_url:
            return self.api_base_url.rstrip("/")
        return f"{SAAS_API_HOST}/v2.0/{self.bc_tenant}/{self.bc_env}/api"

    @property
    def display_target(self) -> str:
        if self.is_saas:
            return f"SaaS {self.bc_tenant}/{self.bc_env}"
        return f"On-prem {self.api_root}"

    def standard_api_url(self, company_id: str) -> str:
        """Standard API v2.0 URL for a company."""
        return f"{self.api_root}/v2.0/companies({company_id})"

    def custom_api_url(self, company_id: str) -> str:
        """Custom Shopfloor API URL for a company."""
        return f"{self.api_root}/alpamayo/shopfloor/v1.0/companies({company_id})"


def get_token_from_az_cli() -> str | None:
    """Get a BC access token from the Azure CLI."""
    try:
        result = subprocess.run(
            [
                "az",
                "account",
                "get-access-token",
                "--resource",
                SAAS_API_HOST,
                "--query",
                "accessToken",
                "--output",
                "tsv",
            ],
            capture_output=True,
            text=True,
            check=True,
        )
        token = result.stdout.strip()
        return token or None
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None


@lru_cache
def load_config() -> Config:
    """Load configuration from the environment (and the repo-root .env, if present)."""
    env_file = find_project_root() / ".env"
    if env_file.exists():
        load_dotenv(env_file)

    config = Config(
        bc_tenant=os.getenv("BC_TENANT") or None,
        bc_env=os.getenv("BC_ENV") or None,
        bc_company=os.getenv("BC_COMPANY") or None,
        bc_company_name=os.getenv("BC_COMPANY_NAME") or None,
        api_base_url=os.getenv("BC_API_BASE_URL") or None,
        username=os.getenv("BC_USERNAME") or None,
        password=os.getenv("BC_PASSWORD") or None,
        access_token=os.getenv("ACCESS_TOKEN") or None,
    )

    if config.is_saas and not (config.bc_tenant and config.bc_env):
        raise ValueError(
            "Missing BC_TENANT/BC_ENV (SaaS) or BC_API_BASE_URL (on-prem/container).\n"
            f"Looked for .env at: {env_file}"
        )
    if not (config.bc_company or config.bc_company_name):
        raise ValueError("Set BC_COMPANY (GUID) or BC_COMPANY_NAME.")
    return config


def get_config_with_token() -> Config:
    """Get config; in SaaS mode fetch a token from the Azure CLI when none is set."""
    config = load_config()
    if config.is_saas and not config.access_token:
        token = get_token_from_az_cli()
        if token:
            config = config.model_copy(update={"access_token": token})
    return config
