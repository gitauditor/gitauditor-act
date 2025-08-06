# Conventional Commits Guide

This repository uses [Conventional Commits](https://www.conventionalcommits.org/) to enable automatic semantic versioning and changelog generation.

## Commit Message Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

| Type | Description | Version Bump |
|------|-------------|--------------|
| `feat` | A new feature | Minor (0.x.0) |
| `fix` | A bug fix | Patch (0.0.x) |
| `docs` | Documentation only changes | Patch (0.0.x) |
| `style` | Changes that do not affect the meaning of the code | Patch (0.0.x) |
| `refactor` | A code change that neither fixes a bug nor adds a feature | Patch (0.0.x) |
| `perf` | A code change that improves performance | Patch (0.0.x) |
| `test` | Adding missing tests or correcting existing tests | Patch (0.0.x) |
| `build` | Changes that affect the build system or external dependencies | Patch (0.0.x) |
| `ci` | Changes to CI configuration files and scripts | Patch (0.0.x) |
| `chore` | Other changes that don't modify src or test files | Patch (0.0.x) |
| `revert` | Reverts a previous commit | Patch (0.0.x) |

### Breaking Changes

To indicate a breaking change, add `BREAKING CHANGE:` to the commit body or add `!` after the type:

```bash
feat!: change action input parameter names

BREAKING CHANGE: Renamed 'token' to 'gitauditor_token' and 'url' to 'api_url' for clarity.
```

This will trigger a **Major version bump** (x.0.0).

## Examples

### Feature Addition
```bash
feat(action): add SARIF output format support

Implements SARIF generation for GitHub Security tab integration.
Users can now upload scan results directly to Security tab.
```

### Bug Fix
```bash
fix(scan): resolve timeout handling for large repositories

Increases default timeout to 30 minutes and adds proper
error handling for timeout scenarios.

Fixes #42
```

### Breaking Change
```bash
feat(inputs)!: restructure action inputs for better UX

BREAKING CHANGE: Changed input parameter structure.
- 'token' renamed to 'gitauditor_token'
- 'checks' renamed to 'check_types'
- 'threshold' renamed to 'severity_threshold'

Migration guide in README.md
```

### Documentation
```bash
docs(readme): add troubleshooting section

Adds common issues and solutions for action configuration
and authentication problems.
```

### Chore/Maintenance
```bash
chore(deps): update Python to 3.11 in Docker image

Updates base image from python:3.9-slim to python:3.11-slim
for improved performance and security.
```

## Scopes

Common scopes for this project:

- `action` - GitHub Action configuration changes
- `scan` - Scanning functionality
- `api` - API client and integration
- `docker` - Docker configuration
- `inputs` - Action input parameters
- `outputs` - Action output parameters
- `auth` - Authentication handling
- `sarif` - SARIF format generation
- `workflows` - Example workflows
- `docs` - Documentation
- `tests` - Test files
- `ci` - CI/CD configuration

## Automatic Versioning

Our GitHub Actions workflow automatically:

1. **Analyzes commit messages** when code is pushed to `main`
2. **Determines version bump** based on commit types:
   - `feat:` → Minor version (0.x.0)
   - `fix:`, `docs:`, etc. → Patch version (0.0.x)
   - `BREAKING CHANGE:` or `!` → Major version (x.0.0)
3. **Creates a git tag** with the new version
4. **Generates a release** with automatic changelog
5. **Updates VERSION file** in the repository
6. **Updates Docker image tags** for the action

## Best Practices

### Do ✅
- Use clear, descriptive commit messages
- Include relevant scope when possible
- Reference issue numbers (`Fixes #123`, `Closes #456`)
- Use imperative mood ("add feature" not "added feature")
- Keep the subject line under 50 characters
- Use the body to explain "what" and "why", not "how"

### Don't ❌
- Don't use vague messages like "fix bug" or "update code"
- Don't forget to specify breaking changes
- Don't combine multiple unrelated changes in one commit
- Don't use past tense in commit messages

## Examples for GitAuditor Action

### Adding New Features
```bash
feat(scan): add support for enterprise-level scans

Adds ability to scan entire GitHub Enterprise instances
with configurable scope and filtering options.

- Supports enterprise_id input parameter
- Implements enterprise scan API endpoint
- Adds enterprise-specific output formatting

Closes #234
```

### Security Fixes
```bash
fix(auth): prevent token exposure in action logs

Masks GitAuditor API token in all log outputs
and ensures sensitive data is not printed.

Security-Impact: High
```

### Performance Improvements
```bash
perf(api): implement connection pooling for API requests

Reduces API call overhead by reusing HTTP connections,
improving scan time by ~30% for large organizations.

Benchmark results in docs/performance.md
```

### Docker Updates
```bash
build(docker): optimize image size with multi-stage build

BREAKING CHANGE: Minimum Docker version now 20.10.
Reduces image size from 250MB to 85MB.

- Uses multi-stage build pattern
- Removes unnecessary build dependencies
- Improves container startup time
```

## Release Notes

The automatic release notes will group changes by type:

```markdown
## What's Changed

### 🚀 Features
- feat(scan): add support for enterprise-level scans
- feat(action): add SARIF output format support

### 🐛 Bug Fixes  
- fix(auth): prevent token exposure in action logs
- fix(scan): resolve timeout handling for large repositories

### 📚 Documentation
- docs(readme): add troubleshooting section

### 🔧 Maintenance
- chore(deps): update Python to 3.11 in Docker image
```

## GitHub Marketplace

When a new version is released:
1. The action version tag is automatically created
2. The GitHub Marketplace listing is updated
3. Users can reference the new version with `@v1`, `@v1.2`, or `@v1.2.3`

## Resources

- [Conventional Commits Specification](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)
- [GitHub Actions Versioning](https://docs.github.com/en/actions/creating-actions/about-custom-actions#using-release-management-for-actions)

## Questions?

If you're unsure about how to format a commit message, check:
1. Recent commits in the repository for examples
2. This guide for the appropriate type and format
3. Open an issue for guidance

Remember: Proper commit messages ensure accurate versioning and clear changelogs! 🚀