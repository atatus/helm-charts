# atatus-one-agent chart

Runs the Atatus One Agent on every node as the DaemonSet `atatus-one-agent`.

The One Agent collects eBPF telemetry from the kernel - traces and request logs, network flows, continuous
profiles and process events - with no code change in the applications it observes. It is built on
[DeepFlow](https://github.com/deepflowio/deepflow) (Apache-2.0), with Atatus licensing, TLS and packaging.

It runs alongside the `atatus-agent` chart rather than replacing it: that one collects infrastructure metrics,
logs and Kubernetes state.

```sh
kubectl create namespace atatus-one-agent
kubectl label namespace atatus-one-agent pod-security.kubernetes.io/enforce=privileged
helm upgrade --install atatus-one-agent atatus/atatus-one-agent -n atatus-one-agent \
  --set atatus.license_key=<license key> \
  --set atatus.cluster_name=<cluster name, unique in the account> \
  --set 'controller.hosts[0]=<agent endpoint>'
```

`atatus.license_key` and `atatus.cluster_name` are the same keys the `atatus-agent` chart uses, and both
charts must be given the **same values**: a mismatched cluster name makes one cluster appear twice in the
account.

Keep a values file per chart - `atatus_values.yaml` and `atatus_one_agent_values.yaml` in this repository.
One shared file does render, because this chart accepts the flat `image` / `imageTag` / `imagePullPolicy`
shape as well as its own `image.repository` map, but the two charts run **different images**: a file that
sets `image` for one would point the other at the wrong one. If you do share a file, keep the license key and
the cluster name in it and set the image per chart on the command line.

From a checkout of this repository, replace `atatus/atatus-one-agent` above with
`charts/atatus-one-agent`.

| Value | Default | Use |
|---|---|---|
| `atatus.license_key` / `atatus.existingSecret`, `existingSecretKey` | | license key, passed as `ATATUS_LICENSE_KEY` from a Secret (never in the ConfigMap) |
| `atatus.cluster_name` | required | the Kubernetes cluster name in Atatus; unique in the account, `default` refused unless `allowDefaultClusterName` |
| `atatus.agentGroupId` | | agent group to join |
| `controller.hosts` | required | one host name, or IP addresses of one family |
| `controller.tlsPort` | 443 | SaaS load balancer port; on-prem NodePort 30035 |
| `tls.mode` | `system` | `system` trust store, `ca` (`tls.caSecret` or `tls.caConfigMap`, key `ca.pem`), `disabled` (tests) |
| `securityMode` | `capabilities` | root with the eBPF capability set, or `privileged` |
| `seccompProfile`, `appArmorProfile` | `Unconfined` | runtime default profiles deny writes under `/sys/kernel/debug` |
| `resources.limits` | 1000m / 768Mi | keep equal to the agent group's `max_millicpus` / `max_memory` |
| `tolerations` | `[]` | `[{operator: Exists}]` to cover tainted and control-plane nodes |
| `integrationService.enabled` | false | node-local Service for the integration port 38086 (also the SkyWalking `collector.backend_service`) |
| `sysctlInitContainer.enabled` | false | enable the BPF JIT on the node (privileged init container) |
| `debugSymbols.hostPath` | `""` | node directory of detached debug files (`.build-id` layout), mounted read-only at `/usr/lib/debug` in the agent so profile frames inside stripped libraries are named; empty disables the mount |
| `extraStaticConfig` | `{}` | other static config keys; chart-owned keys are refused |

One atatus-one-agent runs per host: a second release, or a node that also runs the deb/rpm package, makes the
extra agent exit after 30 seconds.

## Protocols

The agent reads the requests and responses of every protocol it supports, with no setting: HTTP and HTTP/2,
gRPC, Dubbo (Triple included), SOFARPC, FastCGI, bRPC, Tars, MySQL, PostgreSQL, Redis, MongoDB, Memcached, Kafka,
MQTT, AMQP, OpenWire, NATS, Pulsar, ZMTP, RocketMQ, DNS and ICMP ping.

The list is agent group configuration, not a chart value, so neither `--set` nor `extraStaticConfig` changes it.
To narrow it, which lowers the agent's CPU use, edit
`processors.request_log.application_protocol_inference.enabled_protocols` in Atatus under Fleet → Groups → the
group → Configuration. Agents take a new list when they restart (`kubectl rollout restart ds/atatus-one-agent`).

## Transactions of URLs with ids in them

An endpoint with an id in its path - `/payments/sim_3085`, `/payments/sim_8781` - would be one transaction per
id, and a busy service makes millions of them. The agent does not name a transaction after the raw URL: it
extracts an *endpoint* first, by longest-prefix match on the path and then keeping the first N segments, and
names the transaction and its spans after that. The default is one rule, `url_prefix: ""` with
`keep_segments: 2`, and `/payments/sim_3085` is two segments - which is why each id is its own transaction
until you say otherwise.

Like the protocol list this is agent group configuration, not a chart value: set it in Atatus under
Fleet → Groups → the group → Configuration.

```yaml
processors:
  request_log:
    tag_extraction:
      http_endpoint:
        match_rules:
        - url_prefix: ""
          keep_segments: 2        # unchanged default for every other path
        - url_prefix: /payments
          keep_segments: 1        # /payments/sim_3085 -> /payments
        - url_prefix: /payments/order
          keep_segments: 2        # longest prefix wins, so this one stays separate
```

The rules are prefixes and segment counts, not patterns: there is no `{id}` placeholder, so a path like
`/payments/{id}/refunds` needs its own longer-prefix rule to keep the `refunds` part. Transactions already
recorded keep the names they were recorded with, and agents take new rules when they restart
(`kubectl rollout restart ds/atatus-one-agent`).

`tests/render_test.sh` checks the rendering and the validation (helm only, no cluster).
