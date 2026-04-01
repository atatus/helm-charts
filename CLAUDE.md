# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is the official Helm charts repository for Atatus, providing Kubernetes-native deployment of the Atatus Infrastructure Agent for observability, monitoring, and logging.

## Development Commands

All commands should be run from the repository root directory.

### Template Generation (Debug)
```bash
helm template test-release charts/atatus-agent --debug -f ./atatus_values.yaml
```

### Dry Run Installation
```bash
helm install test-release charts/atatus-agent --debug --dry-run -f ./atatus_values.yaml
```

### Install Chart
```bash
helm install test-release charts/atatus-agent --debug -f ./atatus_values.yaml
```

### Upgrade Release
```bash
helm upgrade test-release charts/atatus-agent -f ./atatus_values.yaml
```

### Force Pod Restart on Upgrade
```bash
helm upgrade --recreate-pods test-release charts/atatus-agent -f ./atatus_values.yaml
```

### Uninstall
```bash
helm uninstall test-release
```

## Architecture

### Chart Structure
```
charts/atatus-agent/
├── Chart.yaml           # Chart metadata (version 1.1.0, appVersion 4.0.0)
├── values.yaml          # Default configuration values
└── templates/
    ├── _helpers.tpl     # Template helper functions
    ├── daemonset.yaml   # Primary deployment (node-level metrics/logs)
    ├── deployment.yaml  # Optional singleton deployment (cluster-level)
    ├── configmap.yaml   # Agent configuration (atatus.yml, kubernetes.yml)
    ├── serviceaccount.yaml
    ├── clusterrole.yaml
    ├── clusterrolebinding.yaml
    ├── role.yaml
    ├── rolebinding.yaml
    └── secret.yaml
```

### Deployment Modes
- **DaemonSet** (default, enabled): Runs on every node, collects node-level metrics and logs via host path mounts
- **Deployment** (optional, disabled by default): Singleton instance for cluster-level metrics like kube-state-metrics

### Dependencies
- **kube-state-metrics** (prometheus-community, v4.7.0): Conditional on `atatus.state_metrics.enabled`

### Key Template Helpers (`_helpers.tpl`)
- `atatus-agent.fullname`: Resource naming with 63-char limit
- `atatus-agent.labels`: Standard Kubernetes labels
- `atatus-agent.serviceAccount`: ServiceAccount name resolution
- `state-metrics.fullname`: kube-state-metrics endpoint resolution

### Required Configuration
The `atatus.license_key` value is required for deployment. Use `atatus_values.yaml` as a reference for test configurations.
