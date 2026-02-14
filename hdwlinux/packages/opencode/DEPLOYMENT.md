# OpenCode Planning & Execution Plugin Suite - Deployment Guide

This document describes how to build, test, and deploy the plugin suite.

## Prerequisites

- Bun 1.0+ (for building and running)
- Node.js 18+ (for compatibility)
- OpenCode CLI installed
- Beads plugin installed and configured

## Building

### Build All Plugins

```bash
cd hdwlinux/packages/opencode
bun run build
```

This will:
1. Build the core module
2. Build all three plugins
3. Generate TypeScript declarations
4. Output to `dist/` directories

### Build Individual Plugin

```bash
cd hdwlinux/packages/opencode/program-planner
bun run build
```

### Watch Mode (Development)

```bash
cd hdwlinux/packages/opencode
bun run dev
```

This will watch for changes and rebuild automatically.

## Testing

### Run All Tests

```bash
cd hdwlinux/packages/opencode
bun run test
```

### Run Tests for Specific Plugin

```bash
cd hdwlinux/packages/opencode/core
bun run test
```

### Run Tests with Coverage

```bash
cd hdwlinux/packages/opencode
bun run test -- --coverage
```

## Installation

### Option 1: Local Development

1. Build the plugins:
   ```bash
   cd hdwlinux/packages/opencode
   bun run build
   ```

2. Link plugins to OpenCode:
   ```bash
   opencode plugin link ./program-planner/dist
   opencode plugin link ./project-planner/dist
   opencode plugin link ./work-executor/dist
   ```

3. Verify installation:
   ```bash
   opencode plugin list
   ```

### Option 2: Package for Distribution

1. Create a tarball:
   ```bash
   cd hdwlinux/packages/opencode
   tar -czf opencode-plugins-suite.tar.gz \
     program-planner/dist \
     project-planner/dist \
     work-executor/dist \
     core/dist
   ```

2. Distribute and install:
   ```bash
   tar -xzf opencode-plugins-suite.tar.gz
   opencode plugin link ./program-planner/dist
   opencode plugin link ./project-planner/dist
   opencode plugin link ./work-executor/dist
   ```

### Option 3: NPM Registry

1. Publish to NPM:
   ```bash
   cd hdwlinux/packages/opencode/core
   npm publish
   
   cd ../program-planner
   npm publish
   
   cd ../project-planner
   npm publish
   
   cd ../work-executor
   npm publish
   ```

2. Install from NPM:
   ```bash
   opencode plugin install opencode-planner-core
   opencode plugin install opencode-program-planner
   opencode plugin install opencode-project-planner
   opencode plugin install opencode-work-executor
   ```

## Configuration

### Initial Setup

1. Create configuration directory:
   ```bash
   mkdir -p ~/.config/opencode/plugins
   ```

2. Create default configurations:
   ```bash
   cat > ~/.config/opencode/plugins/program-planner.json << 'EOF'
   {
     "defaultHorizon": "quarter",
     "autoCreateProjectEpics": true,
     "defaultLabels": ["program"],
     "charterDocLocation": "external"
   }
   EOF
   
   cat > ~/.config/opencode/plugins/project-planner.json << 'EOF'
   {
     "sprintStyle": "labels",
     "defaultSprintLength": 2,
     "defaultSprintLengthUnit": "weeks",
     "autoAssignTasks": false,
     "charterDocLocation": "external"
   }
   EOF
   
   cat > ~/.config/opencode/plugins/work-executor.json << 'EOF'
   {
     "riskPosture": "medium",
     "alwaysRunSecurityReview": true,
     "autonomousEditLimits": {
       "maxFilesPerCommit": 10,
       "requiresApprovalForPublicAPIs": true,
       "requiresApprovalForDependencyChanges": true
     },
     "techStackPreferences": {
       "defaultLanguage": "go",
       "preferredFrameworks": ["nix", "terraform"]
     }
   }
   EOF
   ```

3. Verify configuration:
   ```bash
   opencode config show
   ```

## Verification

### Test Plugin Loading

```bash
opencode plugin list
```

