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


## Releasing a chart

A release takes two merged PRs and a tag. The [Release PR](.github/workflows/release-pr.yaml) and
[Publish](.github/workflows/publish.yaml) workflows do the packaging and publishing, so nothing is packaged by hand.

1. **Bump the version.** In your PR, raise `version` in `charts/<chart>/Chart.yaml`, and `appVersion` when the
   agent image changes. When the PR merges to `main`, the Release PR workflow lints the chart and packages it
   with freshly fetched dependencies. It adds the package to `index.yaml` and opens a PR titled
   `release <chart>-<version>`.
   To run it again, for example after changing the workflow, use **Actions → Release PR → Run workflow** on `main`.
2. **Merge the release PR.** Review and merge it like any other PR. Don't push to its branch, `bot/release`:
   the workflow rebuilds that branch from `main` every time it runs.
3. **Tag the merge commit.** The tag message becomes the "What's Changed" list of the GitHub Release:

   ```bash
   git fetch origin
   git tag -a atatus-agent-1.8.0 origin/main      # write the notes as "* ..." bullets
   .github/scripts/verify-release.sh atatus-agent-1.8.0
   git push origin atatus-agent-1.8.0
   ```

   git's editor drops lines that start with `#`, so don't put Markdown headings in the message.

Pushing the tag runs the Publish workflow. It checks the tag and fast-forwards `gh-pages` to the tagged commit,
so `helm repo update` sees the new version once GitHub Pages rebuilds. Then it creates the GitHub Release
with the package attached.

A tag that fails the checks publishes nothing. Delete it with `git push origin :refs/tags/<tag>` and
`git tag -d <tag>`, fix the cause, and tag again.
