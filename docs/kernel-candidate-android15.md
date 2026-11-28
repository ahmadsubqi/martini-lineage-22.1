# Lumia 930 Android 15 kernel candidate assessment

## Current target

- Device: Nokia Lumia 930
- Codename: martini
- SoC: Qualcomm MSM8974
- ROM target: LineageOS 22.1 / Android 15
- Architecture: ARM 32-bit

## Candidate found

Repository: https://github.com/Android4Lumia/android_kernel_nokia_martini

Branch: `lineage-23.1`

Pinned branch head checked: `2bdb4b5d868dbf6b0b0d216e913092e429563820`

The repository is explicitly described as a 3.4 CAF kernel fork with Lumia 930 changes. The branch exists and had a commit on 2026-06-05 titled `fix compilation of wifi driver`.

Inspection confirms:
- Kernel Makefile reports Linux 3.4.113.
- `arch/arm/configs/msm8974_defconfig` exists and sets `CONFIG_ARCH_MSM8974=y`.
- No martini-specific defconfig was found in the initial config-directory inventory.

## Existing device tree baseline

The existing Lumia device tree branch is still `lineage-18.1`. Its BoardConfig uses:
- `TARGET_KERNEL_SOURCE := kernel/nokia/msm8974`
- `TARGET_KERNEL_CONFIG := lineage_martini_defconfig`
- `BOARD_KERNEL_IMAGE_NAME := zImage-dtb`
- ARMv7-A NEON
- `androidboot.selinux=permissive` in the kernel command line

The old vendor tree also only exposes `lineage-18.1` in the branch inventory. These are not Android 15-ready sources.

## Decision

The `lineage-23.1` kernel branch is a promising kernel candidate because it is maintained in an Android 15-era branch and retains MSM8974/Lumia 930 context. It is not yet a validated replacement for the old martini kernel integration.

Do not substitute the generic `msm8974_defconfig` for `lineage_martini_defconfig` without checking all required Lumia hardware options, DTB targets, modules, firmware interfaces, SELinux configuration and boot image format.

## Required next work

1. Compare the candidate branch's MSM8974 defconfig with the old `lineage_martini_defconfig`.
2. Reconstruct a martini-specific defconfig for the candidate branch and compile the kernel alone in GitHub Actions.
3. Port BoardConfig and device makefiles to the LineageOS 22.1 build system.
4. Audit proprietary vendor blobs, HIDL interfaces, init scripts, sepolicy and VINTF.
5. Only then attempt a full ROM build.

## Limits

This is source inspection and branch reachability research. No kernel image or ROM ZIP has been built, flashed or boot-tested by this audit.
