#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLES_DIR="$ROOT_DIR/bundles"
MANIFESTS_DIR="$ROOT_DIR/manifests"
STAMP="${1:-20201126T195831}"
SOURCE_DIR_DEFAULT="$ROOT_DIR/raw/models/model_loader_parity_${STAMP}"
SOURCE_DIR="${GXRENDER_MODEL_LOADER_PARITY_SOURCE_DIR:-$SOURCE_DIR_DEFAULT}"
SOURCE_DIR_REL="${SOURCE_DIR#$ROOT_DIR/}"

FILES=(
  hmi.M_720s.20201126_195831.E18S19CR.CEA.NAS.CHR.sav
  hmi.M_720s.20201126_195831.E18S19CR.CEA.NAS.CHR.clone.h5
)

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

mkdir -p "$BUNDLES_DIR" "$MANIFESTS_DIR"

BUNDLE_NAME="model_loader_parity_${STAMP}.tar.gz"
BUNDLE_PATH="$BUNDLES_DIR/$BUNDLE_NAME"
RAW_SUMS="$MANIFESTS_DIR/model_loader_parity_${STAMP}.sha256"
BUNDLE_SUM="$MANIFESTS_DIR/model_loader_parity_${STAMP}.bundle.sha256"
MANIFEST_MD="$MANIFESTS_DIR/model_loader_parity_${STAMP}.md"

TMP_ROOT="$(mktemp -d)"
TMP_SUMS="$(mktemp)"
cleanup() {
  rm -rf "$TMP_ROOT"
  rm -f "$TMP_SUMS"
}
trap cleanup EXIT

TMP_DIR="$TMP_ROOT/model_loader_parity_${STAMP}"
mkdir -p "$TMP_DIR"

> "$TMP_SUMS"
for base in "${FILES[@]}"; do
  src="$SOURCE_DIR/$base"
  if [[ ! -f "$src" ]]; then
    echo "Missing source file: $src" >&2
    echo "Hint: set GXRENDER_MODEL_LOADER_PARITY_SOURCE_DIR to the parity fixture directory." >&2
    exit 1
  fi
  cp "$src" "$TMP_DIR/$base"
  printf '%s  %s\n' "$(sha256_file "$src")" "$SOURCE_DIR_REL/$base" >> "$TMP_SUMS"
done
mv "$TMP_SUMS" "$RAW_SUMS"

tar -czf "$BUNDLE_PATH" -C "$TMP_ROOT" "model_loader_parity_${STAMP}"
printf '%s  %s\n' "$(sha256_file "$BUNDLE_PATH")" "bundles/$BUNDLE_NAME" > "$BUNDLE_SUM"

{
  echo "# Model Loader Parity Bundle Manifest: $STAMP"
  echo
  echo "- Bundle name: \`$BUNDLE_NAME\`"
  echo "- Bundle timestamp: \`$STAMP\`"
  echo "- Created on: \`$(date -u +%Y-%m-%dT%H:%M:%SZ)\`"
  echo "- Source directory: \`$SOURCE_DIR_REL\`"
  echo "- Source model epoch: \`2020-11-26T19:58:31.300\`"
  echo
  echo "## Bundle Files"
  echo
  echo "- Local archive: \`bundles/$BUNDLE_NAME\`"
  echo "- Raw-file checksums: \`manifests/model_loader_parity_${STAMP}.sha256\`"
  echo "- Bundle checksum: \`manifests/model_loader_parity_${STAMP}.bundle.sha256\`"
  echo "- Release tag: \`testdata-model-loader-parity-${STAMP}\`"
  echo "- Release URL: \`https://github.com/suncast-org/pyGXrender-test-data/releases/tag/testdata-model-loader-parity-${STAMP}\`"
  echo
  echo "## Raw Model Files"
  echo
  for base in "${FILES[@]}"; do
    echo "- \`$base\`"
  done
  echo
  echo "## Provenance"
  echo
  echo "- The SAV source is the IDL-generated CHR model:"
  echo "  \`hmi.M_720s.20201126_195831.E18S19CR.CEA.NAS.CHR.sav\`."
  echo "- The clone H5 was generated from that SAV with gximagecomputing's"
  echo "  \`gxrender.io.sav_to_h5.build_h5_from_sav\` after the SAV/H5 axis-order"
  echo "  normalization fix."
  echo "- The pair is intended for strict loader parity tests, not as the default"
  echo "  rendering model bundle."
  echo "- Publish the archive as a GitHub Release asset rather than committing it to Git history."
} > "$MANIFEST_MD"

echo "Created bundle:   $BUNDLE_PATH"
echo "Raw checksums:    $RAW_SUMS"
echo "Bundle checksum:  $BUNDLE_SUM"
echo "Manifest:         $MANIFEST_MD"
echo
echo "Next suggested commands:"
echo "  cd '$ROOT_DIR'"
echo "  git add '$RAW_SUMS' '$BUNDLE_SUM' '$MANIFEST_MD' scripts/package_model_loader_parity.sh scripts/install_dataset.sh"
echo "  git status --short"
echo "  scripts/publish_bundle_release.sh testdata-model-loader-parity-${STAMP} '$BUNDLE_PATH' '$RAW_SUMS' '$BUNDLE_SUM' '$MANIFEST_MD'"
