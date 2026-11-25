# Nokia Lumia 930 (martini) — LineageOS 22.1 bring-up

Target device: **Nokia Lumia 930 (martini / MSM8974 / ARMv7)**  
Intended ROM: **LineageOS 22.1 (Android 15), userdebug**

This repository is the project workspace for auditing and preparing the
existing Lumia 930 device tree for a future Android 15 port.

## Important status

The upstream reference is
[`lumia-msm8974/android_device_nokia_martini`](https://github.com/lumia-msm8974/android_device_nokia_martini),
branch `lineage-18.1`.

That tree is a legacy Android 11 / LineageOS 18.1 base. It must **not** be
treated as an Android 15-ready device tree. This repository currently contains
only the initial manifest and an automated reference audit; it does not yet
build a ROM or produce a flashable ZIP.

## Project layout

- `.repo/local_manifests/martini.xml` — initial repo manifest entry for the
  upstream reference tree.
- `scripts/audit-device-tree.sh` — checks out and audits required upstream
  device-tree files.
- `.github/workflows/audit.yml` — runs the audit in GitHub Actions.

## Run the audit

1. Open the **Actions** tab.
2. Select **Martini device tree audit**.
3. Select **Run workflow**.
4. Open the run and inspect the **Audit upstream Lumia 930 tree** job log.

The workflow is an audit only. Standard GitHub-hosted runners are not assumed
to have enough disk space, RAM, or runtime for a complete Android ROM build.

## Latest audit

See [`docs/ANDROID15_PORT_AUDIT.md`](docs/ANDROID15_PORT_AUDIT.md) for the verified source inventory, compatibility blockers and safe porting order. The current result is **not build-ready**.

## Planned Android 15 port stages

1. Audit the complete device tree, kernel source, vendor blobs, firmware and
   boot chain.
2. Identify Android 15 / LineageOS 22.1 framework and build-system changes.
3. Port product makefiles, BoardConfig, device configuration, init scripts,
   overlays, sepolicy and HAL integration.
4. Confirm a compatible MSM8974 kernel and required legacy interfaces.
5. Validate proprietary blobs and their dependency/API compatibility.
6. Build boot/vendor/system images in a suitably provisioned build environment.
7. Test boot, display, touch, radio, Wi-Fi, Bluetooth, audio, camera, sensors,
   storage, charging and recovery on real hardware.
8. Move SELinux from bring-up permissive mode to enforcing only after policy
   denials have been reviewed and hardware functions have been tested.

## Device facts

- SoC: Qualcomm MSM8974 / Snapdragon 800
- CPU: ARMv7 (32-bit)
- GPU: Adreno 330
- Display: 1080 × 1920 AMOLED
- Device codename: `martini`

## Safety

Do not flash experimental images until the boot chain, partition layout,
firmware compatibility and recovery path have been verified for the exact
Lumia 930 variant. Keep a recoverable backup of the original device state.
