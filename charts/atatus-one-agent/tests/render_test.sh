#!/usr/bin/env bash
# Copyright (c) 2026 Atatus
# Render checks of the atatus-one-agent chart (helm template, no cluster).
#   charts/atatus-one-agent/tests/render_test.sh
set -euo pipefail
CHART=$(cd "$(dirname "$0")/.." && pwd)
failures=0

render() { helm template t "$CHART" -n obs "$@" 2>&1; }
ok() {
    local name=$1 pattern=$2
    shift 2
    if render "$@" | grep -qE -- "$pattern"; then echo "ok   $name"; else
        echo "FAIL $name: no /$pattern/"
        failures=$((failures + 1))
    fi
}
refused() {
    local name=$1 message=$2
    shift 2
    local out
    out=$(render "$@" || true)
    if grep -qF -- "$message" <<<"$out"; then echo "ok   $name"; else
        echo "FAIL $name: not refused with '$message'"
        failures=$((failures + 1))
    fi
}

base=(--set atatus.license_key=k1 --set atatus.cluster_name=prod-eu --set 'controller.hosts[0]=agent.us1.atatus.com')

ok "saas example renders" "kind: DaemonSet" -f "$CHART/values-saas.example.yaml" --set atatus.cluster_name=prod
ok "onprem example mounts the CA" "mountPath: /etc/atatus-one-agent/tls" -f "$CHART/values-onprem.example.yaml"
ok "static config: system trust store" "controller-cert-file-prefix: system" "${base[@]}"
ok "static config: cluster name" "kubernetes-cluster-name: prod-eu" "${base[@]}"
ok "static config: controller host" "- agent.us1.atatus.com" "${base[@]}"
ok "license key from the Secret" "name: t-atatus-one-agent-license" "${base[@]}"
ok "existing Secret" "name: my-key" --set atatus.existingSecret=my-key --set atatus.cluster_name=c --set 'controller.hosts[0]=h'
ok "fixed DaemonSet name" "^  name: atatus-one-agent$" "${base[@]}"
ok "host PID" "hostPID: true" "${base[@]}"
ok "capabilities mode" "- SYS_ADMIN" "${base[@]}"
ok "privileged mode" "privileged: true" "${base[@]}" --set securityMode=privileged
ok "extra static config" "l7-protocol-enabled" "${base[@]}" --set 'extraStaticConfig.l7-protocol-enabled[0]=HTTP'
ok "disabled TLS uses the plain port" "controller-port: 30035" "${base[@]}" --set tls.mode=disabled

refused "license key required" "atatus.license_key (or atatus.existingSecret) is required" --set atatus.cluster_name=c --set 'controller.hosts[0]=h'
refused "cluster name required" "atatus.cluster_name is required" --set atatus.license_key=k --set 'controller.hosts[0]=h'
refused "default cluster name" "collides across clusters" --set atatus.license_key=k --set atatus.cluster_name=default --set 'controller.hosts[0]=h'
refused "controller required" "controller.hosts is required" --set atatus.license_key=k --set atatus.cluster_name=c
refused "two host names" "exactly one host name" "${base[@]}" --set 'controller.hosts[1]=b.example.com'
refused "mixed address families" "do not mix IPv4 and IPv6" --set atatus.license_key=k --set atatus.cluster_name=c --set 'controller.hosts[0]=10.0.0.1' --set 'controller.hosts[1]=fd00::1'
refused "ca mode without a CA" "tls.mode ca needs" "${base[@]}" --set tls.mode=ca
refused "chart-owned static key" "extraStaticConfig must not set team-id" "${base[@]}" --set 'extraStaticConfig.team-id=x'
refused "limits required" "resources.limits.cpu and resources.limits.memory are required" "${base[@]}" --set resources.limits=null

# the license key never reaches the ConfigMap
if render "${base[@]}" | awk '/kind: ConfigMap/,/^---/' | grep -q k1; then
    echo "FAIL license key in the ConfigMap"
    failures=$((failures + 1))
else echo "ok   license key not in the ConfigMap"; fi

# The image accepts this chart's own map and the flat shape the atatus-agent chart in this
# repository uses, so an operator running both does not need a second value name for the same thing.
ok "image map shape" 'image: atatus/atatus-one-agent:' "${base[@]}"
ok "image string shape" 'image: localhost:5000/one-agent:c-1' "${base[@]}" \
    --set image=localhost:5000/one-agent --set imageTag=c-1
ok "pull policy from the flat shape" 'imagePullPolicy: Always' "${base[@]}" \
    --set image=localhost:5000/one-agent --set imagePullPolicy=Always
ok "pull policy from the map shape" 'imagePullPolicy: Never' "${base[@]}" --set image.pullPolicy=Never
# neither shape is a guess: "<nil>:<nil>" would be a pod that never starts, with nothing saying why
refused "image of the wrong type" 'image must be a string or a map' "${base[@]}" --set image=true
refused "empty image string" 'image is empty' "${base[@]}" --set image=""

[ "$failures" = 0 ] || { echo "$failures failures"; exit 1; }
echo "all render checks passed"
