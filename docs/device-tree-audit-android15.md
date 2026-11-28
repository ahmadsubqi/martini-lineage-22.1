# Martini Device Tree — Android 15 Compatibility Audit

This audit inspects the upstream Lumia 930 device tree at a pinned commit. It is diagnostic only: it does not compile a ROM and does not prove Android 15 compatibility.

## Current baseline finding

The upstream device tree branch is named `lineage-18.1`, and its README identifies the project as LineageOS 18.1. Its build instructions use the LineageOS 18.1 manifest. This is an Android 11-era baseline, not an Android 15 / LineageOS 22.1 tree.

The audit also records legacy VINTF/HIDL declarations, old build variables, kernel integration and external dependencies that require review before porting.

## Run

1. Open the repository's **Actions** tab.
2. Select **Martini Device Tree Android 15 Compatibility Audit**.
3. Click **Run workflow** on the `main` branch.
4. Download the `martini-device-tree-android15-audit` artifact after completion.

## Pinned upstream source

- Repository: `lumia-msm8974/android_device_nokia_martini`
- Branch baseline: `lineage-18.1`
- Pinned commit: `0a92a30a194135c5004743717d14c817be3537d6`
- Kernel reference: `lumia-msm8974/android_kernel_nokia_msm8974`
- Kernel commit: `75676b8f3f0682b3813144d2f0f04627aa6f2f1c`

## Next engineering work

1. Select a valid LineageOS 22.1 manifest and matching common Qualcomm MSM8974 trees.
2. Port product makefiles, BoardConfig, VINTF and sepolicy to the Android 15 build system.
3. Audit proprietary vendor blobs and 32-bit HAL compatibility.
4. Establish a kernel strategy; the Linux 3.4.113 kernel is a major compatibility risk and must not be assumed Android 15-ready.
5. Only after those checks, run a full GitHub Actions build and inspect compiler/linker failures.
