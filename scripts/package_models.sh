#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLES_DIR="$ROOT_DIR/bundles"
MANIFESTS_DIR="$ROOT_DIR/manifests"
WORKSPACE_ROOT="$(cd "$ROOT_DIR/.." && pwd)"
SOURCE_DIR="${GXRENDER_MODELS_SOURCE_DIR:-$WORKSPACE_ROOT/gximagecomputing/test_data}"
STAMP="${1:-20251126T153431}"

FILES=(
  test.chr.sav
  test.chr.h5
  test.chr.sav.clone.h5
  test.chr.none.sav.h5
  test.none.from_fresh.h5
  test.none.from_savbox.h5
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

BUNDLE_NAME="models_${STAMP}.tar.gz"
BUNDLE_PATH="$BUNDLES_DIR/$BUNDLE_NAME"
RAW_SUMS="$MANIFESTS_DIR/models_${STAMP}.sha256"
BUNDLE_SUM="$MANIFESTS_DIR/models_${STAMP}.bundle.sha256"
MANIFEST_MD="$MANIFESTS_DIR/models_${STAMP}.md"

TMP_ROOT="$(mktemp -d)"
TMP_SUMS="$(mktemp)"
cleanup() {
  rm -rf "$TMP_ROOT"
  rm -f "$TMP_SUMS"
}
trap cleanup EXIT

TMP_DIR="$TMP_ROOT/models_${STAMP}"
mkdir -p "$TMP_DIR"

> "$TMP_SUMS"
for base in "${FILES[@]}"; do
  src="$SOURCE_DIR/$base"
  if [[ ! -f "$src" ]]; then
    echo "Missing source file: $src" >&2
    echo "Hint: set GXRENDER_MODELS_SOURCE_DIR to the directory containing the model fixtures." >&2
    exit 1
  fi
  cp "$src" "$TMP_DIR/$base"
  printf '%s  %s\n' "$(sha256_file "$src")" "$src" >> "$TMP_SUMS"
done
mv "$TMP_SUMS" "$RAW_SUMS"

tar -czf "$BUNDLE_PATH" -C "$TMP_ROOT" "models_${STAMP}"
printf '%s  %s\n' "$(sha256_file "$BUNDLE_PATH")" "$BUNDLE_PATH" > "$BUNDLE_SUM"

if [[ ! -f "$MANIFEST_MD" ]]; then
  {
    echo "# Model Bundle Manifest: $STAMP"
    echo
    echo "- Bundle name: \`$BUNDLE_NAME\`"
    echo "- Bundle timestamp: \`$STAMP\`"
    echo "- Created on: \`$(date -u +%Y-%m-%dT%H:%M:%SZ)\`"
    echo "- Source directory: \`$SOURCE_DIR\`"
    echo "- Source model epoch: \`2025-11-26T15:34:31\`"
    echo
    echo "## Bundle Files"
    echo
    echo "- Local archive: \`bundles/$BUNDLE_NAME\`"
    echo "- Raw-file checksums: \`manifests/models_${STAMP}.sha256\`"
    echo "- Bundle checksum: \`manifests/models_${STAMP}.bundle.sha256\`"
    echo
    echo "## Raw Model Files"
    echo
    for base in "${FILES[@]}"; do
      echo "- \`$base\`"
    done
    echo
    echo "## Provenance"
    echo
    echo "- These files are gximagecomputing model fixtures packaged without the separate EUV response tables."
    echo "- The bundle includes the main CHR SAV/HDF5 fixtures and the additional no-corona conversion variants currently used by local parity and rendering tests."
    echo "- The source files were copied from the directory referenced by \`GXRENDER_MODELS_SOURCE_DIR\` (default: sibling \`gximagecomputing/test_data\`)."
    echo "- Publish the archive as a GitHub Release asset rather than committing it to Git history."
  } > "$MANIFEST_MD"
fi

echo "Created bundle:   $BUNDLE_PATH"
echo "Raw checksums:    $RAW_SUMS"
echo "Bundle checksum:  $BUNDLE_SUM"
echo "Manifest:         $MANIFEST_MD"
echo
echo "Next suggested commands:"
echo "  cd '$ROOT_DIR'"
echo "  git add '$RAW_SUMS' '$BUNDLE_SUM' '$MANIFEST_MD'"
echo "  git status --short"
echo "  scripts/publish_bundle_release.sh <release-tag> '$BUNDLE_PATH' '$RAW_SUMS' '$BUNDLE_SUM' '$MANIFEST_MD'"
