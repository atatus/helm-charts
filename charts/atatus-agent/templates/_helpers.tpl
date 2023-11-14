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


{{- define "state-metrics.fullname" -}}
{{- if gt (len .Values.atatus.state_metrics.hosts) 0 -}}
{{- if .Release.Name -}}
{{- range $index, $host := .Values.atatus.state_metrics.hosts -}}{{- if $index -}}, {{- end -}}"{{- $host -}}"{{- end -}}
{{- end -}}
{{- else -}}
"{{- .Release.Name | trunc 63 | trimSuffix "-" -}}-kube-state-metrics:8080"
{{- end -}}
{{- end -}}