Should show:
```
Installed Plugins:
  - opencode-program-planner (v0.1.0)
  - opencode-project-planner (v0.1.0)
  - opencode-work-executor (v0.1.0)
```

### Test Commands

```bash
# Test program planner
/program-list

# Test project planner
/project-list

# Test work executor
/work-status
```

### Test Beads Integration

```bash
# Create a test program
/program-new

# Verify it was created in beads
bd list --label program
```

## Troubleshooting

### Plugin Not Loading

1. Check plugin installation:
   ```bash
   opencode plugin list
   ```

2. Check logs:
   ```bash
   opencode logs
   ```

3. Rebuild and reinstall:
   ```bash
   cd hdwlinux/packages/opencode
   bun run build
   opencode plugin unlink opencode-program-planner
   opencode plugin link ./program-planner/dist
   ```

### Beads Integration Issues

1. Verify beads is installed:
   ```bash
   bd --version
   ```

2. Check beads configuration:
   ```bash
   bd config show
   ```

3. Test beads directly:
   ```bash
   bd new --type epic --title "Test" --label test
   bd list --label test
   ```

### Command Not Found

1. Verify plugin is loaded:
   ```bash
   opencode plugin list
   ```

2. Check command registration:
   ```bash
   opencode help | grep program-
   ```

3. Restart OpenCode:
   ```bash
   opencode restart
   ```

## Performance Optimization

### Caching

The plugins use in-memory caching for beads queries. To clear cache:

```bash
# Restart OpenCode to clear all caches
opencode restart
```

### Batch Operations

For large operations, use batch commands:

```bash
# Plan multiple projects at once
/program-plan PROG-123 service-a service-b service-c
```

### Pagination

For large result sets, use pagination:

```bash
# List programs with pagination
/program-list --page 1 --limit 10
```

## Monitoring

### Enable Debug Logging

```bash
export OPENCODE_DEBUG=1
opencode
```

### Monitor Plugin Performance

```bash
opencode metrics show
```

### Check Plugin Health

```bash
opencode plugin health
```

## Updates

### Check for Updates

```bash
opencode plugin check-updates
```

### Update Plugins

```bash
opencode plugin update opencode-program-planner
opencode plugin update opencode-project-planner
opencode plugin update opencode-work-executor
```

### Rollback to Previous Version

```bash
opencode plugin rollback opencode-program-planner v0.0.1
```

## Uninstallation

### Remove Individual Plugin

```bash
opencode plugin unlink opencode-program-planner
```

### Remove All Plugins

```bash
opencode plugin unlink opencode-program-planner
opencode plugin unlink opencode-project-planner
opencode plugin unlink opencode-work-executor
```

### Clean Configuration

```bash
rm ~/.config/opencode/plugins/program-planner.json
rm ~/.config/opencode/plugins/project-planner.json
rm ~/.config/opencode/plugins/work-executor.json
```

## Development Workflow

### Local Testing

1. Build plugins:
   ```bash
   bun run build
   ```

2. Link for development:
   ```bash
   opencode plugin link ./program-planner/dist --dev
   ```

3. Make changes and rebuild:
   ```bash
   bun run dev
   ```

4. Test in OpenCode:
   ```bash
   /program-list
   ```

### Creating a Release

1. Update version in `package.json`:
   ```bash
   cd hdwlinux/packages/opencode
   npm version minor
   ```

2. Build and test:
   ```bash
   bun run build
   bun run test
   ```

3. Create git tag:
   ```bash
   git tag v0.2.0
   git push origin v0.2.0
   ```

4. Publish to NPM:
   ```bash
   npm publish
   ```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Build and Test

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: oven-sh/setup-bun@v1
      - run: cd hdwlinux/packages/opencode && bun install
      - run: cd hdwlinux/packages/opencode && bun run build
      - run: cd hdwlinux/packages/opencode && bun run test
      - run: cd hdwlinux/packages/opencode && bun run lint
```

## Support

For issues or questions:

1. Check the SPEC.md for detailed documentation
2. Review EXAMPLES.md for usage patterns
3. Check IMPLEMENTATION.md for architecture details
4. Open an issue on GitHub
5. Contact the development team
