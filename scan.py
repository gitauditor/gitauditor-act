#!/usr/bin/env python3
"""
GitAuditor GitHub Action
Triggers security scans via GitAuditor.io API
"""

import os
import sys
import json
import time
import requests
from typing import Dict, List, Optional, Any, Tuple
from datetime import datetime, timezone
import argparse
from version import get_version, get_version_info

def log(message: str, level: str = "INFO"):
    """Log message with timestamp"""
    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    print(f"[{timestamp}] [{level}] {message}")

def error(message: str):
    """Log error and exit"""
    log(message, "ERROR")
    sys.exit(1)

def set_output(name: str, value: str):
    """Set GitHub Actions output"""
    if "GITHUB_OUTPUT" in os.environ:
        with open(os.environ["GITHUB_OUTPUT"], "a") as f:
            f.write(f"{name}={value}\n")
    print(f"::set-output name={name}::{value}")

def set_summary(content: str):
    """Set GitHub Actions job summary"""
    if "GITHUB_STEP_SUMMARY" in os.environ:
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a") as f:
            f.write(content)

class GitAuditorClient:
    """Client for GitAuditor API"""
    
    def __init__(self, api_url: str, token: str):
        self.api_url = api_url.rstrip('/')
        self.token = token
        self.session = requests.Session()
        self.session.headers.update({
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json',
            'User-Agent': f'GitAuditor-GitHub-Action/{get_version()}'
        })
    
    def get_organization_by_name(self, org_name: str) -> Optional[Dict]:
        """Get organization by GitHub org name"""
        try:
            response = self.session.get(f"{self.api_url}/organizations")
            response.raise_for_status()
            
            orgs = response.json()
            for org in orgs:
                if org.get('external_id') == f'github_{org_name}':
                    return org
            return None
        except Exception as e:
            log(f"Failed to get organization: {e}", "ERROR")
            return None
    
    def create_repository_scan(self, repo_id: str, check_types: List[str]) -> Dict:
        """Create a repository scan"""
        payload = {
            "repository_id": repo_id,
            "configuration": {
                "check_types": check_types
            }
        }
        
        response = self.session.post(f"{self.api_url}/scans/repository", json=payload)
        response.raise_for_status()
        return response.json()
    
    def create_organization_scan(self, org_id: str, check_types: List[str], visibility_filter: List[str]) -> Dict:
        """Create an organization scan"""
        payload = {
            "organization_id": org_id,
            "configuration": {
                "check_types": check_types
            },
            "visibility_filter": visibility_filter
        }
        
        response = self.session.post(f"{self.api_url}/scans/organization", json=payload)
        response.raise_for_status()
        return response.json()
    
    def create_enterprise_scan(self, enterprise_id: str, check_types: List[str], visibility_filter: List[str]) -> Dict:
        """Create an enterprise scan"""
        payload = {
            "enterprise_id": enterprise_id,
            "configuration": {
                "check_types": check_types
            },
            "visibility_filter": visibility_filter
        }
        
        response = self.session.post(f"{self.api_url}/scans/enterprise", json=payload)
        response.raise_for_status()
        return response.json()
    
    def get_scan_status(self, scan_id: str) -> Dict:
        """Get scan status"""
        response = self.session.get(f"{self.api_url}/scans/{scan_id}/status")
        response.raise_for_status()
        return response.json()
    
    def get_issue_instances(self, scan_id: str) -> List[Dict]:
        """Get issue instances for a scan"""
        response = self.session.get(f"{self.api_url}/issues/instances", params={"scan_id": scan_id})
        response.raise_for_status()
        return response.json()

def get_github_context() -> Dict:
    """Get GitHub context information"""
    github_context = {}
    
    # Repository information
    if "GITHUB_REPOSITORY" in os.environ:
        repo_full_name = os.environ["GITHUB_REPOSITORY"]
        github_context["repository"] = repo_full_name
        github_context["owner"], github_context["repo_name"] = repo_full_name.split("/", 1)
    
    # Event information
    if "GITHUB_EVENT_NAME" in os.environ:
        github_context["event"] = os.environ["GITHUB_EVENT_NAME"]
    
    # Reference information
    if "GITHUB_REF" in os.environ:
        github_context["ref"] = os.environ["GITHUB_REF"]
    
    # SHA information
    if "GITHUB_SHA" in os.environ:
        github_context["sha"] = os.environ["GITHUB_SHA"]
    
    return github_context

def wait_for_scan_completion(client: GitAuditorClient, scan_id: str, timeout_minutes: int = 30) -> Dict:
    """Wait for scan to complete"""
    timeout_seconds = timeout_minutes * 60
    start_time = time.time()
    
    log(f"Waiting for scan {scan_id} to complete (timeout: {timeout_minutes}m)")
    
    while time.time() - start_time < timeout_seconds:
        try:
            status = client.get_scan_status(scan_id)
            scan_status = status.get("status", "unknown")
            
            log(f"Scan status: {scan_status}")
            
            if scan_status in ["completed", "failed", "cancelled"]:
                return status
            
            # Wait before next check
            time.sleep(10)
            
        except Exception as e:
            log(f"Error checking scan status: {e}", "WARNING")
            time.sleep(5)
    
    raise TimeoutError(f"Scan {scan_id} did not complete within {timeout_minutes} minutes")

