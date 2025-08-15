"""
Version utilities for GitAuditor GitHub Action
"""
import os
from pathlib import Path


def get_version() -> str:
    """
    Get the current version of GitAuditor Action.

    Attempts to read version from:
    1. VERSION file in project root
    2. Environment variable GITAUDITOR_ACTION_VERSION
    3. Git tag (if available)
    4. Default fallback version

    Returns:
        str: Version string
    """
    # Try to read from VERSION file
    try:
        version_file = Path(__file__).parent / "VERSION"
        if version_file.exists():
            return version_file.read_text().strip()
    except Exception:
        pass

    # Try environment variable
    env_version = os.getenv("GITAUDITOR_ACTION_VERSION")
    if env_version:
        return env_version.strip()

    # Try git tag (if available)
    try:
        import subprocess

        result = subprocess.run(
            ["git", "describe", "--tags", "--exact-match", "HEAD"],
            capture_output=True,
            text=True,
            cwd=Path(__file__).parent,
        )
        if result.returncode == 0:
            return result.stdout.strip().lstrip("v")
    except Exception:
        pass

    # Fallback version
    return "0.1.0-dev"


def get_version_info() -> dict:
    """
    Get detailed version information.

    Returns:
        dict: Version information including version, git commit, etc.
    """
    version = get_version()

    info = {
        "version": version,
        "name": "GitAuditor Posture Scan Action",
        "description": "GitHub Action for automated git posture scanning via GitAuditor.io",
    }

    # Try to get git commit info
    try:
        import subprocess

        result = subprocess.run(
            ["git", "rev-parse", "HEAD"],
            capture_output=True,
            text=True,
            cwd=Path(__file__).parent,
        )
        if result.returncode == 0:
            info["git_commit"] = result.stdout.strip()[:8]
    except Exception:
        pass

    # Try to get git branch
    try:
        import subprocess

        result = subprocess.run(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"],
            capture_output=True,
            text=True,
            cwd=Path(__file__).parent,
        )
        if result.returncode == 0:
            info["git_branch"] = result.stdout.strip()
    except Exception:
        pass

    # Add Docker image version info
    info["docker_image"] = f"gitauditor/gitauditor-act:{version}"
    
    # Add marketplace info
    info["marketplace_url"] = "https://github.com/marketplace/actions/gitauditor-security-scan"
    
    return info


if __name__ == "__main__":
    # When run directly, print version info
    import json
    print(json.dumps(get_version_info(), indent=2))