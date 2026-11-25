# Martini Android 15 driver and toolchain audit

## Purpose
This audit is the next gate after the source-only kernel compatibility review. It inspects the legacy MSM8974 kernel, device tree, vendor repository and common device tree, and attempts a limited ARM kernel compile using the Ubuntu 22.04 distribution cross-compiler.

## Repositories and pinned legacy branches
- Kernel: `lumia-msm8974/android_kernel_nokia_msm8974` / `lineage-18.1-martini`
- Device: `lumia-msm8974/android_device_nokia_martini` / `lineage-18.1`
- Vendor: `lumia-msm8974/android_vendor_nokia_martini` / `lineage-18.1`
- Common: `lumia-msm8974/android_device_oppo_msm8974-common` / `lineage-18.1-lumia`

## What it checks
1. Whether the ARM GNU cross-compiler and basic kernel build tools are available.
2. Presence of legacy GPU/KGSL, display/MDP/DSI, camera, audio, battery, charging, regulator, thermal and wakelock source paths.
3. Device-tree HAL declarations and rough vendor blob inventory.
4. Whether the old `lineage_martini_defconfig` can pass configuration and compile smoke-test stages with the runner's distro compiler.

## Interpretation
- A driver path being present does not prove the driver works with Android 15.
- HAL declarations and blob counts are inventory signals, not proof of VINTF, ABI or service compatibility.
- A kernel compile failure with a modern distro compiler may indicate toolchain/source-age friction; it does not by itself prove the kernel is impossible to build with an appropriate historical toolchain.
- A successful kernel compile is not a ROM build and does not prove bootability.
- No partition, boot image, Binder ABI, memfd, or SELinux boot arguments are changed by this audit.

## Safety gate
The workflow is audit-only. Do not flash output from this workflow. Android 15 readiness still requires userspace/HAL integration, full ROM build, boot testing, hardware validation and security review.
