#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLES_DIR="$ROOT_DIR/bundles"
MANIFESTS_DIR="$ROOT_DIR/manifests"
SOURCE_DIR="${GXRENDER_EBTEL_SOURCE_DIR:-${SSW:-}/packages/gx_simulator/euv/ebtel}"
LABEL="${1:-gxsimulator_euv}"

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

if [[ -z "$SOURCE_DIR" || ! -d "$SOURCE_DIR" ]]; then
  echo "EBTEL source directory not found: ${SOURCE_DIR:-<unset>}" >&2
  echo "Hint: set GXRENDER_EBTEL_SOURCE_DIR or SSW before running this script." >&2
  exit 1
fi

mkdir -p "$BUNDLES_DIR" "$MANIFESTS_DIR"

BUNDLE_NAME="ebtel_${LABEL}.tar.gz"
BUNDLE_PATH="$BUNDLES_DIR/$BUNDLE_NAME"
RAW_SUMS="$MANIFESTS_DIR/ebtel_${LABEL}.sha256"
BUNDLE_SUM="$MANIFESTS_DIR/ebtel_${LABEL}.bundle.sha256"
MANIFEST_MD="$MANIFESTS_DIR/ebtel_${LABEL}.md"

FILES=()
while IFS= read -r path; do
  FILES+=("$path")
done < <(find "$SOURCE_DIR" -maxdepth 1 -type f -name '*.sav' | sort)

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "No EBTEL .sav files found under $SOURCE_DIR" >&2
  exit 1
fi

TMP_ROOT="$(mktemp -d)"
TMP_SUMS="$(mktemp)"
cleanup() {
  rm -rf "$TMP_ROOT"
  rm -f "$TMP_SUMS"
}
trap cleanup EXIT

TMP_DIR="$TMP_ROOT/ebtel_${LABEL}"
mkdir -p "$TMP_DIR"

> "$TMP_SUMS"
for src in "${FILES[@]}"; do
  base="$(basename "$src")"
  cp "$src" "$TMP_DIR/$base"
  printf '%s  %s\n' "$(sha256_file "$src")" "$src" >> "$TMP_SUMS"
done
mv "$TMP_SUMS" "$RAW_SUMS"

tar -czf "$BUNDLE_PATH" -C "$TMP_ROOT" "ebtel_${LABEL}"
printf '%s  %s\n' "$(sha256_file "$BUNDLE_PATH")" "$BUNDLE_PATH" > "$BUNDLE_SUM"

if [[ ! -f "$MANIFEST_MD" ]]; then
  {
    echo "# EBTEL Bundle Manifest: $LABEL"
    echo
    echo "- Bundle name: \`$BUNDLE_NAME\`"
    echo "- Bundle label: \`$LABEL\`"
    echo "- Created on: \`$(date -u +%Y-%m-%dT%H:%M:%SZ)\`"
    echo "- Source directory: \`$SOURCE_DIR\`"
    echo
    echo "## Bundle Files"
    echo
    echo "- Local archive: \`bundles/$BUNDLE_NAME\`"
    echo "- Raw-file checksums: \`manifests/ebtel_${LABEL}.sha256\`"
    echo "- Bundle checksum: \`manifests/ebtel_${LABEL}.bundle.sha256\`"
    echo
    echo "## Raw EBTEL Files"
    echo
    for src in "${FILES[@]}"; do
      echo "- \`$(basename "$src")\`"
    done
    echo
    echo "## Provenance"
    echo
    echo "- These files were copied from the SolarSoft gx_simulator EBTEL table directory referenced by \`GXRENDER_EBTEL_SOURCE_DIR\` (or \`\$SSW/packages/gx_simulator/euv/ebtel\` if \`SSW\` is set)."
    echo "- The bundle preserves all currently available .sav tables under \`gx_simulator/euv/ebtel\`."
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
