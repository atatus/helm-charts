# Atatus Agent Helm Charts

## Installing

### Install a released version using the Helm repository

* Add the Atatus Helm charts repo:

```
helm repo add atatus https://github.com/atatus/helm-charts
```

* Install it:

```
helm install atatus charts/atatus-agent -f ./atatus_values.yaml
```

Here `atatus_values.yml` will have your license key and other settings.



### Install development version

* Go the helm-charts repo:

```bash
cd helm-charts/charts
```

* Generate template with test values:

```bash
helm template test-release charts/atatus-agent --debug -f ./atatus_values.yaml
```

* Dry run the helm install:

```bash
helm install test-release charts/atatus-agent --debug --dry-run -f ./atatus_values.yaml
```

* Install it:

```bash
helm install test-release charts/atatus-agent --debug -f ./atatus_values.yaml
```

* Upgrade existing helm release

```bash
helm upgrade test-release charts/atatus-agent -f ./atatus_values.yaml
```

* Upgrade existing helm release with force restarting of pods

```bash
helm upgrade --recreate-pods test-release charts/atatus-agent -f ./atatus_values.yaml
```

* Uninstall release

```bash
    helm uninstall test-release
```


## Configuration



## License

The project is released under version 2.0 of the [Apache license](http://www.apache.org/licenses/LICENSE-2.0).





