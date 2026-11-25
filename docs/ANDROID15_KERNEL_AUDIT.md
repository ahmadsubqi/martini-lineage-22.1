# Android 15 kernel audit — Nokia Lumia 930 (martini)

## Scope
- Repository: `lumia-msm8974/android_kernel_nokia_msm8974`
- Branch: `lineage-18.1-martini`
- Device: Nokia Lumia 930 / MSM8974 / ARMv7
- Expected source version: Linux 3.4.113

## Initial source findings
The upstream Makefile identifies Linux **3.4.113**. The martini defconfig enables Binder IPC, legacy ashmem, seccomp, SELinux, ION, ext4 and F2FS. It explicitly disables user, PID and UTS namespaces. The Binder 32-bit compatibility option is not enabled; this matches the historical 64-bit Binder board declaration, but does not prove compatibility with LineageOS 22.1.

## Kernel compile and artifact verification (GitHub Actions Run #11)
Run: https://github.com/ahmadsubqi/martini-lineage-22.1/actions/runs/45649914104

The kernel smoke test completed with exit code 0 using GCC 4.9. Artifact `martini-android15-driver-toolchain-audit` (ID `15040655260`) contains `.config`, `System.map`, `zImage`, `zImage-dtb`, the build log and checksum manifest.

| File | Size |
|---|---:|
| `zImage` | 5,579,544 bytes |
| `zImage-dtb` | 5,764,303 bytes |
| `System.map` | 2,191,725 bytes |
| `.config` | 99,509 bytes |

SHA-256:
- `zImage`: `245d7b9b933d6972bc4da2463832ec5e6be62a98d4dc1e1e3f1d267cbdca4046`
- `zImage-dtb`: `e296125122a995b868d140f3e762d2c361ce7b6cfa9dd847a42083f34e0ece7d`
- `System.map`: `0c78b880159042dbcd3a211e2c7c7612014693ad56f00d34cfcb593d71520fb2`

Binary inspection found no FDT magic in `zImage`. In `zImage-dtb`, FDT magic `d00dfeed` starts exactly at offset 5,579,544. Its header declares 184,759 bytes, exactly the remaining appended data. The built config sets:
```
CONFIG_BUILD_ARM_APPENDED_DTB_IMAGE=y
CONFIG_BUILD_ARM_APPENDED_DTB_IMAGE_NAMES="msm8974-v2.2-martini"
```

The corresponding kernel DTS, `arch/arm/boot/dts/msm8974-v2.2-martini.dts`, identifies itself as:
```
model = "Nokia Lumia 930";
compatible = "nokia,martini", "qcom,msm8974";
qcom,msm-id = <126 0x96 0x20002>;
```

## Critical DTB / bootloader matching discrepancy — unresolved
The Lumia boot chain documented by `lumia-msm8974/bandit-installer` is Nokia UEFI → bootmgr → BCD entry "Android (lk1st)" → BootShim → lk1st → Android. Its payload pins the martini lk1st build to `lumia-msm8974/lk2nd` commit `5650648a`.

At that exact lk2nd commit, `lk2nd/device/dts/msm8974/msm8974-nokia-martini.dts` declares:
```
qcom,msm-id = <QCOM_ID_MSM8974 0x10008 0x20002>;
```
The accompanying header defines `QCOM_ID_MSM8974` as 126. Therefore the lk1st DTB's three cells are `<126 0x10008 0x20002>`, while the kernel's appended DTB uses `<126 0x96 0x20002>`. The second cell differs.

This discrepancy is **not resolved** by the successful kernel compile or by finding a valid appended FDT. The kernel DTS comment claims the ID matches lk2nd, but the pinned lk2nd source above shows a different value. The exact selection/validation behavior must be established from the relevant lk1st source/build logic and, ultimately, an actual RM-1045 lk1st log. Do not change either ID based only on this static comparison.

The installer documentation lists the RM-1045 martini `base-7cc` lk1st as verified to reach its on-screen fastboot menu and boot Android/TWRP. This is evidence for the bootloader build, not proof that this new kernel artifact will boot.

## Linker warning
The successful GCC 4.9 build emits ARM linker warnings that unwinding may not work because EXIDX input sections are not in the EXIDX output section. The warning must be assessed for exception unwinding and runtime impact before considering a device boot test.

## Main Android 15 risks
1. Linux 3.4.113 predates Android 15 by many years; missing kernel interfaces and security fixes are likely.
2. Legacy ashmem is present, but modern Android userspace compatibility is unverified.
3. Namespace configuration is incomplete for modern Android expectations.
4. SELinux being compiled in does not prove modern policy compatibility or safe enforcing mode.
5. Binder driver behavior, ioctl ABI, vendor services and Binder expectations remain unvalidated.
6. MSM8974 display, camera, audio, modem, GPU/KGSL, power and thermal drivers have not been validated against Android 15 HAL/VINTF requirements.
7. The appended DTB is structurally verified, but the DTB ID relationship to lk1st is unresolved.
8. Compiler/toolchain compatibility is only demonstrated for this legacy kernel smoke test.

## Decision
**KERNEL_COMPILE_AND_DTB_APPEND_VERIFIED — NOT_ANDROID_15_KERNEL_READY.** The workflow verifies compilation and packaging of the legacy kernel only. It does not establish Android 15 compatibility, correct hardware DTB selection, a full ROM build, or device boot. Do not flash images from this stage.

## Next gate
1. Resolve the lk1st/kernel DTB ID discrepancy using source-level selection logic and real device logs when available.
2. Perform a focused Android 15 namespace and Binder ABI compatibility audit.
3. Inspect the EXIDX linker warning and determine whether a narrowly scoped toolchain/linker correction is needed.
4. Only then plan kernel integration and ROM build work. Keep boot layout, partition settings, Binder flags and SELinux boot arguments unchanged until verified.
