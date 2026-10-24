# Atatus Kubernetes Helm Charts

This is the official Helm charts repository for Atatus.

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

## Usage

[Helm](https://helm.sh) must be installed to use the charts.
Please refer to Helm's [documentation](https://helm.sh/docs/) to get started.

Once Helm is set up properly, add the repo as follows:

```console
helm repo add atatus https://atatus.github.io/helm-charts
```

You can then run `helm search repo atatus` to see the charts.

## Charts

| Chart | What it collects |
|---|---|
| `atatus-agent` | Infrastructure metrics, container and node logs, and Kubernetes state. |
| `atatus-one-agent` | eBPF telemetry: traces and request logs, network flows, profiles and process events, with no code change in the applications. |

The two run alongside each other, not instead of one another. Install both with the **same**
`atatus.license_key` and the **same** `atatus.cluster_name`, or one cluster appears twice in the account.

<!-- Keep full URL links to repo files because this README syncs from main to gh-pages.  -->
Chart documentation is available for
[atatus-agent](https://github.com/atatus/helm-charts/blob/main/charts/atatus-agent/README.md) and
[atatus-one-agent](https://github.com/atatus/helm-charts/blob/main/charts/atatus-one-agent/README.md).

## License

<!-- Keep full URL links to repo files because this README syncs from main to gh-pages.  -->
[Apache 2.0 License](https://github.com/atatus/helm-charts/blob/main/LICENSE).