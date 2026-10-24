{{- define "atatus-one-agent.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "atatus-one-agent.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "atatus-one-agent.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ include "atatus-one-agent.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "atatus-one-agent.selectorLabels" -}}
app.kubernetes.io/name: {{ include "atatus-one-agent.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: agent
{{- end }}

{{- define "atatus-one-agent.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "atatus-one-agent.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "atatus-one-agent.licenseSecret" -}}
{{- default (printf "%s-license" (include "atatus-one-agent.fullname" .)) .Values.atatus.existingSecret }}
{{- end }}

{{/*
The container image. Two value shapes are accepted, because the atatus-agent chart of the helm-charts
repository uses the flat one and an operator with both charts installed should be able to keep one values
file:

  image: {repository: atatus/one-agent, tag: "", pullPolicy: IfNotPresent}   this chart's own shape
  image: atatus/one-agent            with imageTag / imagePullPolicy        the atatus-agent shape

A string image is read with imageTag and imagePullPolicy; a map with its own keys. Nothing else is guessed:
an image value that is neither fails the render rather than producing "<nil>:<nil>".
*/}}
{{- define "atatus-one-agent.image" -}}
{{- if kindIs "string" .Values.image }}
{{- if not .Values.image }}{{ fail "image is empty: set image.repository, or image plus imageTag" }}{{ end }}
{{- printf "%s:%s" .Values.image (default .Chart.AppVersion .Values.imageTag) }}
{{- else if kindIs "map" .Values.image }}
{{- if not .Values.image.repository }}{{ fail "image.repository is required" }}{{ end }}
{{- printf "%s:%s" .Values.image.repository (default .Chart.AppVersion .Values.image.tag) }}
{{- else }}
{{- fail (printf "image must be a string or a map, got %s" (kindOf .Values.image)) }}
{{- end }}
{{- end }}

{{/* The pull policy, from whichever of the two shapes was used. */}}
{{- define "atatus-one-agent.imagePullPolicy" -}}
{{- if kindIs "map" .Values.image }}
{{- default "IfNotPresent" .Values.image.pullPolicy }}
{{- else }}
{{- default "IfNotPresent" .Values.imagePullPolicy }}
{{- end }}
{{- end }}

{{/* The static config (atatus-one-agent.yaml); chart-owned keys win over extraStaticConfig. */}}
{{- define "atatus-one-agent.staticConfig" -}}
{{- $generated := dict "controller-ips" .Values.controller.hosts "kubernetes-cluster-name" .Values.atatus.cluster_name }}
{{- if eq .Values.tls.mode "disabled" }}
{{- $_ := set $generated "controller-port" (int .Values.controller.port) }}
{{- $_ := set $generated "controller-cert-file-prefix" "" }}
{{- else }}
{{- $_ := set $generated "controller-tls-port" (int .Values.controller.tlsPort) }}
{{- $_ := set $generated "controller-cert-file-prefix" (ternary "system" "/etc/atatus-one-agent/tls/ca.pem" (eq .Values.tls.mode "system")) }}
{{- end }}
{{- if .Values.atatus.agentGroupId }}
{{- $_ := set $generated "vtap-group-id-request" .Values.atatus.agentGroupId }}
{{- end }}
{{- $_ := set $generated "liveness-probe-port" (int .Values.livenessProbe.port) }}
{{- toYaml (mergeOverwrite (deepCopy .Values.extraStaticConfig) $generated) }}
{{- end }}
