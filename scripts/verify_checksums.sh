#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <file> [<file> ...]" >&2
  exit 1
fi

for path in "$@"; do
  shasum -a 256 "$path"
done
