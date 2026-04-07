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

## Fixture Origins

The published bundles originate from upstream tools, but this repository is
intended to be consumable without access to the original local packaging
environment.

### EBTEL tables

The packaged EBTEL tables are also available from the upstream GX Simulator / SolarSoft distribution, typically under:

```text
$SSW/packages/gx_simulator/euv/ebtel/
```

The bundle in this repository is provided for reproducible testing, not because these tables are unique to `pyGXrender`.

### Model fixtures

`test.chr.sav` was produced from an IDL `gx_fov2box` run stored in the SAV metadata.
The exact local output/cache directories are not important for downstream use.

```idl
gx_fov2box, '26-Nov-25 15:47:52', CENTER_ARCSEC=[ -280, -230], DX_KM= 1400, EUV= 1, SIZE_PIX=[ 150, 100, 100], UV= 1, CEA= 1
```

`test.chr.h5` was produced from a Python `gx-fov2box` run stored in the HDF metadata.
Again, the local cache/output directories are environment-specific and omitted here.

```bash
gx-fov2box --time 2025-11-26T15:47:52 --coords -280.0 -230.0 --hpc --cea --box-dims 150 100 100 --dx-km 1400.000000 --pad-frac 0.1000 --euv --uv --save-potential --save-bounds --save-nas --save-gen --save-chr --observer-name earth --stop-after chr
```

These are origin examples only. Re-running them requires a working SSW/IDL GX Simulator or `pyAMPP` environment plus appropriate local data caches.

### Response fixtures

The response bundles were generated in IDL for the test-model epoch using:

- `gximagecomputing/idlcode/LoadEUVresponse.pro`
- `gximagecomputing/local/GenerateTestEUVResponses.pro`

The helper loops over supported instruments and writes date-tagged files such as:

- `resp_aia_20251126T153431.sav`

Those scripts require an SSW/IDL GX Simulator installation with the relevant SolarSoft response routines available. The response generation epoch follows the test-model observation time (`2025-11-26T15:34:31`), not just the original `gx_fov2box` request time.

## Release-Asset Workflow

- Keep manifests, checksums, and helper scripts in normal Git history.
- Stage large archives locally under `bundles/`.
- Publish those archives as GitHub Release assets with `scripts/publish_bundle_release.sh`.
- Record the release tag or asset location in the relevant manifest.

## Versioning Policy

- Tag this repository when publishing a matching `pyGXrender` release test bundle.
- Prefer immutable archives plus manifest files with checksums.
- Record only the minimal fixture-origin information needed to regenerate a published bundle.

## Data Policy

- Keep only lightweight metadata and helper files in normal Git history.
- Do not commit large binary datasets directly to Git history.
- Prefer GitHub Release assets referenced by tracked manifest files.
