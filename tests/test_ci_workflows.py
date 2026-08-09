"""Regression checks for GitHub Actions workflow contracts."""

from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]


def _read(relative: str) -> str:
    return (REPO_ROOT / relative).read_text(encoding="utf-8")


def test_sbom_workflow_runs_only_for_main_pushes_and_main_pull_requests():
    workflow = _read(".github/workflows/sbom.yml")

    assert "push:" in workflow
    assert "pull_request:" in workflow
    assert workflow.count("branches: [main]") == 2


def test_sbom_workflow_generates_scans_and_uploads_artifacts():
    workflow = _read(".github/workflows/sbom.yml")

    assert "Generate SBOM" in workflow
    assert "aquasec/trivy:0.58.2 fs" in workflow
    assert "Scan SBOM with Trivy" in workflow
    assert "aquasec/trivy:0.58.2 sbom" in workflow
    assert "--format table" in workflow
    assert "--exit-code 1" in workflow
    assert "--severity HIGH,CRITICAL" in workflow
    assert "actions/upload-artifact@v4" in workflow
    assert "sboms/*.cdx.json" in workflow
    assert "trivy-reports/*.trivy.txt" in workflow


def test_sbom_workflow_keeps_platform_publish_disabled():
    workflow = _read(".github/workflows/sbom.yml")

    assert "# - name: Publish SBOMs to Alpamayo Intelligence" in workflow
    assert "#   if: github.event_name == 'push' && github.ref == 'refs/heads/main'" in workflow
    assert "#     artifact-files: sboms/*.cdx.json" in workflow
