#!/usr/bin/env bash
set -uo pipefail
SRC="${1:-device-src}"
REPORT="martini-device-tree-android15-audit.txt"
if [[ ! -d "$SRC" ]]; then echo "ERROR: missing source: $SRC" >&2; exit 2; fi
: > "$REPORT"
{
  echo "=== LUMIA 930 DEVICE TREE AUDIT — ANDROID 15 TARGET ==="
  echo "Source: https://github.com/lumia-msm8974/android_device_nokia_martini"
  echo "Pinned ref: 0a92a30a194135c5004743717d14c817be3537d6"
  echo "Audit UTC: $(date -u +%F\ %T)"
  echo
  echo "=== SOURCE IDENTITY ==="
  git -C "$SRC" rev-parse HEAD 2>&1 || true
  git -C "$SRC" log -1 --format='%H%n%ad%n%s' --date=iso-strict 2>&1 || true
  echo
  echo "=== REQUIRED DEVICE FILES ==="
  for f in Android.mk AndroidProducts.mk BoardConfig.mk device.mk lineage_martini.mk manifest.xml rootdir configs; do
    if [[ -e "$SRC/$f" ]]; then echo "PASS  $f"; else echo "FAIL  $f"; fi
  done
  echo
  echo "=== TARGET / PLATFORM DECLARATIONS ==="
  grep -nE 'PRODUCT_(NAME|DEVICE|MODEL)|TARGET_BOARD_PLATFORM|TARGET_ARCH|TARGET_CPU_ABI|TARGET_KERNEL_(SOURCE|CONFIG)|TARGET_OTA_ASSERT_DEVICE|BOARD_VENDOR|DEVICE_PATH' "$SRC/BoardConfig.mk" "$SRC/lineage_martini.mk" "$SRC/AndroidProducts.mk" 2>/dev/null || true
  echo
  echo "=== ANDROID RELEASE BASELINE MARKERS ==="
  grep -RInE 'LineageOS 18\.1|LineageOS 22\.1|Android 11|Android 15|lineage-18\.1|lineage-22\.1' "$SRC/README.md" "$SRC/Android.mk" "$SRC/AndroidProducts.mk" "$SRC/lineage_martini.mk" "$SRC/BoardConfig.mk" 2>/dev/null | head -n 160 || true
  echo
  echo "=== LEGACY / MIGRATION RISK MARKERS ==="
  grep -RInE 'target-level="legacy"|TARGET_USES_64_BIT_BINDER|BUILD_BROKEN_|TARGET_HAS_MEMFD_BACKPORT|BOARD_SEPOLICY_DIRS|include device/qcom/sepolicy-legacy|LOCAL_.*:=|PRODUCT_PROPERTY_OVERRIDES' "$SRC/BoardConfig.mk" "$SRC/device.mk" "$SRC/manifest.xml" "$SRC/Android.mk" 2>/dev/null | head -n 240 || true
  echo
  echo "=== DEPENDENCY REFERENCES ==="
  grep -RInE 'device/oppo/msm8974-common|vendor/nokia/martini|kernel/nokia/msm8974|device/qcom/sepolicy-legacy|packages/apps/LumiaParts' "$SRC" --include='*.mk' --include='*.xml' --include='*.md' 2>/dev/null | head -n 180 || true
  echo
  echo "=== PRODUCT AND KERNEL DEFCONFIG ==="
  grep -nE 'lineage_martini|lineage_martini_defconfig|zImage-dtb|BOARD_KERNEL_CMDLINE|TARGET_KERNEL_CONFIG' "$SRC/BoardConfig.mk" "$SRC/lineage_martini.mk" "$SRC/AndroidProducts.mk" 2>/dev/null || true
  echo
  echo "=== DEVICE TREE FILE INVENTORY ==="
  find "$SRC" -maxdepth 3 -type f | sort | sed -n '1,260p'
  echo
  echo "=== AUDIT FINDINGS ==="
  if grep -qiE 'LineageOS 18\.1|lineage-18\.1|Android 11' "$SRC/README.md" "$SRC/BoardConfig.mk" "$SRC/lineage_martini.mk" 2>/dev/null; then
    echo "BLOCKER: upstream device tree documents LineageOS 18.1 / Android 11, not LineageOS 22.1 / Android 15."
  else
    echo "REVIEW: no explicit LineageOS 18.1 / Android 11 marker found; verify the actual manifest baseline."
  fi
  if grep -q 'target-level="legacy"' "$SRC/manifest.xml" 2>/dev/null; then
    echo "RISK: device VINTF manifest declares target-level=legacy; Android 15 compatibility must be validated against current VINTF rules."
  fi
  echo "RISK: legacy HIDL HALs, 32-bit vendor userspace and Linux 3.4 kernel need a compatibility review; this audit does not certify them."
  echo "NOTE: no ROM compilation or phone boot test was performed."
  echo
  echo "=== CONCLUSION ==="
  echo "This is a static inventory only. The current upstream tree is a LineageOS 18.1 baseline; do not treat it as an Android 15-ready tree."
} | tee "$REPORT"
