#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_ROOT="$ROOT_DIR/raw"
REPO="suncast-org/pyGXrender-test-data"
MODELS_TAG="${GXRENDER_DATA_MODELS_TAG:-testdata-models-20201126T195831}"
EOVSA_TAG="${GXRENDER_DATA_EOVSA_TAG:-testdata-eovsa-20201126T200000Z}"
AIA_EUV_TAG="${GXRENDER_DATA_AIA_EUV_TAG:-testdata-aia-euv-20201126T195823Z}"
MODEL_LOADER_PARITY_TAG="${GXRENDER_DATA_MODEL_LOADER_PARITY_TAG:-testdata-model-loader-parity-20201126T195831}"
RESPONSES_TAG="${GXRENDER_DATA_RESPONSES_TAG:-responses-20251126T153431}"
EBTEL_TAG="${GXRENDER_DATA_EBTEL_TAG:-ebtel-gxsimulator-euv}"

usage() {
  cat <<USAGE
Usage: $0 [--target-root DIR] [--repo OWNER/REPO] [--models-tag TAG] [--eovsa-tag TAG] [--aia-euv-tag TAG] [--model-loader-parity-tag TAG] [--responses-tag TAG] [--ebtel-tag TAG]

Installs the default pyGXrender fixture set by downloading release assets and
extracting them under the target raw-data directory.

Defaults:
  --target-root   $ROOT_DIR/raw
  --repo          suncast-org/pyGXrender-test-data
  --models-tag    $MODELS_TAG
  --eovsa-tag     $EOVSA_TAG
  --aia-euv-tag   $AIA_EUV_TAG
  --model-loader-parity-tag $MODEL_LOADER_PARITY_TAG (set to empty string to skip)
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
    --eovsa-tag)
      EOVSA_TAG="$2"
      shift 2
      ;;
    --responses-tag)
      RESPONSES_TAG="$2"
      shift 2
      ;;
    --aia-euv-tag)
      AIA_EUV_TAG="$2"
      shift 2
      ;;
    --model-loader-parity-tag)
      MODEL_LOADER_PARITY_TAG="$2"
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

sha256_file() {
  local path="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$path" | awk '{print $1}'
    return
  fi
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$path" | awk '{print $1}'
    return
  fi
  if command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 "$path" | awk '{print $NF}'
    return
  fi
  echo "No SHA-256 tool found (need one of: sha256sum, shasum, openssl)." >&2
  exit 1
}

TARGET_ROOT="$(cd "$(dirname "$TARGET_ROOT")" && pwd)/$(basename "$TARGET_ROOT")"
mkdir -p "$TARGET_ROOT"

download_and_extract() {
  local tag="$1"
  local dest="$2"
  local asset_prefix="$3"
  local tmp_dir
  local bundle_file
  local bundle_sum
  local bundle_name
  local expected_sum
  local actual_sum

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN

  echo "Downloading release assets for tag: $tag"
  gh release download "$tag" \
    --repo "$REPO" \
    --dir "$tmp_dir" \
    --clobber \
    --pattern "${asset_prefix}*.tar.gz" \
    --pattern "${asset_prefix}*.bundle.sha256" \
    --pattern "${asset_prefix}*.sha256" \
    --pattern "${asset_prefix}*.md"

  bundle_file="$(find "$tmp_dir" -maxdepth 1 -type f -name "${asset_prefix}*.tar.gz" | head -n 1)"
  bundle_sum="$(find "$tmp_dir" -maxdepth 1 -type f -name "${asset_prefix}*.bundle.sha256" | head -n 1)"

  if [[ -z "$bundle_file" || -z "$bundle_sum" ]]; then
    echo "Missing bundle or checksum asset for release tag: $tag" >&2
    exit 1
  fi

  bundle_name="$(basename "$bundle_file")"
  expected_sum="$(awk '{print $1}' "$bundle_sum")"
  actual_sum="$(sha256_file "$bundle_file")"

  if [[ -z "$expected_sum" || -z "$actual_sum" ]]; then
    echo "Failed to compute bundle checksum for release tag: $tag" >&2
    exit 1
  fi

  if [[ "$expected_sum" != "$actual_sum" ]]; then
    echo "Checksum mismatch for $bundle_name" >&2
    echo "  expected: $expected_sum" >&2
    echo "  actual:   $actual_sum" >&2
    exit 1
  fi

  mkdir -p "$dest"
  tar -xzf "$bundle_file" -C "$dest"

  echo "Installed $tag into $dest"
}

download_and_extract "$MODELS_TAG" "$TARGET_ROOT/models" "models_"
if [[ -n "$MODEL_LOADER_PARITY_TAG" ]]; then
  download_and_extract "$MODEL_LOADER_PARITY_TAG" "$TARGET_ROOT/models" "model_loader_parity_"
else
  echo "Skipping model-loader parity fixtures because --model-loader-parity-tag is empty."
fi
download_and_extract "$EOVSA_TAG" "$TARGET_ROOT/eovsa_maps" "eovsa_maps_"
if [[ -n "$AIA_EUV_TAG" ]]; then
  download_and_extract "$AIA_EUV_TAG" "$TARGET_ROOT/aia_euv_maps" "aia_euv_maps_"
fi
download_and_extract "$RESPONSES_TAG" "$TARGET_ROOT/responses" "responses_"
download_and_extract "$EBTEL_TAG" "$TARGET_ROOT/ebtel" "ebtel_"

echo
echo "Dataset install complete."
echo "Set GXRENDER_TEST_DATA_ROOT=$TARGET_ROOT if gxrender is not checked out next to this repository."
