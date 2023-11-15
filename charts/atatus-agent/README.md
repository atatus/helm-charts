# Atatus Agent Helm Charts

## Installing

### Add the Atatus Helm charts repo:

```console
helm repo add atatus https://atatus.github.io/helm-charts
helm repo update
```

_See [helm repo](https://helm.sh/docs/helm/helm_repo/) for command documentation._

### Installing the Chart

To install the chart with the release name `atatus-release`:

```console
helm install atatus-release atatus/atatus-agent -f ./values.yaml
```

Here `values.yml` will have your license key and other settings.


### Uninstalling the Chart:

To uninstall/delete the atatus-release deployment:

```console
helm uninstall atatus-release
```

## Configuration

| Parameter                             | Description                       | Default                                 |
|---------------------------------------|-----------------------------------|-----------------------------------------|
| `atatus.license_key`                  | The Atatus Infra License Key.     |                                         |
| `atatus.cluster_name`                 | Your cluster name                 |`default`                              |
| `atatus.logs_enabled`                 | Enable Log Monitoring             |`true`                                 |
| `atatus.notify_url`                   | Atatus Endpoint for Infra Metrics | `""`                                  |
| `atatus.log_notify_url`               | Atatus Endpoint for Logs Collection | `""`                                |


### Example values.yaml

```yaml
atatus:
  license_key: "lic_infra_*****"
  cluster_name: "ecom-cluster"
  logs_enabled: true
```

## License

The project is released under version 2.0 of the [Apache license](http://www.apache.org/licenses/LICENSE-2.0).





