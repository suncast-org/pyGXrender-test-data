#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <file> [<file> ...]" >&2
  exit 1
fi

sha256_file() {
  local path="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$path"
    return
  fi
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$path"
    return
  fi
  if command -v openssl >/dev/null 2>&1; then
    local sum
    sum="$(openssl dgst -sha256 "$path" | awk '{print $NF}')"
    printf '%s  %s\n' "$sum" "$path"
    return
  fi
  echo "No SHA-256 tool found (need one of: sha256sum, shasum, openssl)." >&2
  exit 1
}

for path in "$@"; do
  sha256_file "$path"
done
