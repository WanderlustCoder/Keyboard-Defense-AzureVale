# TORQUE Integration Guide - Keyboard-Defense

TORQUE (Task Orchestration & Resource Queue Engine) enables parallel task execution for your Node.js/TypeScript application development.

## Project Overview

Keyboard-Defense is a Node.js application with multiple apps, comprehensive documentation, and GitHub Actions CI/CD integration.

## MCP Configuration

Add to your `.mcp.json`:

```json
{
  "mcpServers": {
    "torque": {
      "command": "node",
      "args": ["/mnt/c/Users/Werem/Projects/Torque/dist/index.js"],
      "env": {}
    }
  }
}
```

## Recommended Task Templates

### Build All Apps
```
Submit task: "Run npm run build in apps/ directory for all applications"
```

### Run Tests
```
Submit task: "Execute npm test across all packages and report failures"
```

### Lint and Format
```
Submit task: "Run eslint and prettier across the codebase"
```

## Example Workflows

### CI Pipeline
```
Create pipeline:
1. npm ci (clean install)
2. npm run lint
3. npm run typecheck
4. npm run test
5. npm run build
```

### Parallel App Development
```
Queue tasks in parallel:
- "Build and test apps/app1"
- "Build and test apps/app2"
- "Build and test apps/app3"
```

### Screenshot Updates
```
Submit task: "Run app in test mode and capture updated screenshots to Screenshots/"
```

### Documentation
```
Submit task: "Generate API documentation from source and update docs/"
```

## Tips

- Use `timeout_minutes: 10` for full builds with tests
- Tag tasks by app: `tags: ["app1", "build"]` or `tags: ["test", "integration"]`
- Use pipelines for install -> lint -> test -> build sequences
- Check AGENTS.md for AI-specific guidelines
- Monitor scripts/ for utility automation opportunities
