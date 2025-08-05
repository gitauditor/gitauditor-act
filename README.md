# GitAuditor Security Scan Action

[![GitHub Marketplace](https://img.shields.io/badge/Marketplace-GitAuditor%20Security%20Scan-blue.svg?colorA=24292e&colorB=0366d6&style=flat&longCache=true&logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAM6wAADOsB5dZE0gAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAAERSURBVCiRhZG/SsMxFEZPfsVJ61jbxaF0cRQRcRJ9hlYn30IHN/+9iquDCOIsblIrOjqKgy5aKoJQj4n3NwhJgUYyoFw/8PvyJYHArT+zw+f93v1+yyBYU3VfGf9lXUkN8kRdm73QfZ4Uu2z73+pO4mQUGJ/9zGo/TGW89Q8oLnZj/s1PuJ9Ev9p+7Axt1M5lmBNM4tMTqmvVtUu1sMb8Bi8NuHW3kJdBjxX7rMmTsQz2y0ysZJ6x4MRdBxh4AXYQTM9z8EKg0TwXpzJrFFdTPLWFiOaTpfJXHhTUmyUmVhJnNzIJdDT4x9J4lfqjl7cWJ3JtdPKhRg==)](https://github.com/marketplace/actions/gitauditor-security-scan)

A GitHub Action for automated security scanning of your repositories using [GitAuditor.io](https://gitauditor.io), a comprehensive Git posture management solution.

## Features

- 🔍 **Comprehensive Security Scanning**: Detect misconfigurations, vulnerabilities, and compliance issues
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

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: gitauditor/gitauditor-action@v1
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
- uses: gitauditor/gitauditor-action@v1
  with:
    gitauditor_token: ${{ secrets.GITAUDITOR_TOKEN }}
    scan_type: repository
    check_types: 'branch_protection,secrets,dependabot'
    fail_on_issues: true
    severity_threshold: high
```

### Organization-Wide Scan

```yaml
- uses: gitauditor/gitauditor-action@v1
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

jobs:
  security-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run Security Scan
        id: scan
        uses: gitauditor/gitauditor-action@v1
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

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: gitauditor/gitauditor-action@v1
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
- uses: gitauditor/gitauditor-action@v1
  with:
    gitauditor_token: ${{ secrets.GITAUDITOR_TOKEN }}
    output_format: 'sarif'

- uses: github/codeql-action/upload-sarif@v3
  if: always()
  with:
    sarif_file: gitauditor-results.sarif
```

## Security Considerations

- Store your GitAuditor token in GitHub Secrets, never in code
- Use organization-level secrets for organization-wide scans
- Consider using GitHub's OIDC provider for enhanced security
- Regularly rotate your API tokens
- Review scan results in the GitAuditor dashboard for detailed analysis

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
- 💬 [Community Support](https://github.com/gitauditor/gitauditor-action/discussions)
- 🐛 [Report Issues](https://github.com/gitauditor/gitauditor-action/issues)
- 📧 [Contact Support](mailto:support@gitauditor.io)

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## License

This action is released under the [MIT License](LICENSE).

---

Made with ❤️ by the [GitAuditor.io](https://gitauditor.io) team
