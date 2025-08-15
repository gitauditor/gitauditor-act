# GitAuditor Posture Scan Action

[![GitHub Marketplace](https://img.shields.io/badge/Marketplace-GitAuditor%20Posture%20Scan-blue.svg?colorA=24292e&colorB=0366d6&style=flat&longCache=true&logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAM6wAADOsB5dZE0gAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAAERSURBVCiRhZG/SsMxFEZPfsVJ61jbxaF0cRQRcRJ9hlYn30IHN/+9iquDCOIsblIrOjqKgy5aKoJQj4n3NwhJgUYyoFw/8PvyJYHArT+zw+f93v1+yyBYU3VfGf9lXUkN8kRdm73QfZ4Uu2z73+pO4mQUGJ/9zGo/TGW89Q8oLnZj/s1PuJ9Ev9p+7Axt1M5lmBNM4tMTqmvVtUu1sMb8Bi8NuHW3kJdBjxX7rMmTsQz2y0ysZJ6x4MRdBxh4AXYQTM9z8EKg0TwXpzJrFFdTPLWFiOaTpfJXHhTUmyUmVhJnNzIJdDT4x9J4lfqjl7cWJ3JtdPKhRg==)](https://github.com/marketplace/actions/gitauditor-posture-scan)

A GitHub Action for automated git posture scanning of your repositories using [GitAuditor.io](https://gitauditor.io), a comprehensive Git Posture Management (GPM) solution.

## Features

- 🔍 **Comprehensive Git Posture Scanning**: Detect misconfigurations, vulnerabilities, and compliance issues
- 🏢 **Multi-Scope Support**: Scan individual repositories, entire organizations, or enterprises
- 🎯 **Customizable Checks**: Choose specific security checks to run based on your needs
- 📊 **Multiple Output Formats**: Get results in table, JSON, or SARIF format
- 🚨 **PR Integration**: Automatically comment on pull requests with security findings
- ⚡ **Fast & Reliable**: Efficient scanning with configurable timeouts
- 🔗 **GitHub Integration**: Native integration with GitHub Security tab via SARIF uploads

## Supported Security Checks

- **Branch Protection**: Verify branch protection rules and policies
- **Admin Rights**: Detect excessive administrative permissions
- **Dependabot**: Check for dependency vulnerability management
- **Secrets**: Scan for exposed secrets and sensitive information
- **Secret Scanning**: Verify GitHub secret scanning configuration
- **IAM**: Analyze identity and access management settings
- **PR Performance**: Evaluate pull request security practices

## Quick Start

### 1. Get Your GitAuditor Token

1. Sign up at [GitAuditor.io](https://gitauditor.io)
2. Generate an API token from your dashboard
3. Add the token to your repository secrets as `GITAUDITOR_TOKEN`

### 2. Basic Repository Scan

Create `.github/workflows/security-scan.yml`:

```yaml
name: Security Scan

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  contents: read        # Read repository metadata and files
  security-events: write # Upload SARIF results (optional)

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: gitauditor/gitauditor-act@main
        with:
          gitauditor_token: ${{ secrets.GITAUDITOR_TOKEN }}
```

## Usage

### Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `gitauditor_token` | GitAuditor API token | ✅ | - |
| `api_url` | GitAuditor API base URL | ❌ | `https://api.gitauditor.io` |
| `scan_type` | Scan scope: `repository`, `organization`, or `enterprise` | ❌ | `repository` |
| `organization_id` | Organization ID (required for org/enterprise scans) | ❌ | - |
| `enterprise_id` | Enterprise ID (required for enterprise scans) | ❌ | - |
| `check_types` | Comma-separated list of checks to run | ❌ | `branch_protection,admin_rights,dependabot,secrets,secret_scanning` |
| `visibility_filter` | Repository visibility filter | ❌ | `public,internal,private` |
| `fail_on_issues` | Fail the action if issues are found | ❌ | `false` |
| `severity_threshold` | Minimum severity to report | ❌ | `medium` |
| `output_format` | Output format: `table`, `json`, or `sarif` | ❌ | `table` |
| `wait_for_completion` | Wait for scan to complete | ❌ | `true` |
| `timeout` | Timeout in minutes | ❌ | `30` |

### Outputs

| Output | Description |
|--------|-------------|
| `scan_id` | The ID of the created scan |
| `status` | Final status of the scan |
| `issues_found` | Number of security issues found |
| `critical_issues` | Number of critical severity issues |
| `high_issues` | Number of high severity issues |
| `medium_issues` | Number of medium severity issues |
| `low_issues` | Number of low severity issues |
| `scan_url` | URL to view detailed results |
| `sarif_file` | Path to generated SARIF file |

## Examples

### Repository Security Scan

```yaml
- uses: gitauditor/gitauditor-act@main
  with:
    gitauditor_token: ${{ secrets.GITAUDITOR_TOKEN }}
    scan_type: repository
    check_types: 'branch_protection,secrets,dependabot'
    fail_on_issues: true
    severity_threshold: high
```

### Organization-Wide Scan

```yaml
- uses: gitauditor/gitauditor-act@main
  with:
    gitauditor_token: ${{ secrets.GITAUDITOR_TOKEN }}
    scan_type: organization
    organization_id: ${{ vars.ORGANIZATION_ID }}
    visibility_filter: 'public,private'
    output_format: 'table,sarif'
```

### Pull Request Security Check

```yaml
name: PR Security Check
on:
  pull_request:
    types: [opened, synchronize]

permissions:
  contents: read        # Read repository metadata
  security-events: write # Upload SARIF results
  pull-requests: write  # Comment on PRs (optional)

jobs:
  security-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run Security Scan
        id: scan
        uses: gitauditor/gitauditor-act@main
        with:
          gitauditor_token: ${{ secrets.GITAUDITOR_TOKEN }}
          check_types: 'secrets,branch_protection'
          fail_on_issues: true
          severity_threshold: medium
      
      - name: Upload SARIF
        if: always()
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: ${{ steps.scan.outputs.sarif_file }}
```

### Scheduled Organization Audit

```yaml
name: Weekly Security Audit
on:
  schedule:
    - cron: '0 2 * * 1'  # Every Monday at 2 AM

permissions:
  contents: read        # Read repository metadata
  security-events: write # Upload SARIF results (optional)

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: gitauditor/gitauditor-act@main
        with:
          gitauditor_token: ${{ secrets.GITAUDITOR_TOKEN }}
          scan_type: organization
          organization_id: ${{ vars.ORGANIZATION_ID }}
          timeout: 60
          output_format: 'table,sarif'
```

## Advanced Configuration

### Custom Check Selection

Available check types:
- `branch_protection` - Branch protection rule validation
- `admin_rights` - Administrative permission analysis
- `dependabot` - Dependency vulnerability management
- `secrets` - Secret exposure detection
- `secret_scanning` - GitHub secret scanning verification
- `iam` - Identity and access management
- `pr_performance` - Pull request security practices

```yaml
check_types: 'branch_protection,secrets,iam'
```

### Severity Levels

- `low` - Minor security recommendations
- `medium` - Moderate security issues
- `high` - Significant security vulnerabilities
- `critical` - Severe security risks requiring immediate attention

### Output Formats

- `table` - Human-readable table format for job summaries
- `json` - Machine-readable JSON format
- `sarif` - SARIF format for GitHub Security tab integration

## SARIF Integration

The action can generate SARIF (Static Analysis Results Interchange Format) files for integration with GitHub's Security tab:

```yaml
- uses: gitauditor/gitauditor-act@main
  with:
    gitauditor_token: ${{ secrets.GITAUDITOR_TOKEN }}
    output_format: 'sarif'

- uses: github/codeql-action/upload-sarif@v3
  if: always()
  with:
    sarif_file: gitauditor-results.sarif
```

## Permissions

GitAuditor Action operates with **read-only** permissions by default. The action only reads repository metadata and configuration to perform security scans. No changes are made to your repository.

### Required Permissions

```yaml
permissions:
  contents: read        # Read repository metadata and files (required)
  security-events: write # Upload SARIF results to GitHub Security tab (optional)
  pull-requests: write  # Comment on pull requests with findings (optional)
```

- **`contents: read`** - Required for accessing repository information and configuration
- **`security-events: write`** - Only needed if uploading SARIF results to GitHub Security tab
- **`pull-requests: write`** - Only needed if you want the action to comment on PRs

### Minimal Permissions Example

For the most restrictive setup with read-only access:

```yaml
permissions:
  contents: read  # Only read access needed

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: gitauditor/gitauditor-act@main
        with:
          gitauditor_token: ${{ secrets.GITAUDITOR_TOKEN }}
```

## Security Considerations

- Store your GitAuditor token in GitHub Secrets, never in code
- Use organization-level secrets for organization-wide scans
- Consider using GitHub's OIDC provider for enhanced security
- Regularly rotate your API tokens
- Review scan results in the GitAuditor dashboard for detailed analysis
- The action operates with read-only permissions and never modifies your repository

## Troubleshooting

### Common Issues

**"Organization not found"**
- Ensure your organization is registered in GitAuditor
- Verify the organization ID is correct
- Check that your token has access to the organization

**"Timeout waiting for scan"**
- Increase the `timeout` value for large scans
- Consider running scans during off-peak hours
- Check GitAuditor service status

**"Authentication failed"**
- Verify your `GITAUDITOR_TOKEN` secret is set correctly
- Ensure the token hasn't expired
- Check token permissions in GitAuditor dashboard

### Getting Help

- 📖 [GitAuditor Documentation](https://docs.gitauditor.io)
- 💬 [Community Support](https://github.com/gitauditor/gitauditor-act/discussions)
- 🐛 [Report Issues](https://github.com/gitauditor/gitauditor-act/issues)
- 📧 [Contact Support](mailto:support@gitauditor.io)

## Local Testing

You can test the GitAuditor Action workflows locally using [act](https://github.com/nektos/act) before committing changes.

### Prerequisites

1. **Install act**:
   - **macOS**: `brew install act`
   - **Linux**: `brew install act` or `curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash`

2. **Configure secrets** (copy and modify the example):
   ```bash
   cp .secrets.example .secrets
   # Edit .secrets with your actual GitAuditor token
   ```

### Testing Workflows

Run the interactive testing script:

```bash
./test-workflows.sh
```

This script will:
- ✅ Check if `act` is installed (with OS-specific installation instructions)
- ✅ Validate your `.secrets` file and `GITAUDITOR_TOKEN`
- ✅ List all available workflows
- ✅ Run interactive dry-runs of selected workflows

### Manual Testing

You can also run workflows manually:

```bash
# Dry-run a specific workflow
act workflow_dispatch --dryrun -W .github/workflows/example-repository-scan.yml --secret-file .secrets

# List all workflows
act -l

# Run a workflow (actually execute, not just dry-run)
act workflow_dispatch -W .github/workflows/example-repository-scan.yml --secret-file .secrets
```

**Note**: The `.secrets` file is automatically ignored by git to prevent accidental commits of sensitive information.

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## License

This action is released under the [MIT License](LICENSE).

---

Made with ❤️ by the [GitAuditor.io](https://gitauditor.io) team

> **Note**: This action follows semantic versioning. Check our [releases](https://github.com/gitauditor/gitauditor-act/releases) for the latest version.
