# Device-tree migration map — martini to LineageOS 22.1

**This is a planning artifact, not a buildable device tree.** Do not add this directory to a sync manifest or invoke lunch/build from it yet.

Target: Nokia Lumia 930 (RM-1045), Qualcomm MSM8974, ARMv7 / Krait, 2 GB RAM, 1080x1920.

## Source files reviewed

Reference: `lumia-msm8974/android_device_nokia_martini`, branch `lineage-18.1`.

| Legacy file | Migration action | Reason / validation |
|---|---|---|
| `AndroidProducts.mk` | Recreate for 22.1 after product makefile is valid | Lunch choice syntax and product registration must match current build rules |
| `lineage_martini.mk` | Rebuild minimally | Re-check common product inheritance and product properties; do not copy `WITH_ADB_INSECURE` blindly |
| `device.mk` | Split into minimal core + optional hardware groups | Legacy package list contains HIDL services, old package names, old paths and common-tree assumptions |
| `BoardConfig.mk` | Re-derive from 22.1 examples and kernel/bootloader evidence | Contains legacy build flags, 32-bit ABI declarations, 64-bit Binder selection, old VNDK and recovery assumptions |
| `rootdir/etc/fstab.martini` | Reconcile with Android 15 fs_mgr and actual partition layout | Current file explicitly calls itself provisional; userdata/cache layout is created inside Windows Data space |
| `manifest.xml` and fragments | Regenerate against actual service implementations | Existing HIDL declarations are not proof that Android 15 can use those vendor services |
| `sepolicy/` | Port policy incrementally | Legacy policy must be compiled and AVC-tested; enforcing is not assumed ready |
| `overlay/` | Review each resource against 22.1 framework | Resource names and config semantics may have changed |
| `rootdir/` init scripts | Audit service triggers, property namespaces, rc syntax and SELinux labels | Android init/property changes and vendor service domains need validation |
| `audio/`, `camera/`, `sensors/`, `ril/`, `nfc/`, `vibrator/` | Keep disabled until each HAL and blob passes ABI/interface checks | These components depend on old Qualcomm userspace and proprietary libraries |

## Critical BoardConfig observations

- The legacy board declares `TARGET_ARCH := arm`, `armv7-a-neon`, `armeabi-v7a`, `armeabi`, and runtime CPU variant `krait`.
- It also sets `TARGET_USES_64_BIT_BINDER := true`. This must be reconciled with the actual Android 15 Binder/kernel/userspace configuration. Do not flip it based only on the ARM32 CPU.
- `TARGET_HAS_MEMFD_BACKPORT := true` is a legacy compatibility marker and must be checked against the target platform's current memfd implementation.
- `BOARD_RAMDISK_USE_XZ := true`, `BOARD_KERNEL_IMAGE_NAME := zImage-dtb`, base address and offsets are boot-chain-sensitive. Preserve only after checking the exact lk1st/BootShim image contract.
- The kernel source is Linux 3.4.113. A successful kernel compile alone will not establish Android 15 runtime compatibility.
- Legacy product copies a VNDK v29 ARM library. Treat as obsolete until a 22.1-specific dependency proves it is needed.
- Legacy build enables permissive SELinux by default unless an environment switch is set. The port must not claim enforcing until policy compiles and a real device boot has no unresolved denials.

## Dependency inventory to validate before syncing

| Project | Legacy ref observed | Required next check |
|---|---|---|
| `android_device_nokia_martini` | `lineage-18.1` | Freeze commit and port device files |
| `android_kernel_nokia_msm8974` | `lineage-18.1-martini` | Freeze commit; enumerate Android 15 kernel compatibility patches |
| `android_vendor_nokia_martini` | `lineage-18.1` | Freeze commit; inventory ELF ABI, DT_NEEDED, symbols, firmware provenance |
| `android_device_oppo_msm8974-common` | `lineage-18.1-lumia` | Identify exact generic pieces needed; remove Oppo-specific product assumptions |
| Qualcomm / OnePlus vendor sources | legacy 18.1-era projects | Determine if each blob/HAL is actually required and legally/source-available |

## Acceptance gates

1. A reproducible source manifest points only to selected 22.1-compatible projects or explicitly documented legacy compatibility forks.
2. Product makefiles parse under the 22.1 build system without missing inheritance, duplicate copy destinations or undefined variables.
3. Board configuration is consistent with 32-bit userspace, Binder ABI, boot image layout and the real bootloader chain.
4. All proprietary binaries have known architecture and dependency closure; no unexplained v29-era copy remains.
5. VINTF declarations match installed service binaries and framework compatibility matrix.
6. Kernel compiles with the selected toolchain and required config, then boots far enough to collect complete logs.
7. SELinux policy builds; enforcing is tested only after permissive bring-up and AVC review.
8. A recovery/rollback method and verified partition map exist before flashing.

## Current state

Only source inspection and documentation have been completed. No Android 15 device-tree makefile, kernel patch, vendor blob conversion, boot image or ROM ZIP has been produced. The next code change should be a minimal product/board port based on verified 22.1 build rules, not a wholesale copy of the legacy tree.
