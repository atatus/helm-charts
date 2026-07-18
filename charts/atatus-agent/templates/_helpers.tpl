{{/*
Expand the name of the chart.
*/}}
{{- define "atatus-agent.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "atatus-agent.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "atatus-agent.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "atatus-agent.labels" -}}
helm.sh/chart: {{ include "atatus-agent.chart" . -}}
{{ include "atatus-agent.selectorLabels" . -}}
{{- if .Chart.AppVersion -}}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote -}}
{{- end -}}
app.kubernetes.io/managed-by: {{ .Release.Service -}}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "atatus-agent.selectorLabels" -}}
app.kubernetes.io/name: {{ include "atatus-agent.name" . -}}
app.kubernetes.io/instance: {{ .Release.Name -}}
{{- end -}}

{{/*
Use the fullname if the serviceAccount value is not set
*/}}
{{- define "atatus-agent.serviceAccount" -}}
{{- if .Values.serviceAccount -}}
{{- .Values.serviceAccount -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}


{{/*
Resolve GOMEMLIMIT for an agent container.
Inputs: dict "explicit" "<string-or-empty>"   "memLimit" "<resourcesLimitsMemory>"
Output: a string suitable for the container env value, e.g. "1638MiB", or empty
when neither an explicit value nor a parseable memory limit is available.
*/}}
{{- define "atatus-agent.goMemLimit" -}}
{{- $explicit := .explicit -}}
{{- $memLimit := .memLimit -}}
{{- if $explicit -}}
{{ $explicit }}
{{- else if $memLimit -}}
{{- $bytes := include "atatus-agent.parseMemoryBytes" $memLimit | int64 -}}
{{- if gt $bytes 0 -}}
{{- $capped := mul (div $bytes 100) 80 -}}
{{- printf "%dMiB" (div $capped 1048576) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Parse a Kubernetes memory string (Ti/Gi/Mi/Ki/T/G/M/K or plain bytes) to bytes.
Falls back to 0 when the input is empty or unparseable, so callers can guard
on that.
*/}}
{{- define "atatus-agent.parseMemoryBytes" -}}
{{- $s := . | default "" | toString -}}
{{- if hasSuffix "Ti" $s -}}
{{- mul (int (trimSuffix "Ti" $s)) 1099511627776 -}}
{{- else if hasSuffix "Gi" $s -}}
{{- mul (int (trimSuffix "Gi" $s)) 1073741824 -}}
{{- else if hasSuffix "Mi" $s -}}
{{- mul (int (trimSuffix "Mi" $s)) 1048576 -}}
{{- else if hasSuffix "Ki" $s -}}
{{- mul (int (trimSuffix "Ki" $s)) 1024 -}}
{{- else if hasSuffix "T" $s -}}
{{- mul (int (trimSuffix "T" $s)) 1000000000000 -}}
{{- else if hasSuffix "G" $s -}}
{{- mul (int (trimSuffix "G" $s)) 1000000000 -}}
{{- else if hasSuffix "M" $s -}}
{{- mul (int (trimSuffix "M" $s)) 1000000 -}}
{{- else if hasSuffix "K" $s -}}
{{- mul (int (trimSuffix "K" $s)) 1000 -}}
{{- else if regexMatch "^[0-9]+$" $s -}}
{{- $s -}}
{{- else -}}
0
{{- end -}}
{{- end -}}


{{/*
Whether the cluster-scoped Deployment should be rendered.

Derived rather than a plain .Values.deployment.enabled lookup: splitClusterMetrics
removes the cluster-scoped metricsets from the DaemonSet, so the Deployment that
collects them instead is required. Pre-2.0.0 the shipped default was
`deployment.enabled: false`, and honouring that literally would break upgrades
for every customer still carrying it.
*/}}
{{- define "atatus-agent.deploymentEnabled" -}}
{{- if or .Values.splitClusterMetrics .Values.deployment.enabled -}}
true
{{- end -}}
{{- end -}}


{{- define "state-metrics.fullname" -}}
{{- if gt (len .Values.atatus.state_metrics.hosts) 0 -}}
{{- if .Release.Name -}}
{{- range $index, $host := .Values.atatus.state_metrics.hosts -}}{{- if $index -}}, {{- end -}}"{{- $host -}}"{{- end -}}
{{- end -}}
{{- else -}}
"{{- .Release.Name | trunc 63 | trimSuffix "-" -}}-kube-state-metrics:8080"
{{- end -}}
{{- end -}}
