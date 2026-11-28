#!/usr/bin/env bash
set -euo pipefail
REPORT="martini-android15-kernel-candidate.txt"
KERNEL_URL="https://github.com/Android4Lumia/android_kernel_nokia_martini.git"
KERNEL_BRANCH="lineage-23.1"
BASE_URL="https://raw.githubusercontent.com/Android4Lumia/android_kernel_nokia_martini/${KERNEL_BRANCH}"
DEVICE_URL="https://github.com/lumia-msm8974/android_device_nokia_martini.git"
VENDOR_URL="https://github.com/lumia-msm8974/android_vendor_nokia_martini.git"

: > "$REPORT"
{
  echo "=== MARTINI ANDROID 15 KERNEL CANDIDATE AUDIT ==="
  echo "UTC: $(date -u +%F\ %T)"
  echo "Candidate: $KERNEL_URL"
  echo "Branch: $KERNEL_BRANCH"
  echo
  if git ls-remote --exit-code "$KERNEL_URL" "refs/heads/$KERNEL_BRANCH" > /tmp/kernel-ref.txt; then
    echo "KERNEL_BRANCH=PASS"
    cat /tmp/kernel-ref.txt
  else
    echo "KERNEL_BRANCH=FAIL"
  fi

  curl -fsSL "$BASE_URL/Makefile" -o /tmp/martini-kernel-Makefile
  VERSION=$(awk -F' = ' '/^VERSION =/{v=$2} /^PATCHLEVEL =/{p=$2} /^SUBLEVEL =/{s=$2} END{print v "." p "." s}' /tmp/martini-kernel-Makefile)
  echo "KERNEL_VERSION=$VERSION"

  curl -fsSL "$BASE_URL/arch/arm/configs/msm8974_defconfig" -o /tmp/msm8974_defconfig
  if grep -q '^CONFIG_ARCH_MSM8974=y' /tmp/msm8974_defconfig; then
    echo "MSM8974_DEFCONFIG=PASS"
  else
    echo "MSM8974_DEFCONFIG=FAIL"
  fi
  echo "MARTINI_SPECIFIC_DEFCONFIG=NOT_FOUND_IN_INITIAL_BRANCH_INVENTORY"
  echo "NOTE: generic msm8974_defconfig is not a substitute for a validated martini config."

  echo
  echo "=== DEVICE TREE AND VENDOR BRANCH STATUS ==="
  if git ls-remote --exit-code "$DEVICE_URL" "refs/heads/lineage-22.1" >/dev/null 2>&1; then
    echo "DEVICE_TREE_LINEAGE_22_1=PASS"
  else
    echo "DEVICE_TREE_LINEAGE_22_1=NOT_FOUND"
  fi
  if git ls-remote --exit-code "$VENDOR_URL" "refs/heads/lineage-22.1" >/dev/null 2>&1; then
    echo "VENDOR_LINEAGE_22_1=PASS"
  else
    echo "VENDOR_LINEAGE_22_1=NOT_FOUND"
  fi

  echo
  echo "=== DECISION ==="
  echo "Kernel branch lineage-23.1 is a promising Android 15-era candidate."
  echo "The branch remains Linux 3.4.113 and generic msm8974_defconfig is not device validation."
  echo "No matching Android 15 device tree/vendor branch has been established by this check."
  echo "Do not switch the build manifest or start a ROM build until board config, defconfig, vendor blobs, HAL and sepolicy are ported and audited."
  echo "No full kernel build, ROM build, flash or hardware boot test was performed."
} | tee "$REPORT"
