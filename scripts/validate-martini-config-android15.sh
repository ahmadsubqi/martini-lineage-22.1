#!/usr/bin/env bash
set -euo pipefail

KERNEL_DIR="$RUNNER_TEMP/android_kernel_nokia_martini"
BASELINE_DIR="$RUNNER_TEMP/android_kernel_nokia_msm8974"
OUT="$GITHUB_WORKSPACE/martini-device-config-validation-android15.txt"
REPORT="$RUNNER_TEMP/report.txt"

{
  echo "=== MARTINI DEVICE CONFIG VALIDATION ==="
  echo "Candidate: Android4Lumia/android_kernel_nokia_martini @ lineage-23.1"
  echo "Baseline: lumia-msm8974/android_kernel_nokia_msm8974 @ lineage-18.1-martini"
  echo

  echo "[1] Clone sources"
  git clone --depth=1 --branch lineage-23.1 https://github.com/Android4Lumia/android_kernel_nokia_martini.git "$KERNEL_DIR"
  git clone --depth=1 --branch lineage-18.1-martini https://github.com/lumia-msm8974/android_kernel_nokia_msm8974.git "$BASELINE_DIR"

  echo
  echo "[2] Confirm Martini DTS files and references"
  for f in msm8974-martini.dts msm8974-martini.dtsi msm8974-martini-panel.dtsi msm8974-martini-regulator.dtsi msm8974-martini-touch.dtsi; do
    test -s "$KERNEL_DIR/arch/arm/boot/dts/$f"
    echo "FOUND: $f"
  done
  grep -nE 'model =|compatible =|msm8974-martini.dtsi' "$KERNEL_DIR/arch/arm/boot/dts/msm8974-martini.dts" || true

  echo
  echo "[3] Create merged candidate config"
  make -C "$KERNEL_DIR" ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- msm8974_defconfig
  ( cd "$KERNEL_DIR" && scripts/kconfig/merge_config.sh -m .config "$BASELINE_DIR/arch/arm/configs/lineage_martini_defconfig" )
  make -C "$KERNEL_DIR" ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- olddefconfig

  echo
  echo "[4] Resolved device-critical options"
  for key in CONFIG_ARCH_MSM8974 CONFIG_OF CONFIG_BUILD_ARM_APPENDED_DTB_IMAGE CONFIG_BUILD_ARM_APPENDED_DTB_IMAGE_NAMES CONFIG_TOUCHSCREEN_SYNAPTICS_I2C_RMI4 CONFIG_PRIMA_WLAN CONFIG_PRONTO_WLAN CONFIG_F2FS_FS CONFIG_EXT4_FS CONFIG_SECURITY_SELINUX CONFIG_MSM_KGSL CONFIG_QPNP_CHARGER CONFIG_QPNP_BMS; do
    value="$(grep -E "^$key=" "$KERNEL_DIR/.config" | head -n1 || true)"
    if [ -z "$value" ] && grep -qE "^# $key is not set$" "$KERNEL_DIR/.config"; then value="$key=n"; fi
    [ -n "$value" ] || value="$key=UNSET"
    echo "$value"
  done
  echo
  echo "[4a] Check baseline-critical options after Kconfig resolution"
  for key in CONFIG_PRIMA_WLAN CONFIG_PRONTO_WLAN CONFIG_F2FS_FS CONFIG_EXT4_FS CONFIG_BUILD_ARM_APPENDED_DTB_IMAGE_NAMES; do
    grep -E "^(# )?$key(=| is not set)" "$KERNEL_DIR/.config" || true
  done
  if grep -q 'config MACH_NOKIA_MARTINI' "$KERNEL_DIR/arch/arm/mach-msm/Kconfig"; then
    echo "CONFIG_MACH_NOKIA_MARTINI=SUPPORTED_BY_CANDIDATE_KCONFIG"
  else
    echo "CONFIG_MACH_NOKIA_MARTINI=NOT_IN_CANDIDATE_KCONFIG (candidate uses DT-based board description; legacy symbol is not expected)"
  fi

  echo
  echo "[5] Verify DTB build"
  # Build this board DTB through the legacy ARM pattern rule. The aggregate
  # dtbs target in this candidate expands a path already prefixed with
  # arch/arm/boot, causing the parent rule to prepend that path twice.
  make -C "$KERNEL_DIR" ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j2 msm8974-martini.dtb
  test -s "$KERNEL_DIR/arch/arm/boot/msm8974-martini.dtb"
  echo "DTB_BUILD=SUCCESS"
  cp "$KERNEL_DIR/.config" "$GITHUB_WORKSPACE/martini-merged-kernel.config"
  echo
  echo "RESULT=DEVICE_TREE_AND_MERGED_CONFIG_VALIDATED"
  echo "NOTE=This validates config resolution and DTB compilation only. It does not yet build zImage, flash, or boot-test the device."
} 2>&1 | tee "$REPORT"

cp "$REPORT" "$OUT"
