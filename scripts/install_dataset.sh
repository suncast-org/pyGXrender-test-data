#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_ROOT="$ROOT_DIR/raw"
REPO="suncast-org/pyGXrender-test-data"
MODELS_TAG="${GXRENDER_DATA_MODELS_TAG:-models-20251126T153431}"
RESPONSES_TAG="${GXRENDER_DATA_RESPONSES_TAG:-responses-20251126T153431}"
EBTEL_TAG="${GXRENDER_DATA_EBTEL_TAG:-ebtel-gxsimulator-euv}"

usage() {
  cat <<USAGE
Usage: $0 [--target-root DIR] [--repo OWNER/REPO] [--models-tag TAG] [--responses-tag TAG] [--ebtel-tag TAG]

Installs the default pyGXrender fixture set by downloading release assets and
extracting them under the target raw-data directory.

Defaults:
  --target-root   $ROOT_DIR/raw
  --repo          suncast-org/pyGXrender-test-data
  --models-tag    $MODELS_TAG
  --responses-tag $RESPONSES_TAG
  --ebtel-tag     $EBTEL_TAG
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target-root)
      TARGET_ROOT="$2"
      shift 2
      ;;
    --repo)
      REPO="$2"
      shift 2
      ;;
    --models-tag)
      MODELS_TAG="$2"
      shift 2
      ;;
    --responses-tag)
      RESPONSES_TAG="$2"
      shift 2
      ;;
    --ebtel-tag)
      EBTEL_TAG="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) is required for install_dataset.sh." >&2
  exit 1
fi

TARGET_ROOT="$(cd "$(dirname "$TARGET_ROOT")" && pwd)/$(basename "$TARGET_ROOT")"
mkdir -p "$TARGET_ROOT"

download_and_extract() {
  local tag="$1"
  local dest="$2"
  local tmp_dir
  local bundle_file
  local bundle_sum

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN

  echo "Downloading release assets for tag: $tag"
  gh release download "$tag" \
    --repo "$REPO" \
    --dir "$tmp_dir" \
    --clobber \
    --pattern "*.tar.gz" \
    --pattern "*.bundle.sha256" \
    --pattern "*.sha256" \
    --pattern "*.md"

  bundle_file="$(find "$tmp_dir" -maxdepth 1 -type f -name '*.tar.gz' | head -n 1)"
  bundle_sum="$(find "$tmp_dir" -maxdepth 1 -type f -name '*.bundle.sha256' | head -n 1)"

  if [[ -z "$bundle_file" || -z "$bundle_sum" ]]; then
    echo "Missing bundle or checksum asset for release tag: $tag" >&2
    exit 1
  fi

  (
    cd "$tmp_dir"
    shasum -a 256 -c "$(basename "$bundle_sum")"
  )

  mkdir -p "$dest"
  tar -xzf "$bundle_file" -C "$dest"

  echo "Installed $tag into $dest"
}

download_and_extract "$MODELS_TAG" "$TARGET_ROOT/models"
download_and_extract "$RESPONSES_TAG" "$TARGET_ROOT/responses"
download_and_extract "$EBTEL_TAG" "$TARGET_ROOT/ebtel"

echo
echo "Dataset install complete."
echo "Set GXRENDER_TEST_DATA_ROOT=$TARGET_ROOT if gxrender is not checked out next to this repository."
