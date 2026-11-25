#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE="$ROOT/device/nokia/martini"
MANIFEST="$ROOT/.repo/local_manifests/martini.xml"
fail=0

check_file() {
  if [[ -s "$1" ]]; then
    echo "PASS: $2"
  else
    echo "FAIL: $2 ($1 missing or empty)"
    fail=1
  fi
}

check_file "$DEVICE/AndroidProducts.mk" "AndroidProducts.mk"
check_file "$DEVICE/lineage_martini.mk" "lineage_martini.mk"
check_file "$DEVICE/device.mk" "device.mk"
check_file "$DEVICE/BoardConfig.mk" "BoardConfig.mk"
check_file "$DEVICE/PORTING_STATUS.md" "porting status"

grep -q 'lineage_martini' "$DEVICE/AndroidProducts.mk" || { echo "FAIL: product discovery entry"; fail=1; }
grep -q 'PRODUCT_DEVICE := martini' "$DEVICE/lineage_martini.mk" || { echo "FAIL: product device identity"; fail=1; }
grep -q 'device/nokia/martini/device.mk' "$DEVICE/lineage_martini.mk" || { echo "FAIL: device makefile inheritance"; fail=1; }
grep -q 'TARGET_ARCH := arm' "$DEVICE/BoardConfig.mk" || { echo "FAIL: ARM target declaration"; fail=1; }
grep -q 'TARGET_KERNEL_CONFIG := lineage_martini_defconfig' "$DEVICE/BoardConfig.mk" || { echo "FAIL: kernel defconfig reference"; fail=1; }

if grep -Eq 'BOARD_KERNEL_BASE|BOARD_MKBOOTIMG_ARGS|BOARD_BOOTIMAGE_PARTITION_SIZE|TARGET_USES_64_BIT_BINDER|TARGET_HAS_MEMFD_BACKPORT|androidboot.selinux' "$DEVICE/BoardConfig.mk"; then
  echo "FAIL: unverified legacy boot/ABI/SELinux setting leaked into minimal BoardConfig"
  fail=1
else
  echo "PASS: unverified boot, partition, Binder and SELinux settings remain excluded"
fi

python3 - "$MANIFEST" <<'PY'
import sys
import xml.etree.ElementTree as ET
root = ET.parse(sys.argv[1]).getroot()
projects = root.findall("project")
device = [p for p in projects if p.get("path") == "device/nokia/martini"]
if len(device) != 1:
    raise SystemExit("FAIL: manifest must contain exactly one martini device project")
p = device[0]
if p.get("name") != "martini-lineage-22.1" or p.get("revision") != "android-15-port":
    raise SystemExit("FAIL: manifest device project does not point to this Android 15 branch")
print("PASS: local manifest XML and Android 15 device project mapping")
PY

if [[ "$fail" -ne 0 ]]; then
  echo "RESULT: SKELETON_CHECK_FAILED"
  exit 1
fi

echo "RESULT: SKELETON_STATIC_CHECKS_PASS (not a ROM build)"
