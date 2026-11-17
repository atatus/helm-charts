#!/usr/bin/env bash
# Check that a release tag can be published. Run by the Publish workflow on a
# tag push, and runnable locally before pushing one:
#
#   git fetch origin
#   .github/scripts/verify-release.sh atatus-agent-1.8.0
#
# The tag must be annotated (its message is the release notes), be named
# <chart>-<version> after a chart's Chart.yaml at the tagged commit, point at a
# commit on main that holds packages/<tag>.tgz, and that commit's index.yaml
# must list the package with its digest.
set -euo pipefail

tag="${1:?usage: verify-release.sh <chart>-<version>}"
cd "$(git rev-parse --show-toplevel)"

fail() { echo "error: $*" >&2; exit 1; }

chart_field() { sed -n "s/^$1:[[:space:]]*//p" | sed 's/[[:space:]]*#.*//' | tr -d "\"'"; }

[[ "$(git cat-file -t "refs/tags/$tag" 2>/dev/null)" == "tag" ]] \
  || fail "$tag is not an annotated tag. Its message is the release notes: create it with 'git tag -a'"

[[ "$tag" =~ ^(.+)-([0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?)$ ]] \
  || fail "$tag is not named <chart>-<version>"
chart="${BASH_REMATCH[1]}"
version="${BASH_REMATCH[2]}"

sha="$(git rev-parse "refs/tags/$tag^{commit}")"
pkg="packages/$tag.tgz"

git cat-file -e "$sha:charts/$chart/Chart.yaml" 2>/dev/null \
  || fail "$tag names chart '$chart', but there is no charts/$chart at $sha"

chart_version="$(git show "$sha:charts/$chart/Chart.yaml" | chart_field version)"
[[ "$chart_version" == "$version" ]] \
  || fail "charts/$chart/Chart.yaml at $sha has version $chart_version, not $version"

git cat-file -e "$sha:$pkg" 2>/dev/null \
  || fail "$pkg is not in $sha. Merge the release PR first, then tag its merge commit"

pkg_version="$(git show "$sha:$pkg" | tar -xzO "$chart/Chart.yaml" | chart_field version)"
[[ "$pkg_version" == "$version" ]] \
  || fail "$pkg holds version $pkg_version, not $version"

digest="$(git show "$sha:$pkg" | sha256sum | cut -d' ' -f1)"
# Each index entry lists its digest before its urls.
indexed="$(git show "$sha:index.yaml" | awk -v url="/$pkg" '
  $1 == "digest:" { d = $2 }
  $1 == "-" && length($2) >= length(url) && substr($2, length($2) - length(url) + 1) == url { print d; exit }')"
[[ -n "$indexed" ]] || fail "index.yaml at $sha does not list $pkg"
[[ "$indexed" == "$digest" ]] \
  || fail "index.yaml at $sha lists $pkg with digest $indexed, but the file's digest is $digest"

git merge-base --is-ancestor "$sha" origin/main \
  || fail "$tag points at $sha, which is not on main. Tag the release PR's merge commit"

if git rev-parse -q --verify origin/gh-pages >/dev/null; then
  git merge-base --is-ancestor origin/gh-pages "$sha" || git merge-base --is-ancestor "$sha" origin/gh-pages \
    || fail "gh-pages has commits that are not on main, so it cannot be fast-forwarded to $sha"
fi

echo "ok: $tag publishes $pkg ($version) from $sha"