def format_scan_results(scan_status: Dict, issues: List[Dict], output_format: str) -> str:
    """Format scan results for output"""
    if output_format == "json":
        return json.dumps({
            "scan": scan_status,
            "issues": issues
        }, indent=2)
    
    elif output_format == "table":
        # Create a formatted table
        result = []
        result.append("# GitAuditor Scan Results")
        result.append("")
        result.append(f"**Scan ID:** {scan_status.get('scan_id', 'Unknown')}")
        result.append(f"**Status:** {scan_status.get('status', 'Unknown')}")
        result.append(f"**Scope:** {scan_status.get('scope', 'Unknown')}")
        result.append("")
        
        if issues:
            # Group issues by severity
            severity_counts = {"critical": 0, "high": 0, "medium": 0, "low": 0}
            for issue in issues:
                severity = issue.get("severity", "unknown").lower()
                if severity in severity_counts:
                    severity_counts[severity] += 1
            
            result.append("## Issue Summary")
            result.append("")
            result.append("| Severity | Count |")
            result.append("|----------|-------|")
            for severity, count in severity_counts.items():
                result.append(f"| {severity.capitalize()} | {count} |")
            result.append("")
            
            if len(issues) > 0:
                result.append("## Issues Found")
                result.append("")
                for issue in issues[:10]:  # Limit to first 10 issues
                    result.append(f"- **{issue.get('issue_id', 'Unknown')}** ({issue.get('severity', 'unknown')})")
                    if issue.get('context', {}).get('description'):
                        result.append(f"  {issue['context']['description']}")
                
                if len(issues) > 10:
                    result.append(f"... and {len(issues) - 10} more issues")
        else:
            result.append("✅ No security issues found!")
        
        return "\n".join(result)
    
    return f"Scan completed with {len(issues)} issues found"

def generate_sarif_output(issues: List[Dict], scan_info: Dict) -> Dict:
    """Generate SARIF format output"""
    sarif = {
        "$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",
        "version": "2.1.0",
        "runs": [
            {
                "tool": {
                    "driver": {
                        "name": "GitAuditor",
                        "version": "1.0.0",
                        "informationUri": "https://gitauditor.io",
                        "rules": []
                    }
                },
                "results": []
            }
        ]
    }
    
    # Add rules and results
    rules_added = set()
    for issue in issues:
        issue_id = issue.get("issue_id", "unknown")
        
        # Add rule if not already added
        if issue_id not in rules_added:
            rule = {
                "id": issue_id,
                "shortDescription": {
                    "text": issue.get("title", issue_id)
                },
                "fullDescription": {
                    "text": issue.get("description", "")
                },
                "help": {
                    "text": issue.get("remediation", "")
                },
                "defaultConfiguration": {
                    "level": map_severity_to_sarif_level(issue.get("severity", "medium"))
                }
            }
            sarif["runs"][0]["tool"]["driver"]["rules"].append(rule)
            rules_added.add(issue_id)
        
        # Add result
        result = {
            "ruleId": issue_id,
            "message": {
                "text": issue.get("context", {}).get("description", f"Issue detected: {issue_id}")
            },
            "level": map_severity_to_sarif_level(issue.get("severity", "medium")),
            "locations": [
                {
                    "physicalLocation": {
                        "artifactLocation": {
                            "uri": issue.get("context", {}).get("file_path", ".")
                        }
                    }
                }
            ]
        }
        sarif["runs"][0]["results"].append(result)
    
    return sarif

def map_severity_to_sarif_level(severity: str) -> str:
    """Map GitAuditor severity to SARIF level"""
    mapping = {
        "critical": "error",
        "high": "error", 
        "medium": "warning",
        "low": "note"
    }
    return mapping.get(severity.lower(), "warning")

