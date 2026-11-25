# Android 15 port audit — Nokia Lumia 930 (martini)

Audit date: 2026-11-25  
Working branch: `android-15-port`  
Target: LineageOS 22.1 / Android 15, `userdebug`, Nokia Lumia 930 RM-1045.

## Result

**Status: NOT Android 15 build-ready.** The successful GitHub Actions job only audited the legacy reference tree. No Android 15 ROM build has been attempted and no flashable image exists.

The upstream device tree currently referenced is LineageOS 18.1. Its README reports LineageOS 18.1 test builds on a real RM-1045, but that does not establish Android 15 compatibility.

## Confirmed source inventory

| Component | Existing upstream ref | Finding |
|---|---|---|
| Device tree | `lumia-msm8974/android_device_nokia_martini:lineage-18.1` | Legacy Android 11 product/device makefiles |
| Kernel | `lumia-msm8974/android_kernel_nokia_msm8974:lineage-18.1-martini` | Linux 3.4.113, old Android kernel interfaces |
| Vendor blobs | `lumia-msm8974/android_vendor_nokia_martini:lineage-18.1` | Proprietary set packaged for the 18.1 tree |
| MSM8974 common device tree | `lumia-msm8974/android_device_oppo_msm8974-common:lineage-18.1-lumia` | Legacy common HAL/configuration dependencies |
| LineageOS platform | `LineageOS/android:lineage-22.1` | Target branch exists; platform existence does not imply device support |

## Verified technical blockers / review items

1. **Kernel age:** the selected kernel Makefile reports Linux 3.4.113. Android 15 integration will require a compatibility assessment of binder, ashmem/memfd, SELinux, seccomp, filesystem, net, and driver interfaces. Do not assume a modern GKI kernel can replace this device-specific boot-chain kernel.
2. **32-bit platform:** the device tree declares ARMv7 / `armeabi-v7a`. Confirm the exact Android 15 / LineageOS 22.1 build-system support for a 32-bit-only product and its vendor userspace before proceeding.
3. **Binder setting:** `BoardConfig.mk` currently sets `TARGET_USES_64_BIT_BINDER := true` while the target CPU/userspace declarations are 32-bit. This is a high-priority consistency check, not a setting to change blindly.
4. **Legacy product makefiles:** the product inherits LineageOS common phone configuration and Android 11-era packages/configuration. Product inheritance, package names, properties and copy paths must be reconciled against 22.1.
5. **VNDK:** `device.mk` explicitly copies a VNDK v29 ARM library. This is an Android 10-era artifact and must not be carried forward without checking the Android 15 linker/VNDK model and exact required ABI.
6. **HIDL / HAL:** the tree lists multiple HIDL 1.0/2.0-era services (GNSS, health, sensors, Wi-Fi, USB, keymaster, lights, vibrator, graphics). Each service must be mapped to the Android 15 interface expectations; do not bulk-upgrade interface versions without matching implementation support.
7. **Vendor availability:** the Nokia vendor repository exposes only a `lineage-18.1` branch. Blob provenance, 32-bit ABI, linker dependencies, service compatibility and firmware versions need an explicit audit.
8. **Common dependencies:** the current local manifest pulls Oppo/MSM8974 common, OnePlus and proprietary Oppo/OnePlus projects from legacy branches. These are not automatically compatible with LineageOS 22.1 and must be minimized or ported.
9. **Boot chain / partitions:** the device uses Nokia UEFI → BootShim → lk1st → zImage+DTB. Image format, load addresses, partition layout and recovery path must be validated independently before any flash attempt.
10. **SELinux:** the reference BoardConfig defaults to permissive for bring-up unless a build variable is set. Keep initial bring-up isolated; enforcing must be enabled only after policy and runtime denials are reviewed.

## Safe porting order

- [ ] Freeze and record the exact upstream commits for device, kernel, vendor and common trees.
- [ ] Audit the LineageOS 22.1 platform requirements and 32-bit-only build support.
- [ ] Build a dependency map; remove unrelated Oppo/OnePlus device-specific inheritance and packages.
- [ ] Port product makefiles and BoardConfig in small reviewable commits.
- [ ] Audit every proprietary ELF for ARM ABI, needed libraries, symbols and service compatibility.
- [ ] Audit kernel compatibility and implement only required backports; preserve Nokia boot-chain requirements.
- [ ] Port init, fstab, VINTF, sepolicy, overlays and HAL services.
- [ ] Run static build/configuration checks before attempting a full build.
- [ ] Only after a successful build, test boot images with a verified recovery route; do not flash blindly.
- [ ] Collect boot logs and SELinux AVC denials; move to enforcing after the hardware path is stable.

## Current manifest policy

`.repo/local_manifests/martini.xml` is retained as a **legacy source inventory only**. Its projects point at LineageOS 18.1-era refs. Do not use it unchanged as the final Android 15 sync manifest. The port branch must replace or split those entries after each dependency has been checked against the 22.1 platform.

## Next implementation task

Create a minimal Android 15 device-tree skeleton and migrate only the product identity, ARMv7 target declarations, verified boot/image parameters and indispensable device-specific components. Keep unported legacy HALs and vendor packages disabled until individually validated.
