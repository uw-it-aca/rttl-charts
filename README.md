# rttl-charts
Helm charts for RTTL deployments

## Feature: NFS

Gives every user in a hub a shared read/write folder at `/home/jovyan/Shared`,
backed by a per-hub, in-namespace NFS server.

- Set `global.rttl.features.nfs.enabled=true` (per-deployment `--set`, layer 3), and
- Pass `supplemental-nfs-values.yaml` as an extra `--values` (layer 4) — it mounts
  `pvc-jupyterhub-nfs` into every singleuser pod at `/home/jovyan/Shared`.

What it renders: (the `rttl-jh-nfs` subchart, gated by the `nfs.enabled`
condition in `Chart.yaml`): an `nfs-server` Deployment (privileged) + Service, a
backing PVC/PV on `global.rttl.pvstorageclass`, and a `ReadWriteMany` claim
`pvc-jupyterhub-nfs`.

The flag alone deploys the NFS server; the supplemental file is what actually
mounts the share into user pods, so both are needed for the full feature.

## Feature: OIDC Auth

Points the hub's login at UW IdP OIDC directly - the hub runs
`GenericOAuthenticator` against `idp.u.washington.edu` instead of the default
Canvas OAuth. Use this when the hub does OIDC itself; contrast with Gateway
OIDC below, where the gateway terminates OIDC and the hub only trusts a header.

- Pass `supplemental-oidcauth-values.yaml` as an extra `--values`
(layer 4). That file sets `global.rttl.features.oidc.enabled: true` and the UW IdP
`GenericOAuthenticator` config (authorize/token/userinfo URLs, `client_id`,
`scope`, `username_key: sub`, `authenticator_class: generic-oauth`).

Two fields are intentionally left blank and must be injected per-deployment
(layer 3 `--set`): `jupyterhub.hub.config.GenericOAuthenticator.client_secret`
and `oauth_callback_url`.

## Feature: kgateway

Routes the hub through kgateway (Gateway API) instead of the deprecated
ingress-nginx. When on, the chart renders an `HTTPRoute`
(`templates/httproute.yaml`) that attaches to a shared `ListenerSet` and sends
traffic to `proxy-public`, with nginx `Ingress` being suppressed.

- Set `global.rttl.features.kgateway.enabled=true` plus the three per-cluster
  values — `listenerSetName`, `listenerSetNamespace` (default `default`), and
  `hostname` (all required) via `--set` (layer 3), and
- Pass `supplemental-kgateway-values.yaml` as an extra `--values` (layer 4), which
  sets `jupyterhub.ingress.enabled: false`.

Cluster prerequisites (not rendered by this chart): the shared `ListenerSet`
named above must already exist for the cluster hostname, and a WebSocket
`ListenerPolicy` must exist in `kgateway-system`. Without it kgateway returns
403 on all JupyterLab WebSocket connections.

See kgateway HTTP to HTTPS redirect below to additionally force https.

## Feature: kgateway HTTP to HTTPS redirect

When the kgateway feature is on, the hub route attaches to the ListenerSet by
hostname and binds every matching listener (both `:80` and `:443`). To force
HTTP to HTTPS, set both listener section names on the ListenerSet:

- `global.rttl.features.kgateway.httpSectionName` — the `:80` listener (e.g. `jupyter-eval-http`)
- `global.rttl.features.kgateway.httpsSectionName` — the `:443` listener (e.g. `jupyter-eval-https`)

With both set, the chart pins the main and api routes to the `:443` listener and
renders a redirect route on the `:80` listener. Setting `httpSectionName` without
`httpsSectionName` fails at template time. The main/api routes must be pinned to
`:443` so `:80` carries only the redirect (otherwise both match on `:80` and
Gateway API tie-breaks nondeterministically). Leave both values empty for the
default behavior (route attaches to all listeners, no redirect).

## Feature: Gateway OIDC (kgateway extAuth / header-trust)

Optionally moves UW SSO off the hub and onto the gateway. When enabled, the
gateway (kgateway) terminates UW OIDC and injects an `X-Auth-Request-User`
header; the hub runs a `RemoteUserAuthenticator` that trusts that header instead
of doing its own Canvas OAuth. Gated by `global.rttl.features.gatewayOIDC.enabled`
(default `false`), so existing hubs are unaffected.

## Development
- Template using upstream charts and view output, eg: 
```bash
helm template RELEASE_NAME jupyterhub/jupyterhub \
--values "charts/rttl-jupyterhub/dev-values.yaml" \
--version "v4.0.0" \
--api-versions "networking.k8s.io/v1/Ingress" \
--api-versions "policy/v1" \
--kube-version "1.30.5" \
--namespace release_namespace > output.yaml
```
  - Note that dev-values.yaml formatting differs since jupyterhub is not being
  used as a subchart in that case.

## Update process
- Make changes
- Update version in main Chart.yaml
- If the changes were in a subchart:
  - Update that version in the subchart's Chart.yaml
  - Update the subchart dependencies in the main Chart.yaml
- cd to './charts/rttl-jupyterhub' and run `helm dependency update`
- Verify contents of Chart.lock
- git commit, PR, etc
- Github Actions will run automatically after merge to main
- Available releases show up at https://github.com/uw-it-aca/rttl-charts/releases
- Update Vault rttl/prod/admin/config.yaml to reflect new version

## Updating the JupyterHub chart version
- Check latest versions at https://hub.jupyter.org/helm-chart/
- Edit `charts/rttl-jupyterhub/Chart.yaml`:
  - Update the `version:` field under `dependencies:` for `jupyterhub` to the
  desired JupyterHub chart version
  - Update this chart's `version:` field at the top level
- cd to './charts/rttl-jupyterhub' and run `helm dependency update`
- Verify contents of Chart.lock
- git commit, PR, etc
- Github Actions will run automatically after merge to main
- Available releases show up at https://github.com/uw-it-aca/rttl-charts/releases
- Update Vault rttl/$ENV/admin/config.yaml (`chart_version: "vX.X.X"`) to use
new version of this chart.