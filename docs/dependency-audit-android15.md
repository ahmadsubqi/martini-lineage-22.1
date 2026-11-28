# Martini Android 15 dependency audit

This workflow checks whether every repository and revision referenced by the current local manifest is reachable on GitHub.

## Current manifest status

`.repo/local_manifests/martini.xml` is explicitly a **reference manifest**. It points to legacy LineageOS 18.1 branches, including the device tree, vendor tree, Linux 3.4 kernel, MSM8974 common tree and LumiaParts. It must not be treated as a ready-to-sync LineageOS 22.1 manifest.

## Automated audit

The workflow runs on pushes that change the manifest, audit script, or workflow, and can also be started manually from GitHub Actions. It uploads `martini-android15-dependency-audit`.

The report verifies remote URL and branch/tag reachability. A PASS means only that the revision exists; it does not mean the source is compatible with Android 15.

## Required next step

After collecting the report, build a separate Android 15 manifest using only repositories whose branches and source contents have been inspected for LineageOS 22.1 compatibility. Do not overwrite the reference manifest until that candidate is validated.
