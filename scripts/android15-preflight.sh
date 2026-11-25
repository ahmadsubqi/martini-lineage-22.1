#!/usr/bin/env bash
set -Eeuo pipefail

OUT="${1:-artifacts/android15-preflight}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$OUT"
REPORT="$OUT/PREFLIGHT_REPORT.md"
: > "$REPORT"

log() { printf '%s\n' "$*" | tee -a "$REPORT"; }
section() { log ""; log "## $*"; }

check_branch() {
  local label="$1" repo="$2" branch="$3" sha
  if sha="$(git ls-remote --exit-code "https://github.com/$repo.git" "refs/heads/$branch" | awk 'NR==1 {print $1}')"; then
    log "- PASS: $label — $repo@$branch ($sha)"
  else
    log "- FAIL: $label — branch missing or inaccessible: $repo@$branch"
  fi
}

CLONED_DIR=""
clone_repo() {
  local name="$1" repo="$2" branch="$3" dest="$TMP/$name"
  log ""
  log "### $name — $repo@$branch"
  if ! git clone --quiet --depth=1 --single-branch --branch "$branch" "https://github.com/$repo.git" "$dest" 2>>"$REPORT"; then
    log "- Clone failed; inspect branch/repository availability."
    return 1
  fi
  log "- Commit: $(git -C "$dest" rev-parse HEAD)"
  CLONED_DIR="$dest"
}

log "# Android 15 / LineageOS 22.1 preflight — Nokia Lumia 930 (martini)"
log ""
log "- Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
log "- Scope: source inventory and compatibility signals only; no ROM build or device flashing."
log "- Expected result at this stage: NOT_BUILD_READY until porting and validation are complete."

section "LineageOS 22.1 platform branch"
check_branch "LineageOS manifest" "LineageOS/android" "lineage-22.1"
check_branch "LineageOS build system" "LineageOS/android_build" "lineage-22.1"

section "Legacy martini source branch availability"
check_branch "Device tree" "lumia-msm8974/android_device_nokia_martini" "lineage-18.1"
check_branch "Kernel" "lumia-msm8974/android_kernel_nokia_msm8974" "lineage-18.1-martini"
check_branch "Vendor" "lumia-msm8974/android_vendor_nokia_martini" "lineage-18.1"
check_branch "MSM8974 common" "lumia-msm8974/android_device_oppo_msm8974-common" "lineage-18.1-lumia"

section "Device tree inspection"
if clone_repo device-tree lumia-msm8974/android_device_nokia_martini lineage-18.1; then
  DT="$CLONED_DIR"
  for f in AndroidProducts.mk BoardConfig.mk lineage_martini.mk device.mk rootdir/etc/fstab.martini; do
    if [[ -f "$DT/$f" ]]; then log "- PASS: $f present."; else log "- FAIL: $f missing."; fi
  done
  log ""
  log "#### Architecture and legacy flags"
  grep -nE 'TARGET_ARCH|TARGET_ARCH_VARIANT|TARGET_CPU_ABI|TARGET_USES_64_BIT_BINDER|TARGET_HAS_MEMFD_BACKPORT|BOARD_KERNEL|TARGET_KERNEL_SOURCE|SELINUX|BOARD_RAMDISK_USE_XZ' "$DT/BoardConfig.mk" 2>/dev/null | head -100 | tee -a "$REPORT" || true
  log ""
  log "#### Product and legacy service references"
  grep -RhoE 'PRODUCT_PACKAGES[[:space:]]*\+?=.*|android\.hardware\.[A-Za-z0-9_.-]+@[0-9.]+' "$DT" --include='*.mk' --include='*.rc' 2>/dev/null | head -100 | tee -a "$REPORT" || true
else
  log "- Device tree could not be cloned; detailed inspection skipped."
fi

section "Kernel source inspection"
if clone_repo kernel lumia-msm8974/android_kernel_nokia_msm8974 lineage-18.1-martini; then
  K="$CLONED_DIR"
  log "- Kernel Makefile version: $(grep -m1 -E '^VERSION[[:space:]]*=' "$K/Makefile" 2>/dev/null || echo unknown)."
  if [[ -f "$K/arch/arm/configs/lineage_martini_defconfig" ]]; then
    log "- PASS: ARM defconfig lineage_martini_defconfig present."
  else
    log "- FAIL: expected ARM defconfig missing."
  fi
  grep -nE 'CONFIG_(ANDROID_BINDER_IPC|ANDROID_BINDER_DEVICES|ARM64|SECURITY_SELINUX)=' "$K/arch/arm/configs/lineage_martini_defconfig" 2>/dev/null | head -40 | tee -a "$REPORT" || true
else
  log "- Kernel clone failed; detailed inspection skipped."
fi

section "Vendor and common tree inventory"
if clone_repo vendor lumia-msm8974/android_vendor_nokia_martini lineage-18.1; then
  V="$CLONED_DIR"
  log "- Vendor tree top-level entries: $(find "$V" -mindepth 1 -maxdepth 1 -printf '%f ' | head -c 500)"
  log "- Proprietary file-list candidates:"
  find "$V" -maxdepth 3 -type f \( -name '*.mk' -o -name '*.txt' -o -name '*.xml' \) | sed "s#^$V/##" | head -60 | tee -a "$REPORT" || true
else
  log "- Vendor clone failed."
fi
if clone_repo msm8974-common lumia-msm8974/android_device_oppo_msm8974-common lineage-18.1-lumia; then
  C="$CLONED_DIR"
  log "- Common tree contains $(find "$C" -type f | wc -l) files."
else
  log "- MSM8974 common clone failed."
fi

section "Preliminary blockers"
log "- Legacy device tree, kernel and vendor branches are Android 11-era sources; branch existence does not establish Android 15 compatibility."
log "- Linux 3.4.113 kernel requires a separate Android 15 compatibility and boot-image assessment."
log "- ARM32 userspace, Binder ABI, proprietary blob dependencies, HIDL-to-AIDL expectations, VINTF, SELinux policy and Nokia boot chain remain unvalidated."
log "- Existing legacy fstab is provisional; do not flash or repartition based on this report."
log "- No product makefiles were rewritten and no build was attempted."

section "Decision"
log "**NOT_BUILD_READY** — continue with source-by-source porting. A successful preflight workflow only means this report ran successfully."
