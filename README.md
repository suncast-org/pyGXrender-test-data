# pyGXrender Test Data

Versioned test-data repository for the `pyGXrender` Python package and related parity workflows.

This repository is intended for:
- developers working on `gxrender`
- reviewers validating releases and pull requests
- parity checks against IDL / GX Simulator / pyAMPP outputs

It is not intended to be installed from PyPI. The Python package distribution remains:
- PyPI distribution: `pyGXrender`
- Python import package: `gxrender`

## Purpose

The main `gximagecomputing` repository should stay lightweight. Large CHR model files, response tables, and other validation artifacts live here instead of in the code repository.

## Repository Layout

```text
pyGXrender-test-data/
  README.md
  .gitignore
  manifests/
  scripts/
  bundles/
  raw/
```

- `manifests/`: checksums, provenance, and per-bundle inventories
- `scripts/`: helper scripts for preparing, verifying, or publishing datasets
- `bundles/`: local staging area for archives that will be uploaded as GitHub Release assets
- `raw/`: optional unpacked working data kept out of Git history by default

## Recommended Usage

1. Clone this repository next to the main `gximagecomputing` repo.
2. Install the default dataset into `raw/` with `scripts/install_dataset.sh`, or generate local bundles with the helper scripts.
3. Point `gxrender` test scripts at the extracted files under `raw/`.

Default installer:

```bash
scripts/install_dataset.sh
```

Custom target root:

```bash
scripts/install_dataset.sh --target-root /path/to/raw
```

The main `gximagecomputing` repository auto-detects fixtures from the sibling path:

```text
../pyGXrender-test-data/raw
```

or from the `GXRENDER_TEST_DATA_ROOT` environment variable.

## Release-Asset Workflow

- Keep manifests, checksums, and helper scripts in normal Git history.
- Stage large archives locally under `bundles/`.
- Publish those archives as GitHub Release assets with `scripts/publish_bundle_release.sh`.
- Record the release tag or asset location in the relevant manifest.

## Versioning Policy

- Tag this repository when publishing a matching `pyGXrender` release test bundle.
- Prefer immutable archives plus manifest files with checksums.
- Record data provenance for every published bundle.

## Data Policy

- Keep only lightweight metadata and helper files in normal Git history.
- Do not commit large binary datasets directly to Git history.
- Prefer GitHub Release assets referenced by tracked manifest files.
