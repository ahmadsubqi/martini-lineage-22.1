# Android 15 kernel audit — Nokia Lumia 930 (martini)

## Scope
- Repository: `lumia-msm8974/android_kernel_nokia_msm8974`
- Branch: `lineage-18.1-martini`
- Device: Nokia Lumia 930 / MSM8974 / ARMv7
- Expected source version: Linux 3.4.113

## Initial source findings
The upstream Makefile identifies Linux **3.4.113**. The martini defconfig enables Binder IPC, legacy ashmem, seccomp, SELinux, ION, ext4 and F2FS. It explicitly disables user, PID and UTS namespaces. The Binder 32-bit compatibility option is not enabled; this matches the historical 64-bit Binder board declaration, but does not prove compatibility with LineageOS 22.1.

## Main Android 15 risks
1. Linux 3.4.113 predates Android 15 by many years; missing kernel interfaces and security fixes are likely.
2. Legacy ashmem is present, but modern Android userspace compatibility is unverified.
3. Namespace configuration is incomplete for modern Android expectations.
4. SELinux being compiled in does not prove modern policy compatibility or safe enforcing mode.
5. Binder driver behavior, ioctl ABI, vendor services and Binder expectations remain unvalidated.
6. MSM8974 display, camera, audio, modem, GPU/KGSL, power and thermal drivers have not been validated against Android 15 HAL/VINTF requirements.
7. Compiler/toolchain compatibility has not been established.

## Decision
**NOT_ANDROID_15_KERNEL_READY.** A successful workflow means only that the report was generated, not that the kernel or ROM builds or boots. Do not flash images from this stage.

## Next gate
Perform a dedicated build-toolchain smoke test and driver/API gap review before attempting a full ROM build. Keep boot layout, partition settings, Binder flags and SELinux boot arguments unchanged until verified.
