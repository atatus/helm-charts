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

## Cluster metrics topology

Most kubernetes metricsets are node-scoped: the kubelet, kube-proxy, the
controller manager and the scheduler each report only the node the agent runs
on, so every agent collects its own. Three are cluster-scoped:
kube-state-metrics, the API server and the event stream each return the state of
the *whole* cluster to whoever asks. Exactly one agent may collect those, or
every row is stored once per node.

`clusterMetrics.mode` picks which agent that is.

**`leader` (default, needs agent >= 4.3.1)**

One agent per node, all from the DaemonSet. They contend for a Kubernetes Lease
in the release namespace, and the winner collects the cluster-scoped metricsets
in addition to its own node's. If that node goes away, another agent takes the
lease within about 15 seconds and carries on.

This is the only mode that never puts two agent processes on one node. It is
also the only one that behaves sensibly on a single-node cluster, where one pod
covers both scopes.

The Lease defaults to `atatus-infra-agent-cluster-leader`. Set
`clusterMetrics.leaseName` per release if two independent installs share a
namespace, otherwise they elect one leader between them and one install collects
no cluster metrics.

**`deployment` (for agents 4.2.0 to 4.3.0)**

A separate single-replica Deployment collects the cluster-scoped metricsets, and
the DaemonSet collects node metrics only.

The cost is that the Deployment always lands on a node that already runs a
DaemonSet agent, so that node carries two agent processes. Both report under the
same host, because the agent derives its host id from the kernel boot id and
that is not namespaced. They then disagree about the hostname, and about the
system metrics that every agent collects unconditionally, since only the
DaemonSet mounts the host filesystem. Prefer `leader` wherever the agent version
allows it.

**`every-node` (legacy)**

Every DaemonSet agent collects the cluster-scoped metricsets. Each row is stored
once per node and kube-state-metrics is scraped N times. Kept only for agents
older than 4.2.0.

### Choosing a mode

The mode is resolved at render time, and the chart refuses to install rather
than produce a topology that silently duplicates or drops data. It fails if the
agent image is pinned below 4.3.1 in `leader` mode, if `deployment.enabled`
contradicts an explicit mode, or if `leader` mode is asked for with no DaemonSet.

Leaving `clusterMetrics.mode` unset selects `deployment` when a values file still
carries `deployment.enabled: true`, so an existing install keeps its topology
across a chart upgrade. It selects `leader` otherwise.

### Migrating an existing install

```console
helm upgrade atatus-agent atatus/atatus-agent -n atatus \
  --set clusterMetrics.mode=leader \
  --set deployment.enabled=false
```

The Deployment is removed and its work moves onto the elected DaemonSet agent.
Expect a gap of up to one collection interval while the lease is first acquired.

## License

The project is released under version 2.0 of the [Apache license](http://www.apache.org/licenses/LICENSE-2.0).





