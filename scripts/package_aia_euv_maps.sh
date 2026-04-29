#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLES_DIR="$ROOT_DIR/bundles"
MANIFESTS_DIR="$ROOT_DIR/manifests"
WORKSPACE_ROOT="$(cd "$ROOT_DIR/.." && pwd)"
SOURCE_DIR="${GXRENDER_AIA_EUV_SOURCE_DIR:-$WORKSPACE_ROOT/test-data/jsoc_cache/2020-11-26}"
STAMP="${1:-20201126T195823Z}"

FILES=(
  aia.lev1_euv_12s.2020-11-26T195823Z.image.94.fits
  aia.lev1_euv_12s.2020-11-26T195823Z.image.131.fits
  aia.lev1_euv_12s.2020-11-26T195823Z.image.171.fits
  aia.lev1_euv_12s.2020-11-26T195823Z.image.193.fits
  aia.lev1_euv_12s.2020-11-26T195823Z.image.211.fits
  aia.lev1_euv_12s.2020-11-26T195823Z.image.304.fits
  aia.lev1_euv_12s.2020-11-26T195823Z.image.335.fits
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

usage() {
  cat <<USAGE
Usage: $0 [timestamp]

Default timestamp:
  20201126T195823Z

This will:
- copy the seven full-disk AIA EUV FITS files from GXRENDER_AIA_EUV_SOURCE_DIR
- package them as bundles/aia_euv_maps_<timestamp>.tar.gz
- write per-file SHA256 checksums to manifests/aia_euv_maps_<timestamp>.sha256
- write bundle SHA256 to manifests/aia_euv_maps_<timestamp>.bundle.sha256
- create a starter manifest at manifests/aia_euv_maps_<timestamp>.md if missing

Environment:
  GXRENDER_AIA_EUV_SOURCE_DIR
    Source directory containing the AIA EUV FITS files.
    Default: sibling test-data/jsoc_cache/2020-11-26
USAGE
}

if [[ $# -gt 1 ]]; then
  usage >&2
  exit 1
fi

mkdir -p "$BUNDLES_DIR" "$MANIFESTS_DIR"

BUNDLE_NAME="aia_euv_maps_${STAMP}.tar.gz"
BUNDLE_PATH="$BUNDLES_DIR/$BUNDLE_NAME"
RAW_SUMS="$MANIFESTS_DIR/aia_euv_maps_${STAMP}.sha256"
BUNDLE_SUM="$MANIFESTS_DIR/aia_euv_maps_${STAMP}.bundle.sha256"
MANIFEST_MD="$MANIFESTS_DIR/aia_euv_maps_${STAMP}.md"

TMP_ROOT="$(mktemp -d)"
TMP_SUMS="$(mktemp)"
cleanup() {
  rm -rf "$TMP_ROOT"
  rm -f "$TMP_SUMS"
}
trap cleanup EXIT

TMP_DIR="$TMP_ROOT/aia_euv_maps_${STAMP}"
mkdir -p "$TMP_DIR"

> "$TMP_SUMS"
for base in "${FILES[@]}"; do
  src="$SOURCE_DIR/$base"
  if [[ ! -f "$src" ]]; then
    echo "Missing source file: $src" >&2
    echo "Hint: set GXRENDER_AIA_EUV_SOURCE_DIR to the directory containing the seven AIA EUV FITS fixtures." >&2
    exit 1
  fi
  cp "$src" "$TMP_DIR/$base"
  printf '%s  %s\n' "$(sha256_file "$src")" "raw/aia_euv_maps/aia_euv_maps_${STAMP}/$base" >> "$TMP_SUMS"
done
mv "$TMP_SUMS" "$RAW_SUMS"

tar -czf "$BUNDLE_PATH" -C "$TMP_ROOT" "aia_euv_maps_${STAMP}"
printf '%s  %s\n' "$(sha256_file "$BUNDLE_PATH")" "bundles/$BUNDLE_NAME" > "$BUNDLE_SUM"

if [[ ! -f "$MANIFEST_MD" ]]; then
  {
    echo "# AIA EUV Map Bundle Manifest: $STAMP"
    echo
    echo "- Bundle name: \`$BUNDLE_NAME\`"
    echo "- Bundle timestamp: \`$STAMP\`"
    echo "- Prepared on: \`$(date -u +%Y-%m-%d)\`"
    echo "- Source directory: \`raw/aia_euv_maps/aia_euv_maps_${STAMP}\`"
    echo "- Observation epoch: \`2020-11-26T19:58:23Z\`"
    echo
    echo "## Bundle Files"
    echo
    echo "- Local archive: \`bundles/$BUNDLE_NAME\`"
    echo "- Raw-file checksums: \`manifests/aia_euv_maps_${STAMP}.sha256\`"
    echo "- Bundle checksum: \`manifests/aia_euv_maps_${STAMP}.bundle.sha256\`"
    echo "- Release tag: \`testdata-aia-euv-${STAMP}\`"
    echo "- Release URL: \`https://github.com/suncast-org/pyGXrender-test-data/releases/tag/testdata-aia-euv-${STAMP}\`"
    echo
    echo "## Raw FITS Files"
    echo
    for base in "${FILES[@]}"; do
      echo "- \`$base\`"
    done
    echo
    echo "## Provenance"
    echo
    echo "- These files are the full-disk AIA EUV maps corresponding to the EOVSA observational epoch used by the pyCHMP real-data and validation workflows."
    echo "- The source files are copied from \`GXRENDER_AIA_EUV_SOURCE_DIR\` (default: sibling \`test-data/jsoc_cache/2020-11-26\`)."
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
