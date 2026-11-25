#!/usr/bin/env bash
set -euo pipefail
KERNEL_REPO="https://github.com/lumia-msm8974/android_kernel_nokia_msm8974.git"
KERNEL_REF="lineage-18.1-martini"
WORK="${RUNNER_TEMP:-/tmp}/martini-kernel-audit"
OUT="${GITHUB_WORKSPACE:-.}/kernel-audit-report"
mkdir -p "$OUT"
rm -rf "$WORK"
git clone --depth 1 --branch "$KERNEL_REF" "$KERNEL_REPO" "$WORK"
DEFCONFIG="$WORK/arch/arm/configs/lineage_martini_defconfig"
version="$(awk -F " = " '/^VERSION =/{v=$2}/^PATCHLEVEL =/{p=$2}/^SUBLEVEL =/{s=$2}END{print v"."p"."s}' "$WORK/Makefile")"
{
 echo "# Martini Linux kernel compatibility audit"
 echo
 echo "- Repository: $KERNEL_REPO"
 echo "- Branch: $KERNEL_REF"
 echo "- Commit: $(git -C "$WORK" rev-parse HEAD)"
 echo "- Kernel version: $version"
 echo
 echo "## Defconfig signals"
 for key in CONFIG_ARCH_MSM8974 CONFIG_MACH_NOKIA_MARTINI CONFIG_ANDROID_BINDER_IPC CONFIG_ANDROID_BINDER_IPC_32BIT CONFIG_ASHMEM CONFIG_SECCOMP CONFIG_SECURITY_SELINUX CONFIG_CGROUPS CONFIG_NAMESPACES CONFIG_USER_NS CONFIG_PID_NS CONFIG_UTS_NS CONFIG_ION CONFIG_F2FS_FS CONFIG_EXT4_FS CONFIG_DM_VERITY; do
  line="$(grep -E "^(# )?${key}(=| is not set)" "$DEFCONFIG" || true)"
  if [ -n "$line" ]; then echo "- $key: $line"; else echo "- $key: not explicitly set"; fi
 done
 echo
 echo "## Findings"
 [ "$version" = "3.4.113" ] && echo "- CONFIRMED: legacy Linux 3.4.113 source."
 grep -q "^CONFIG_ANDROID_BINDER_IPC=y$" "$DEFCONFIG" && echo "- PRESENT: Binder IPC enabled."
 grep -q "^CONFIG_ASHMEM=y$" "$DEFCONFIG" && echo "- PRESENT: legacy ashmem enabled; modern userspace compatibility unverified."
 grep -q "^CONFIG_SECCOMP=y$" "$DEFCONFIG" && echo "- PRESENT: seccomp enabled; feature parity unverified."
 grep -q "^CONFIG_SECURITY_SELINUX=y$" "$DEFCONFIG" && echo "- PRESENT: SELinux enabled in config; policy/enforcing compatibility unverified."
 grep -q "^# CONFIG_USER_NS is not set$" "$DEFCONFIG" && echo "- RISK: user namespaces disabled."
 grep -q "^# CONFIG_PID_NS is not set$" "$DEFCONFIG" && echo "- RISK: PID namespaces disabled."
 echo
 echo "## Decision"
 echo "**NOT_ANDROID_15_KERNEL_READY** — source/config audit only. No kernel build, ROM build, boot test, HAL test, or userspace validation was performed."
} | tee "$OUT/ANDROID15_KERNEL_AUDIT.md"
