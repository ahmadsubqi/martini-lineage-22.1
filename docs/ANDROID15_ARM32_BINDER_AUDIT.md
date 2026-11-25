# Android 15 ARM32 and Binder source audit

Date: 2026-11-25

## Findings

- LineageOS 22.1 build/make contains `core/combo/TARGET_linux-arm.mk`, and
  `core/combo/select.mk` selects the target combo from `TARGET_OS` and
  `TARGET_ARCH`. Its board parser requires a target architecture and CPU ABI.
  This is evidence that the Android 15 build system still has an ARM32 target
  toolchain path; it is not proof that every Android 15 component or vendor
  dependency can be built for this device.
- The legacy martini board declares `TARGET_ARCH := arm`,
  `TARGET_ARCH_VARIANT := armv7-a-neon`, and
  `TARGET_CPU_ABI := armeabi-v7a`.
- The legacy martini board also sets `TARGET_USES_64_BIT_BINDER := true`.
- The legacy kernel defconfig enables `CONFIG_ANDROID_BINDER_IPC=y` and
  explicitly leaves `CONFIG_ANDROID_BINDER_IPC_32BIT` unset. The kernel
  Kconfig describes that option as the old Android 4.4-and-earlier 32-bit
  Binder API, defaulting to enabled only when `!64BIT`. The old board flag
  and kernel config are therefore consistent with each other; do not change
  either value based only on the device's ARM32 CPU.

## Remaining blockers

This source audit does **not** prove that Linux 3.4.113 Binder behaves correctly
with the exact Android 15 userspace, nor that old vendor blobs and HIDL services
are compatible with LineageOS 22.1. Binder transaction tests, service startup,
VINTF validation, kernel build, and real-device boot remain mandatory.

The ARM32 source path passing is not a declaration that the port is build-ready.
Keep the new device-tree `BoardConfig.mk` minimal until the next compatibility
checks are complete. Do not flash images from this audit.
