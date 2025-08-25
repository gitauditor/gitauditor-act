<!-- CROSS_SYSTEM_COORDINATION_START -->
## Cross-System Coordination

This component participates in cross-system coordination through the central `.claude` repository.

### Before Starting Work
1. **Check Active Issues**: Review `../.claude/ACTIVE_ISSUES.md` for any issues affecting this component
2. **Check Local Issues**: Review `.claude/CROSS_SYSTEM_ISSUES.md` for component-specific tracking
3. **Review API Changes**: Check `../.claude/API_CHANGES.md` for recent API modifications
4. **Monitor Labels**: Look for issues labeled `affects:action` in the .claude repository

### When You Find a Cross-System Issue
If you discover an issue caused by another component:
1. **Create Issue**: Use template from `../.claude/issue-templates/cross-system-dependency.md`
2. **Apply Labels**: `cross-system`, `comp:action`, `affects:[target]`, priority label
3. **Document Details**: Include error messages, logs, reproduction steps
4. **Update Tracking**: Add to `.claude/CROSS_SYSTEM_ISSUES.md`

### When Another Component Reports an Issue
If this component is causing issues for other components:
1. **Acknowledge Quickly**: Comment on the issue within SLA (P0: 1hr, P1: 2hr, P2: 8hr, P3: 24hr)
2. **Create Local Issue**: Link to the cross-system issue
3. **Update Status**: Change label from `status:detected` to `status:fixing`
4. **Fix and Validate**: Test with affected components before closing

### Common Cross-System Issues for This Component
- **API Authentication**: Token format changes
- **API Endpoints**: Backend API modifications
- **Docker Image**: Base image compatibility
- **Output Format**: SARIF export changes

### Testing Cross-System Changes
Before marking any cross-system issue as resolved:
1. Run component test suite
2. Test integration points with dependencies
3. Test specific scenarios from issue
4. Request validation from affected components
5. Update integration tests with new scenarios

### Quick Reference
- **Central Hub**: `../.claude/` - Coordination repository
- **Active Issues**: `../.claude/ACTIVE_ISSUES.md` - Current cross-system issues
- **Component Registry**: `../.claude/COMPONENT_REGISTRY.md` - Component interfaces
- **API Changes**: `../.claude/API_CHANGES.md` - API modification tracking

### SLA Commitments
| Priority | Response Time | Resolution Target |
|----------|--------------|-------------------|
| P0-Critical | < 1 hour | < 4 hours |
| P1-High | < 2 hours | < 24 hours |
| P2-Medium | < 8 hours | < 3 days |
| P3-Low | < 24 hours | < 1 week |
<!-- CROSS_SYSTEM_COORDINATION_END -->
