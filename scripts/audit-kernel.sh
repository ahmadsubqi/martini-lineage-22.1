#!/usr/bin/env bash
set -u
SRC="${1:-kernel-src}"
REPORT="kernel-audit-report.txt"
if [[ ! -d "$SRC" || ! -f "$SRC/Makefile" ]]; then
  echo "ERROR: kernel source directory not found or Makefile missing: $SRC" >&2
  exit 2
fi
rm -f "$REPORT"
{
  echo "=== MARTINI KERNEL STATIC AUDIT (ANDROID 17 PREPARATION) ==="
  echo "Source: https://github.com/lumia-msm8974/android_kernel_nokia_msm8974"
  echo "Requested ref: lineage-18.1-martini"
  echo "Audit UTC: $(date -u +%F %T)"
  echo
  echo "=== GIT IDENTITY ==="
  git -C "$SRC" rev-parse HEAD 2>&1 || true
  git -C "$SRC" log -1 --format='%H%n%ad%n%s' --date=iso-strict 2>&1 || true
  echo
  echo "=== KERNEL VERSION ==="
  grep -E '^(VERSION|PATCHLEVEL|SUBLEVEL|EXTRAVERSION)[[:space:]]*=' "$SRC/Makefile" || true
  echo
  echo "=== MARTINI/MSM8974 DEFCONFIGS ==="
  find "$SRC/arch/arm/configs" -type f \( -iname '*martini*' -o -iname '*msm8974*' \) -print 2>/dev/null | sort || true
  echo
  echo "=== CONFIG SIGNALS ==="
  find "$SRC/arch/arm/configs" -type f \( -iname '*martini*' -o -iname '*msm8974*' \) -print0 2>/dev/null | while IFS= read -r -d '' f; do
    echo "--- $f ---"
    grep -E 'CONFIG_(ARM|ARM64|BINDER|ASHMEM|ANDROID|SELINUX|SECURITY|MSM|QCOM|ION|DMA|SMP|HIGHMEM|VMSPLIT|HZ|PREEMPT|MODULES|KALLSYMS|DEBUG_INFO|CFI|LTO)' "$f" || true
  done
  echo
  echo "=== BINDER / ASHMEM REFERENCES (sample capped) ==="
  grep -RInE 'binder|ashmem|ANDROID_BINDER|CONFIG_ANDROID|CONFIG_ASHMEM' "$SRC/drivers" "$SRC/include" "$SRC/arch/arm" --exclude-dir=.git 2>/dev/null | head -n 250 || true
  echo
  echo "=== SELINUX CONFIG / IMPLEMENTATION SIGNALS ==="
  grep -RInE 'CONFIG_SECURITY_SELINUX|security_init|selinux_init|avc_init' "$SRC/security" "$SRC/include/linux" "$SRC/arch/arm" --exclude-dir=.git 2>/dev/null | head -n 180 || true
  echo
  echo "=== BUILD TOOLCHAIN HINTS ==="
  grep -RInE 'CROSS_COMPILE|ARCH[[:space:]]*\?=|gcc[[:space:]]*[0-9]|clang|LLVM' "$SRC/Makefile" "$SRC/README*" "$SRC/Documentation" 2>/dev/null | head -n 150 || true
  echo
  echo "=== BOOT / DEVICE TREE FILES ==="
  find "$SRC/arch/arm/boot" -maxdepth 5 -type f \( -name '*.dts' -o -name '*.dtsi' -o -name 'Makefile' \) 2>/dev/null | grep -Ei 'msm8974|martini|qcom|dtb' | head -n 180 || true
  echo
  echo "=== MSM8974 / MARTINI SOURCE REFERENCES ==="
  grep -RInE 'MSM8974|msm8974|martini' "$SRC/arch/arm/mach-msm" "$SRC/drivers" "$SRC/arch/arm/boot" --exclude-dir=.git 2>/dev/null | head -n 220 || true
  echo
  echo "=== RECENT COMMITS ==="
  git -C "$SRC" log -15 --oneline --decorate 2>&1 || true
  echo
  echo "=== INTERPRETATION ==="
  echo "This report is an inventory, not a compatibility verdict. Linux 3.4.113 is legacy; Android 17 integration requires a separate framework/vendor/kernel compatibility plan and build tests."
} | tee "$REPORT"
