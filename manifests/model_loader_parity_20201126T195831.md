# Model Loader Parity Bundle Manifest: 20201126T195831

- Bundle name: `model_loader_parity_20201126T195831.tar.gz`
- Bundle timestamp: `20201126T195831`
- Created on: `2026-04-30T20:58:45Z`
- Source directory: `raw/models/model_loader_parity_20201126T195831`
- Source model epoch: `2020-11-26T19:58:31.300`

## Bundle Files

- Local archive: `bundles/model_loader_parity_20201126T195831.tar.gz`
- Raw-file checksums: `manifests/model_loader_parity_20201126T195831.sha256`
- Bundle checksum: `manifests/model_loader_parity_20201126T195831.bundle.sha256`
- Release tag: `testdata-model-loader-parity-20201126T195831`

## Raw Model Files

- `hmi.M_720s.20201126_195831.E18S19CR.CEA.NAS.CHR.sav`
- `hmi.M_720s.20201126_195831.E18S19CR.CEA.NAS.CHR.clone.h5`

## Provenance

- The SAV source is the IDL-generated CHR model:
  `hmi.M_720s.20201126_195831.E18S19CR.CEA.NAS.CHR.sav`.
- The clone H5 was generated from that SAV with gximagecomputing's
  `gxrender.io.sav_to_h5.build_h5_from_sav` after the SAV/H5 axis-order
  normalization fix.
- The pair is intended for strict loader parity tests, not as the default
  rendering model bundle.
- Publish the archive as a GitHub Release asset rather than committing it to Git history.