def main():
    """Main function"""
    version_info = get_version_info()
    log(f"Starting GitAuditor scan (Action v{version_info['version']})")
    
    # Get configuration from environment
    api_url = os.environ.get("API_URL", "https://api.gitauditor.io")
    token = os.environ.get("GITAUDITOR_TOKEN")
    scan_type = os.environ.get("SCAN_TYPE", "repository")
    organization_id = os.environ.get("ORGANIZATION_ID")
    enterprise_id = os.environ.get("ENTERPRISE_ID")
    check_types_str = os.environ.get("CHECK_TYPES", "branch_protection,admin_rights,dependabot,secrets,secret_scanning")
    visibility_filter_str = os.environ.get("VISIBILITY_FILTER", "public,internal,private")
    fail_on_issues = os.environ.get("FAIL_ON_ISSUES", "false").lower() == "true"
    severity_threshold = os.environ.get("SEVERITY_THRESHOLD", "medium")
    output_format = os.environ.get("OUTPUT_FORMAT", "table")
    wait_for_completion = os.environ.get("WAIT_FOR_COMPLETION", "true").lower() == "true"
    timeout = int(os.environ.get("TIMEOUT", "30"))
    
    if not token:
        error("GITAUDITOR_TOKEN environment variable is required")
    
    # Parse lists
    check_types = [ct.strip() for ct in check_types_str.split(",") if ct.strip()]
    visibility_filter = [vf.strip() for vf in visibility_filter_str.split(",") if vf.strip()]
    
    # Get GitHub context
    github_context = get_github_context()
    log(f"GitHub context: {github_context}")
    
    # Initialize client
    client = GitAuditorClient(api_url, token)
    
    try:
        # Create scan based on type
        if scan_type == "repository":
            if not github_context.get("repository"):
                error("Repository context not available")
            
            # For repository scans, we need to get the organization and repository info
            owner = github_context["owner"]
            org = client.get_organization_by_name(owner)
            if not org:
                error(f"Organization '{owner}' not found in GitAuditor")
            
            # For now, use a placeholder repository ID
            # In a real implementation, you'd need to get the repository ID from GitAuditor
            repo_id = f"github_{github_context['repository'].replace('/', '_')}"
            
            log(f"Creating repository scan for {github_context['repository']}")
            scan_result = client.create_repository_scan(repo_id, check_types)
            
        elif scan_type == "organization":
            if not organization_id:
                # Try to get organization from GitHub context
                if github_context.get("owner"):
                    org = client.get_organization_by_name(github_context["owner"])
                    if org:
                        organization_id = org["id"]
                    else:
                        error(f"Organization '{github_context['owner']}' not found in GitAuditor")
                else:
                    error("organization_id is required for organization scans")
            
            log(f"Creating organization scan for {organization_id}")
            scan_result = client.create_organization_scan(organization_id, check_types, visibility_filter)
            
        elif scan_type == "enterprise":
            if not enterprise_id:
                error("enterprise_id is required for enterprise scans")
            
            log(f"Creating enterprise scan for {enterprise_id}")
            scan_result = client.create_enterprise_scan(enterprise_id, check_types, visibility_filter)
            
        else:
            error(f"Invalid scan_type: {scan_type}")
        
        scan_id = scan_result["scan_id"]
        log(f"Scan created with ID: {scan_id}")
        
        # Set initial outputs
        set_output("scan_id", str(scan_id))
        set_output("status", "queued")
        
        # Wait for completion if requested
        final_status = None
        issues = []
        
        if wait_for_completion:
            try:
                final_status = wait_for_scan_completion(client, str(scan_id), timeout)
                log(f"Scan completed with status: {final_status.get('status')}")
                
                # Get issues
                issues = client.get_issue_instances(str(scan_id))
                log(f"Found {len(issues)} issues")
                
            except TimeoutError as e:
                log(str(e), "WARNING")
                final_status = client.get_scan_status(str(scan_id))
        else:
            log("Not waiting for scan completion")
            final_status = {"status": "queued", "scan_id": scan_id}
        
        # Count issues by severity
        severity_counts = {"critical": 0, "high": 0, "medium": 0, "low": 0}
        for issue in issues:
            severity = issue.get("severity", "unknown").lower()
            if severity in severity_counts:
                severity_counts[severity] += 1
        
        # Set outputs
        set_output("status", final_status.get("status", "unknown"))
        set_output("issues_found", str(len(issues)))
        set_output("critical_issues", str(severity_counts["critical"]))
        set_output("high_issues", str(severity_counts["high"]))
        set_output("medium_issues", str(severity_counts["medium"]))
        set_output("low_issues", str(severity_counts["low"]))
        set_output("scan_url", f"{api_url.replace('api.', 'app.')}/scans/{scan_id}")
        
        # Generate output
        formatted_results = format_scan_results(final_status, issues, output_format)
        
        # Set job summary
        set_summary(formatted_results)
        
        # Generate SARIF if requested
        if "sarif" in output_format:
            sarif_data = generate_sarif_output(issues, final_status)
            sarif_file = "gitauditor-results.sarif"
            with open(sarif_file, "w") as f:
                json.dump(sarif_data, f, indent=2)
            set_output("sarif_file", sarif_file)
            log(f"SARIF file generated: {sarif_file}")
        
        # Check if we should fail
        if fail_on_issues and len(issues) > 0:
            # Check severity threshold
            severity_levels = {"low": 1, "medium": 2, "high": 3, "critical": 4}
            threshold_level = severity_levels.get(severity_threshold.lower(), 2)
            
            significant_issues = [
                issue for issue in issues 
                if severity_levels.get(issue.get("severity", "medium").lower(), 2) >= threshold_level
            ]
            
            if significant_issues:
                error(f"Scan found {len(significant_issues)} issues at or above {severity_threshold} severity")
        
        log("GitAuditor scan completed successfully")
        
    except requests.exceptions.RequestException as e:
        error(f"API request failed: {e}")
    except Exception as e:
        error(f"Scan failed: {e}")

if __name__ == "__main__":
    main()