{{/*
Expand the name of the chart.
*/}}
{{- define "test.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "test.fullname" -}}
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

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "test.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "test.labels" -}}
helm.sh/chart: {{ include "test.chart" . }}
{{ include "test.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "test.selectorLabels" -}}
app.kubernetes.io/name: {{ include "test.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "test.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "test.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "app-template.sharedspec" }}

{{- with .Values.imagePullSecrets }}
imagePullSecrets:
{{- toYaml . | nindent 2 }}
{{- end }}
serviceAccountName: {{ include "test.serviceAccountName" . }}
securityContext:
{{- toYaml .Values.podSecurityContext | nindent 2 }}
{{- with .Values.nodeSelector }}
nodeSelector:
{{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.affinity }}
affinity:
{{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
{{- toYaml . | nindent 2 }}
{{- end }}
containers:
- name: {{ $.Chart.Name }}
  securityContext:
  {{- toYaml $.Values.securityContext | nindent 6 }}
  image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
  imagePullPolicy: {{ $.Values.image.pullPolicy }}
  ports:
    - name: http
      containerPort: 80
      protocol: TCP
  livenessProbe:
    httpGet:
      path: /
      port: http
  readinessProbe:
    httpGet:
      path: /
      port: http
  resources:
  {{- toYaml $.Values.resources | nindent 6 }}
{{- end }}

{{- define "app-template.inline-file-csi-volume"}}
- name: inline-share
  csi:
    driver: file.csi.azure.com
    readOnly: {{ .readonly | default "false" | quote }}
    volumeAttributes:
      shareName:  {{ .shareName | quote }}
      protocol: {{ .protocol | default "smb" | quote }}
      {{- if .subscriptionId }}
      subscriptionId: {{ .subscriptionId | quote }}
      {{- end }}
      {{- if .resourceGroup }}
      resourceGroup: {{ .resourceGroup | quote }}
      {{- end }}
      {{- if .accountName }}
      storageAccount: {{ .accountName | quote }}
      {{- end }}
      {{- if .folderName }}
      folderName: {{ .folderName | quote }}
      {{- end }}
      {{- if .server }}
      server: {{ .server | quote }}
      {{- end }}
      {{ if eq .protocol "nfs" }}
      mountOptions: {{ .mountOptions | default "dir_mode=0777,file_mode=0777,cache=strict,actimeo=30,nosharesock" | quote }}
      {{- end }}
{{- end }}