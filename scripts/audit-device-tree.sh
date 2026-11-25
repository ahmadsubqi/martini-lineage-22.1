#!/usr/bin/env bash
set -Eeuo pipefail

REPO_URL="https://github.com/lumia-msm8974/android_device_nokia_martini.git"
BRANCH="lineage-18.1"
WORKDIR="${RUNNER_TEMP:-/tmp}/martini-device-tree"

echo "== Nokia Lumia 930 (martini) reference audit =="
echo "Repository: ${REPO_URL}"
echo "Branch: ${BRANCH}"

rm -rf "${WORKDIR}"
git clone --depth=1 --branch "${BRANCH}" "${REPO_URL}" "${WORKDIR}"

cd "${WORKDIR}"
echo
echo "== Commit =="
git log -1 --oneline

echo
echo "== Required device-tree files =="
required=(
  "AndroidProducts.mk"
  "BoardConfig.mk"
  "lineage_martini.mk"
  "device.mk"
)
failed=0
for file in "${required[@]}"; do
  if [[ -f "${file}" ]]; then
    echo "[OK] ${file}"
  else
    echo "[MISSING] ${file}"
    failed=1
  fi
done

echo
echo "== Android / build configuration hints =="
grep -nE 'PRODUCT_DEVICE|PRODUCT_NAME|TARGET_ARCH|TARGET_BOARD_PLATFORM|TARGET_KERNEL_SOURCE|TARGET_KERNEL_CONFIG|androidboot.selinux' \
  AndroidProducts.mk BoardConfig.mk lineage_martini.mk 2>/dev/null || true

echo
echo "== Device tree status =="
echo "This audit only checks the upstream reference tree."
echo "It does NOT prove compatibility with LineageOS 22.1 / Android 15."
echo "The reference branch is lineage-18.1; a real Android 15 port is still required."

if [[ "${failed}" -ne 0 ]]; then
  echo "Audit failed: one or more required files are missing."
  exit 1
fi

echo "Audit completed."
