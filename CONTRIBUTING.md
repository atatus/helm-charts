# Contributing Guidelines

* Install the follow packages: ``git``, ``kubectl``, ``helm``, ``helm-docs``. See this [tutorial](REQUIREMENTS.md).
* [OPTIONAL] Configure authentication on your Github account to use the SSH protocol instead of HTTP. Watch this tutorial to learn how to set up: https://help.github.com/en/github/authenticating-to-github/adding-a-new-ssh-key-to-your-github-account
* Create a fork this repository.
* Clone the forked repository to your local system:

```bash
git clone URL_FORKED_REPOSITORY
```

### Test development version

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

