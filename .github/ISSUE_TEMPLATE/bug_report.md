---
name: Bug Report
about: Report a bug or issue with go-framework
title: '[BUG] '
labels: bug
assignees: ''
---

## Bug Description

A clear and concise description of the bug.

## Steps to Reproduce

1. Go to '...'
2. Run command '...'
3. See error

## Expected Behavior

What you expected to happen.

## Actual Behavior

What actually happened.

## Environment

**Operating System:**
- [ ] macOS (version: )
- [ ] Linux (distribution: )
- [ ] Windows with WSL2 (version: )

**Tool Versions:**
```bash
# Run 'make version' and paste output here
docker --version
go version
kubectl version --client --short
helm version --short
```

**go-framework Version:**
```bash
# Run this command and paste output:
git log -1 --oneline
```

## Logs

<details>
<summary>Error Logs</summary>

```
# Paste relevant logs here
# Get logs with: make logs-service SERVICE=<name>
```

</details>

## Service Status

```bash
# Run 'make status' and paste output:
```

## Additional Context

Any other relevant information:
- Screenshots
- Configuration files (sanitize secrets!)
- Related issues
- Attempted solutions

## Checklist

- [ ] I have searched existing issues
- [ ] I have tried the troubleshooting guide
- [ ] I have included all requested information
- [ ] I have sanitized any sensitive data
