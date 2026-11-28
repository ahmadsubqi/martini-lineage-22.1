# Martini Kernel Android 17 Static Audit

This workflow performs an inventory of the Lumia 930 (martini) Linux kernel source at a pinned reference commit. It is diagnostic only and does not prove Android 17 compatibility or a successful ROM boot.

## Run
1. Open the repository's **Actions** tab.
2. Select **Martini Kernel Android 17 Compatibility Audit**.
3. Click **Run workflow** and select the `main` branch.
4. After the run completes, download the `martini-kernel-android17-audit` artifact.

## Source
- Kernel: `lumia-msm8974/android_kernel_nokia_msm8974`
- Ref branch: `lineage-18.1-martini`
- Pinned commit: `75676b8f3f0682b3813144d2f0f04627aa6f2f1c`
- Script: `scripts/audit-kernel.sh`
