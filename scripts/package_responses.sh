#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RAW_DIR="$ROOT_DIR/raw/responses"
BUNDLES_DIR="$ROOT_DIR/bundles"
MANIFESTS_DIR="$ROOT_DIR/manifests"

usage() {
  cat <<USAGE
Usage: $0 <timestamp-dir-name>

Example:
  $0 20251126T153431

This will:
- package raw/responses/<timestamp> into bundles/responses_<timestamp>.tar.gz
- write per-file SHA256 checksums to manifests/responses_<timestamp>.sha256
- write bundle SHA256 to manifests/responses_<timestamp>.bundle.sha256
- create a starter manifest at manifests/responses_<timestamp>.md if missing
USAGE
}

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 1
fi

STAMP="$1"
INPUT_DIR="$RAW_DIR/$STAMP"
if [[ ! -d "$INPUT_DIR" ]]; then
  echo "Input directory not found: $INPUT_DIR" >&2
  exit 1
fi

mkdir -p "$BUNDLES_DIR" "$MANIFESTS_DIR"

BUNDLE_NAME="responses_${STAMP}.tar.gz"
BUNDLE_PATH="$BUNDLES_DIR/$BUNDLE_NAME"
RAW_SUMS="$MANIFESTS_DIR/responses_${STAMP}.sha256"
BUNDLE_SUM="$MANIFESTS_DIR/responses_${STAMP}.bundle.sha256"
MANIFEST_MD="$MANIFESTS_DIR/responses_${STAMP}.md"

TMP_SUMS="$(mktemp)"
cleanup() {
  rm -f "$TMP_SUMS"
}
trap cleanup EXIT

find "$INPUT_DIR" -type f | sort | while read -r path; do
  shasum -a 256 "$path"
done > "$TMP_SUMS"
mv "$TMP_SUMS" "$RAW_SUMS"

tar -czf "$BUNDLE_PATH" -C "$RAW_DIR" "$STAMP"
shasum -a 256 "$BUNDLE_PATH" > "$BUNDLE_SUM"

if [[ ! -f "$MANIFEST_MD" ]]; then
  {
    echo "# Response Bundle Manifest: $STAMP"
    echo
    echo "- Bundle name: \`$BUNDLE_NAME\`"
    echo "- Bundle timestamp: \`$STAMP\`"
    echo "- Created on: \`$(date -u +%Y-%m-%dT%H:%M:%SZ)\`"
    echo "- Generator: \`gximagecomputing/local/GenerateTestEUVResponses.pro\`"
    echo "- Source model epoch: \`$STAMP\`"
    echo
    echo "## Bundle Files"
    echo
    echo "- Local archive: \`bundles/$BUNDLE_NAME\`"
    echo "- Raw-file checksums: \`manifests/responses_${STAMP}.sha256\`"
    echo "- Bundle checksum: \`manifests/responses_${STAMP}.bundle.sha256\`"
    echo
    echo "## Raw Response Files"
    echo
    find "$INPUT_DIR" -maxdepth 1 -type f | sort | while read -r path; do
      base="$(basename "$path")"
      echo "- \`$base\`"
    done
    echo
    echo "## Provenance"
    echo
    echo "- Produced from IDL \`LoadEUVresponse.pro\` using the model observation time."
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
