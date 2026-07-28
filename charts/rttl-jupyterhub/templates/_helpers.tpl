{{/*
Name of the per-hub HTTPRoute. Single source of truth so the main route
(httproute.yaml), the api-exempt route (httproute-api.yaml), and the oauth2
TrafficPolicy (trafficpolicy.yaml) all agree on the target name. In this chart
the route is the release name and should line up correctly.
*/}}
{{- define "rttl-jupyterhub.hubRouteName" -}}
{{- .Release.Name -}}
{{- end -}}

{{/*
Feature-dependency guard. The gatewayOIDC feature layers on top of the kgateway
HTTPRoute/ListenerSet plumbing, so it requires kgateway.enabled. The dependency
is one-directional (kgateway may run without gatewayOIDC). Enforced at
`helm template` time.
*/}}
{{- define "rttl-jupyterhub.validateGatewayOIDC" -}}
{{- if .Values.global.rttl.features.gatewayOIDC.enabled -}}
{{- if not .Values.global.rttl.features.kgateway.enabled -}}
{{- fail "global.rttl.features.gatewayOIDC.enabled requires global.rttl.features.kgateway.enabled=true (gatewayOIDC needs the kgateway HTTPRoute/ListenerSet plumbing)" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
ListenerSet section-name guard. The HTTP->HTTPS redirect (httproute-redirect.yaml)
binds the :80 listener; for it to win deterministically the hub/api routes must be
pinned to the :443 listener. So httpSectionName cannot be set without
httpsSectionName. (httpsSectionName alone is allowed: pin to :443, no redirect.)
*/}}
{{- define "rttl-jupyterhub.validateKgatewaySectionNames" -}}
{{- if .Values.global.rttl.features.kgateway.httpSectionName -}}
{{- if not .Values.global.rttl.features.kgateway.httpsSectionName -}}
{{- fail "global.rttl.features.kgateway.httpSectionName requires httpsSectionName (the HTTP->HTTPS redirect binds the :80 listener, so the hub/api routes must be pinned to the :443 listener via httpsSectionName; otherwise both match :80 and Gateway API tie-breaks nondeterministically)" -}}
{{- end -}}
{{- end -}}
{{- end -}}
