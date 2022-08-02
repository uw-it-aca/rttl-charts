# rttl-charts
Helm charts for RTTL deployments

## Update process
- Make changes
- Update version in main Chart.yaml
- If the changes were in a subchart:
  - Update that version in the subchart's Chart.yaml
  - Update the subchart dependencies in the main Chart.yaml
  - cd to './charts/rttl-jupyterhub' and run `helm dependency update`
  - Verify contents of Chart.lock
- git commit etc