# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is the official Helm charts repository for Atatus. It holds two charts:

- **`atatus-agent`** — the Infrastructure Agent: metrics, container and node logs, Kubernetes state.
- **`atatus-one-agent`** — the One Agent: eBPF traces, request logs, network flows, profiles and process
  events, collected from the kernel with no code change in the applications.

They are installed alongside each other. Both take the same `atatus.license_key` and the same
`atatus.cluster_name`; a mismatched cluster name makes one cluster appear twice in the account.

## Development Commands

All commands should be run from the repository root directory.

Each chart has its own local values file at the repository root, both gitignored:
`atatus_values.yaml` for `atatus-agent`, `atatus_one_agent_values.yaml` for `atatus-one-agent`.

### Template Generation (Debug)
```bash
helm template test-release charts/atatus-agent --debug -f ./atatus_values.yaml
helm template test-release-one charts/atatus-one-agent --debug -f ./atatus_one_agent_values.yaml
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

## atatus-one-agent

### Chart Structure
```
charts/atatus-one-agent/
├── Chart.yaml                    # Chart metadata (version 0.1.0)
├── values.yaml                   # Default configuration values
├── values-saas.example.yaml      # A SaaS install, annotated
└── templates/
    ├── _helpers.tpl
    ├── daemonset.yaml            # the agent, one pod per node
    ├── configmap.yaml            # static config (atatus-one-agent.yaml)
    ├── secret.yaml               # the license key
    ├── service.yaml              # optional integration listener (OTel, SkyWalking, Prometheus, logs)
    ├── rbac.yaml                 # ServiceAccount, ClusterRole, ClusterRoleBinding
    ├── validate.yaml             # fails the render on a misconfiguration, before anything is applied
    └── NOTES.txt
```

The agent needs eBPF capabilities and host mounts, so it runs as root with an explicit capability set
(`securityMode: capabilities`, the default) or privileged (`securityMode: privileged`). Runtime-default
seccomp and AppArmor profiles deny the writes under `/sys/kernel/debug` that eBPF needs, so both are
`Unconfined`.

`tolerations` is `[]` by default, which skips tainted and control-plane nodes. `[{operator: Exists}]` covers
every node — and every node counts as a host, so set it deliberately.

### Required Configuration
| Value | Why |
|---|---|
| `atatus.license_key` | The account key. Or `atatus.existingSecret` to read it from a Secret you manage. |
| `atatus.cluster_name` | Unique in the account, and the same as the `atatus-agent` chart's. It cannot be renamed after first registration; `default` is refused unless `atatus.allowDefaultClusterName` is set. |
| `controller.hosts` | The Atatus agent endpoint of your region, or your on-prem server. |

`templates/validate.yaml` fails the render with a message naming the value when one of these is missing,
so a misconfiguration never reaches the cluster.

### Upstream
The chart is developed in the `atatus-one-agent` repository (`deploy/charts/atatus-one-agent`) and published
here. Change it there first, then port, so the two do not drift.

### Required Configuration (atatus-agent)
The `atatus.license_key` value is required for deployment. Use `atatus_values.yaml` as a reference for test configurations.
