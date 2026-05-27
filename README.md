# rttl-charts
Helm charts for RTTL deployments

## Development
- Template using upstream charts and view output, eg: `helm template RELEASE_NAME jupyterhub/jupyterhub --values "charts/rttl-jupyterhub/dev-values.yaml" --version "v4.0.0" --api-versions "networking.k8s.io/v1/Ingress" --api-versions "policy/v1" --kube-version "1.30.5" --namespace release_namespace > output.yaml`
  - note that dev-values.yaml formatting differs since jupyterhub is not being used as a subchart in that case.

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
  - Update the `version:` field under `dependencies:` for `jupyterhub` to the desired JupyterHub chart version
  - Update this chart's `version:` field at the top level
- cd to './charts/rttl-jupyterhub' and run `helm dependency update`
- Verify contents of Chart.lock
- git commit, PR, etc
- Github Actions will run automatically after merge to main
- Available releases show up at https://github.com/uw-it-aca/rttl-charts/releases
- Update Vault rttl/$ENV/admin/config.yaml (`chart_version: "vX.X.X"`) to use new version of this chart.