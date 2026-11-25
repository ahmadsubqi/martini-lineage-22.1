# Android 15 Compatibility Audit — Nokia Lumia 930 (martini)

Date: 2026-11-25
Target: LineageOS 22.1 / Android 15
Branch: `android-15-port`

## Scope

This is a source-level compatibility review based on the successful preflight inventory and direct inspection of the legacy martini device, kernel, vendor, and MSM8974 common makefiles. It does not claim that the device tree builds, that the kernel boots Android 15, or that the proprietary binaries work.

## Confirmed source facts

- The platform target is LineageOS `lineage-22.1`.
- The martini device source currently declares ARMv7 userspace (`TARGET_ARCH := arm`, `armeabi-v7a`).
- The product inherits `full_base_telephony.mk` and LineageOS `common_full_phone.mk`.
- The board uses a custom Nokia boot layout: `zImage-dtb`, appended DTB, 2 KiB pages, base `0x10000000`, and custom ramdisk/tags offsets. These values are documented as needing on-device confirmation.
- The kernel source is Linux 3.4.113 and has a martini-specific `lineage_martini_defconfig`.
- The device tree currently sets `TARGET_USES_64_BIT_BINDER := true` and `TARGET_HAS_MEMFD_BACKPORT := true`.
- The device and common makefiles still reference multiple HIDL-era HAL packages, including audio 2.0, Bluetooth 1.0, camera provider 2.4, graphics allocator 2.0, composer 2.1, sensors 1.0, USB 1.0, Wi-Fi 1.0 and vibrator 1.0.
- The product uses a device-specific vendor makefile plus generic MSM8974 proprietary blobs. Camera and several hardware stacks depend on legacy proprietary binaries.
- SELinux permissive is currently the default bring-up command line unless `MARTINI_SELINUX_ENFORCING=true` is explicitly selected.

## High-risk compatibility areas

### 1. ARM32 userspace and Binder ABI

Do not change the ARM architecture declarations or Binder setting by guesswork. Verify the Android 15 build-system support for an ARM32-only product and the kernel/userspace Binder ABI combination. In particular, confirm whether the platform build expects 64-bit Binder while all device userspace and proprietary blobs remain 32-bit. Treat this as a build gate.

### 2. Linux 3.4.113 kernel

The kernel predates Android 15 by many years. The presence of Binder, SELinux, cgroups, and other Android options in defconfig is not evidence of compatibility. Audit required kernel interfaces, ashmem/memfd behavior, sync/fence interfaces, namespaces, seccomp, netfilter, filesystem support, and vendor driver dependencies. Do not label it Android 15-compatible until it compiles against the selected toolchain and passes boot/runtime validation.

### 3. HIDL services and vendor interface

The makefiles list many HIDL-era services. Determine which HIDL interfaces and compatibility shims remain available in the exact LineageOS 22.1 source revision, and whether each proprietary blob expects the same interface version. Do not mass-convert HIDL declarations to AIDL: first map each service, implementation, manifest declaration, init service, and blob dependency.

### 4. VINTF and vendor blobs

Compare `manifest.xml`, any fragment manifests, compatibility matrices, service rc files, and the actual vendor binary dependencies. Resolve duplicate or obsolete package declarations only after identifying the implementation and expected interface. Verify every proprietary file is present and has the expected ELF architecture and linked libraries.

### 5. Boot image and partition layout

Keep all partition sizes, fstab entries, kernel load addresses, DTB assumptions, and ramdisk offsets provisional. The Nokia UEFI → BootShim → lk1st chain is device-specific. Do not flash, repartition, or generate a flashable package from these legacy values until the actual phone's bootloader behavior and partition map have been independently confirmed.

### 6. SELinux

Keep bring-up permissive only as a temporary diagnostic configuration. Collect AVC denials from a successful boot, fix policy by service/domain, then test enforcing. Do not advertise enforcing as ready merely because the kernel has `CONFIG_SECURITY_SELINUX=y`.

## Porting sequence

1. Pin the exact LineageOS 22.1 manifest revision and verify the build-system interfaces used by the device tree.
2. Build a minimal product/device skeleton with only identity, architecture, kernel source/config references, and required product inheritance.
3. Validate the ARM32 userspace and Binder ABI decision against the actual platform source.
4. Port BoardConfig variables and boot-image rules; remove obsolete variables only after tracing their consumers.
5. Migrate product packages and HAL declarations service-by-service, preserving only interfaces available in the target platform and required by the blobs.
6. Audit vendor blobs: file inventory, ELF class, dependencies, firmware destinations, and proprietary extraction reproducibility.
7. Reconcile VINTF, init rc files, fstab, properties, and SELinux policy.
8. Attempt a compile-only CI build. Treat compiler errors as migration evidence, not as proof that the device can boot.
9. Only after a successful build, prepare a non-flashing boot test plan for the Nokia boot chain. Never flash or repartition based solely on this audit.

## Current decision

**NOT_BUILD_READY.** The source inventory is complete enough to begin controlled migration, but Android 15 compatibility has not yet been demonstrated. The next implementation task is a minimal Android 15 device skeleton and a separate build-system/ABI validation; do not copy the entire Android 11 product configuration forward unchanged.
