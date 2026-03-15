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
- `scripts/`: helper scripts for preparing, verifying, or fetching datasets
- `bundles/`: release-ready compressed archives for reviewers/developers
- `raw/`: optional unpacked working data kept out of Git history by default

## Recommended Usage

1. Clone this repository next to the main `gximagecomputing` repo.
2. Download or generate a versioned bundle.
3. Unpack into `raw/` or another local working directory.
4. Point `gxrender` test scripts at the unpacked files.

## Versioning Policy

- Tag this repository when publishing a matching `pyGXrender` release test bundle.
- Prefer immutable archives plus manifest files with checksums.
- Record data provenance for every committed bundle.

## Data Policy

- Keep only lightweight metadata and small helper files in normal Git history.
- Avoid committing large binary datasets directly unless there is a strong reason.
- Prefer release assets or compressed bundles referenced by manifest.

## Next Steps

Suggested first additions:
- `manifests/manifest-template.md`
- `scripts/verify_checksums.sh`
- first bundle manifest describing the current CHR test set
