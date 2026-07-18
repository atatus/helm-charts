# Atatus Agent Helm Charts

## Installing

### Add the Atatus Helm charts repo:

```console
helm repo add atatus https://atatus.github.io/helm-charts
helm repo update
```

_See [helm repo](https://helm.sh/docs/helm/helm_repo/) for command documentation._

### Installing the Chart

To install the chart with the release name `atatus-release`:

```console
helm install atatus-release atatus/atatus-agent -f ./values.yaml
```

Here `values.yml` will have your license key and other settings.


### Uninstalling the Chart:

To uninstall/delete the atatus-release deployment:

```console
helm uninstall atatus-release
```

## Configuration

| Parameter                             | Description                       | Default                                 |
|---------------------------------------|-----------------------------------|-----------------------------------------|
| `atatus.license_key`                  | The Atatus Infra License Key.     |                                         |
| `atatus.cluster_name`                 | Your cluster name                 |`default`                              |
| `atatus.logs_enabled`                 | Enable Log Monitoring             |`true`                                 |
| `atatus.notify_url`                   | Atatus Endpoint for Infra Metrics | `""`                                  |
| `atatus.log_notify_url`               | Atatus Endpoint for Logs Collection | `""`                                |


### Example values.yaml

```yaml
atatus:
  license_key: "lic_infra_*****"
  cluster_name: "ecom-cluster"
  logs_enabled: true
```

## Memory tuning

By default the chart sets:

- `resources.limits.memory`: `2Gi`
- `resources.limits.cpu`: `1000m`
- `GOMAXPROCS` — derived from `resources.limits.cpu` (via the downward API)
- `GOMEMLIMIT` — derived as 80% of `resources.limits.memory` (e.g. `1638MiB` for a 2Gi limit)

`GOMEMLIMIT` caps the Go runtime's memory target and triggers aggressive arena
release on cgroup v2 systems (AKS, modern EKS, GKE Autopilot). Without it, Go
can grow RSS toward the cgroup limit even when the live heap is small — the
root cause of the high per-pod RSS seen on those platforms.

To override the derived value:

```yaml
goRuntime:
  goMemLimit: "1024MiB"   # leave "" to derive from resources.limits.memory
  enableGoMaxProcs: true  # set false to skip the GOMAXPROCS downward-API env var
```

You can also inject arbitrary env vars without forking the chart:

```yaml
extraEnv:
  - name: GODEBUG
    value: "madvdontneed=1"
```

> If you run the agent **without** a memory limit on purpose, `GOMEMLIMIT`
> cannot be derived and is omitted — set `goRuntime.goMemLimit` explicitly, or
> keep a `resources.limits.memory` value.

## Architecture modes

Two modes are supported:

**1. Standalone DaemonSet (default, `splitClusterMetrics: false`)**

Every DaemonSet pod scrapes node-scoped **and** cluster-scoped metrics. Simple,
but on clusters larger than ~20 nodes, kube-state-metrics is scraped redundantly
from every node and the apiserver receives N watch connections per cluster
resource. Use only on small clusters.

**2. Split mode (recommended for >20 nodes)**

Set `splitClusterMetrics: true` **and** `deployment.enabled: true`.

- **DaemonSet** — node-scoped only (kubelet metrics, kube-proxy, container/system
  metrics, log harvesters).
- **Deployment** (`replicas: 1`) — cluster-scoped only (`state_*`, `event`,
  `apiserver`/`controllermanager`/`scheduler`).

This drops the kube-state-metrics scrape load to 1× regardless of cluster size
and removes the (N-1) redundant cluster-resource watchers.

> Split mode requires an agent release that honors the `ATATUS_AGENT_MODE` env
> var (appVersion `>= 4.2.0`). On older agents, keep `splitClusterMetrics: false`.

Migration — existing deployments continue working unchanged on upgrade (defaults
preserved). To switch:

```console
helm upgrade atatus-agent atatus/atatus-agent -n atatus \
  --set deployment.enabled=true \
  --set splitClusterMetrics=true
```

## License

The project is released under version 2.0 of the [Apache license](http://www.apache.org/licenses/LICENSE-2.0).





