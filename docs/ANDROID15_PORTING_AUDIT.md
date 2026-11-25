# Android 15 porting audit — Nokia Lumia 930 (martini)

## Confirmed target

- ROM base: LineageOS 22.1 / Android 15
- Device: Nokia Lumia 930, codename `martini`
- SoC: Qualcomm MSM8974 / Snapdragon 800
- CPU architecture: ARMv7-A / 32-bit
- Build variant target: `userdebug`

## Findings from the upstream reference

The GitHub Actions audit completed successfully on 2026-11-25. It confirmed that the upstream `lineage-18.1` device tree contains its four primary product files:

- `AndroidProducts.mk`
- `BoardConfig.mk`
- `lineage_martini.mk`
- `device.mk`

The reference tree sets `TARGET_BOARD_PLATFORM := msm8974`, `TARGET_ARCH := arm`, `TARGET_ARCH_VARIANT := armv7-a-neon`, uses `lineage_martini_defconfig`, and points to `kernel/nokia/msm8974`.

This is a source audit only. It is not a successful Android 15 configuration or ROM build.

## Dependency branch audit

The currently published Lumia device dependencies are legacy LineageOS 18.1 branches:

| Project | Required path | Available reference branch |
|---|---|---|
| `android_device_nokia_martini` | `device/nokia/martini` | `lineage-18.1` |
| `android_vendor_nokia_martini` | `vendor/nokia/martini` | `lineage-18.1` |
| `android_kernel_nokia_msm8974` | `kernel/nokia/msm8974` | `lineage-18.1-martini` |
| `android_device_oppo_msm8974-common` | `device/oppo/msm8974-common` | `lineage-18.1-lumia` |
| `android_device_oppo_common` | `device/oppo/common` | `lineage-18.1` |
| `android_packages_apps_LumiaParts` | `packages/apps/LumiaParts` | `lineage-18.1` |

The vendor and kernel repositories also expose only legacy 18.1 branches in the checked repository metadata. No Android 15 branch was confirmed for these device-specific projects.

The local manifest in `.repo/local_manifests/martini.xml` now records the full upstream 18.1 dependency set. It is deliberately marked **reference only**. Do not sync it into a LineageOS 22.1 checkout and assume it is build-ready.

## Android 15 port blockers to resolve

1. Port the device tree makefiles and product configuration to the LineageOS 22.1 build system.
2. Port or validate the MSM8974 common tree and every HAL/service against Android 15 interfaces.
3. Port the proprietary vendor integration and verify 32-bit userspace / binder configuration. Do not change `TARGET_USES_64_BIT_BINDER` by guesswork.
4. Validate the 3.4 kernel build against the Android 15 boot image, module, and driver requirements. The existing `lineage-18.1-martini` branch is a kernel reference, not proof of Android 15 compatibility.
5. Check VINTF manifests, init scripts, sepolicy, fstab, partition layout, and recovery/boot chain.
6. Keep SELinux permissive only for early bring-up; move to enforcing after denials are resolved and tested on-device.

## Next safe milestone

Create an Android 15 compatibility branch for the device tree and perform static makefile / dependency migration first. Then run a product-configuration build test in a suitably provisioned build environment. Do not publish or flash a ROM until the build, boot image, and device-specific partition/boot-chain assumptions have been validated.

## Links

- Device tree: https://github.com/lumia-msm8974/android_device_nokia_martini
- Kernel: https://github.com/lumia-msm8974/android_kernel_nokia_msm8974
- Vendor: https://github.com/lumia-msm8974/android_vendor_nokia_martini
- Legacy manifests: https://github.com/lumia-msm8974/martini-manifests
