#!/usr/bin/env bash
# Package every chart under charts/ whose Chart.yaml version has no package in
# packages/ yet, and add the new packages to index.yaml.
#
# index.yaml is merged, not regenerated, so existing entries keep their
# created timestamps and only the packages built here are added. Dependencies
# are fetched fresh from their repositories, never taken from a copy left in
# charts/<chart>/charts/.
#
# Run by the Release PR workflow, and runnable locally from a clean checkout of
# main:
#
#   .github/scripts/package-charts.sh
set -euo pipefail

REPO_URL="${REPO_URL:-https://atatus.github.io/helm-charts/packages}"
CI_VALUES_DIR=".github/ci"

cd "$(git rev-parse --show-toplevel)"

fail() { echo "error: $*" >&2; exit 1; }

# Read a top-level key of a Chart.yaml given on stdin.
chart_field() { sed -n "s/^$1:[[:space:]]*//p" | sed 's/[[:space:]]*#.*//' | tr -d "\"'"; }

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir "$work/new"

# Keep the repositories added for dependencies out of the caller's helm config.
export HELM_REPOSITORY_CONFIG="$work/repositories.yaml"
export HELM_REPOSITORY_CACHE="$work/repository-cache"

built=0
for dir in charts/*/; do
  dir="${dir%/}"
  name="$(chart_field name < "$dir/Chart.yaml")"
  version="$(chart_field version < "$dir/Chart.yaml")"
  pkg="packages/${name}-${version}.tgz"

  # A release tag <name>-<version> maps back to charts/<name>.
  [[ "$name" == "$(basename "$dir")" ]] || fail "$dir/Chart.yaml is named '$name': the directory and the chart name must match"

  if [[ -e "$pkg" ]]; then
    echo "skip: $name $version is already packaged as $pkg"
    continue
  fi
  if grep -q "/${pkg}\$" index.yaml; then
    fail "index.yaml lists $pkg, but the file is missing from packages/"
  fi

  echo "::group::package $name $version"

  if grep -q '^dependencies:' "$dir/Chart.yaml"; then
    # helm dependency build only downloads from repositories it knows by URL.
    while read -r repo; do
      helm repo add "dep-$(sha1sum <<<"$repo" | cut -c1-8)" "$repo" >/dev/null
    done < <(helm dependency list "$dir" | awk 'NR > 1 && $3 ~ /^https?:\/\// { print $3 }' | sort -u)
    helm dependency build "$dir"
  fi

  values=()
  if [[ -f "$CI_VALUES_DIR/$name.yaml" ]]; then
    values=(-f "$CI_VALUES_DIR/$name.yaml")
  fi

  helm lint "$dir" "${values[@]}"
  helm package "$dir" -d "$work/new"
  # Render the package itself, with the dependencies it bundles.
  helm template ci "$work/new/${name}-${version}.tgz" "${values[@]}" >/dev/null

  echo "::endgroup::"
  built=$((built + 1))
done

if (( built == 0 )); then
  echo "Every chart's version is already packaged: nothing to release."
  exit 0
fi

helm repo index "$work/new" --url "$REPO_URL" --merge index.yaml
cp "$work/new/"*.tgz packages/
cp "$work/new/index.yaml" index.yaml
echo "Packaged $built chart(s) into packages/ and added them to index.yaml."
