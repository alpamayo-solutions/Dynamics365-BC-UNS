"""Configuration management for Bridge CLI."""

import os
import subprocess
from pathlib import Path
from functools import lru_cache

from dotenv import load_dotenv
from pydantic import BaseModel


def find_project_root() -> Path:
    """Find the project root by looking for .env file."""
    current = Path(__file__).resolve().parent
    while current != current.parent:
        if (current / ".env").exists():
            return current
        # Also check parent dirs up to 3 levels
        current = current.parent
    # Fallback: go up from dev/bridge/bridge to project root
    return Path(__file__).resolve().parent.parent.parent.parent


class Config(BaseModel):
    """Configuration loaded from environment."""

    bc_tenant: str
    bc_env: str
    bc_company: str
    access_token: str | None = None

    @property
    def base_url(self) -> str:
        """Base URL for BC API."""
        return f"https://api.businesscentral.dynamics.com/v2.0/{self.bc_tenant}/{self.bc_env}"

    @property
    def standard_api_url(self) -> str:
        """Standard API URL with company."""
        return f"{self.base_url}/api/v2.0/companies({self.bc_company})"

    @property
    def custom_api_url(self) -> str:
        """Custom Shopfloor API URL with company."""
        return f"{self.base_url}/api/alpamayo/shopfloor/v1.0/companies({self.bc_company})"


def get_token_from_az_cli() -> str | None:
    """Get access token from Azure CLI."""
    try:
        result = subprocess.run(
            [
                "az",
                "account",
                "get-access-token",
                "--resource",
                "https://api.businesscentral.dynamics.com",
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
        return token if token else None
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None


@lru_cache
def load_config() -> Config:
    """Load configuration from .env file."""
    project_root = find_project_root()
    env_file = project_root / ".env"

    if env_file.exists():
        load_dotenv(env_file)

    bc_tenant = os.getenv("BC_TENANT")
    bc_env = os.getenv("BC_ENV")
    bc_company = os.getenv("BC_COMPANY")

    if not all([bc_tenant, bc_env, bc_company]):
        raise ValueError(
            "Missing required environment variables: BC_TENANT, BC_ENV, BC_COMPANY\n"
            f"Looked for .env at: {env_file}"
        )

    return Config(
        bc_tenant=bc_tenant,
        bc_env=bc_env,
        bc_company=bc_company,
        access_token=os.getenv("ACCESS_TOKEN"),
    )


def get_config_with_token() -> Config:
    """Get config, fetching token from Azure CLI if needed."""
    config = load_config()

    if not config.access_token:
        token = get_token_from_az_cli()
        if token:
            config = config.model_copy(update={"access_token": token})

    return config
