#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage: $0 <release-tag> <asset1> [asset2 ...]

Examples:
  $0 responses-20251126T153431 \
     bundles/responses_20251126T153431.tar.gz \
     manifests/responses_20251126T153431.sha256 \
     manifests/responses_20251126T153431.bundle.sha256 \
     manifests/responses_20251126T153431.md

If the release does not exist, it will be created.
Assets are uploaded with --clobber so reruns replace existing files.
USAGE
}

if [[ $# -lt 2 ]]; then
  usage >&2
  exit 1
fi

TAG="$1"
shift

for path in "$@"; do
  if [[ ! -f "$path" ]]; then
    echo "Missing asset file: $path" >&2
    exit 1
  fi
done

if ! gh release view "$TAG" >/dev/null 2>&1; then
  gh release create "$TAG" --title "$TAG" --notes "pyGXrender test-data release assets for $TAG"
fi

gh release upload "$TAG" "$@" --clobber

echo "Uploaded assets to release: $TAG"
gh release view "$TAG"
