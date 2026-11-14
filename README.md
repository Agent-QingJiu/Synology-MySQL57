# Synology MySQL 5.7.44

Native DSM package targeting the confirmed NAS:

- Platform: `bromolow` (`synology_bromolow_3615xs`)
- DSM: `6.2.3-25426`
- Architecture: `x86_64`
- Source: official Oracle MySQL Community Server `5.7.44`
- Package ID: `MySQL`

## Fixed paths

- Package target: `/volume1/@appstore/MySQL`
- Data directory: `/volume1/@appstore/MySQL/Data`
- TCP port: `3306`

This is a native Synology SPK, not a Docker deployment. GitHub Actions uses Synology's DSM 6.2 package toolkit and Bromolow build environment.

## Build

Run **Build DSM 6.2.3 SPK** from Actions, or push a change to `main`. The workflow downloads the official MySQL source, builds it in the DSM 6.2 Bromolow environment, and uploads the SPK as a workflow artifact.

## Validation status

The first CI run is a build/compatibility validation. Do not install an SPK until CI succeeds and the package lifecycle has been tested on the target NAS. MySQL 5.7 is end-of-life; restrict access to port 3306 to trusted clients.

## Data safety

The requested data path is inside the package target. DSM's uninstall behavior for package target directories must be validated before claiming data survives uninstall. The uninstall hook does not intentionally delete database files.