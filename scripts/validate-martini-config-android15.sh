#!/usr/bin/env bash
set -euo pipefail

KERNEL_DIR="$RUNNER_TEMP/android_kernel_nokia_martini"
BASELINE_DIR="$RUNNER_TEMP/android_kernel_nokia_msm8974"
OUT="$GITHUB_WORKSPACE/martini-device-config-validation-android15.txt"
REPORT="$RUNNER_TEMP/report.txt"

exec > >(tee "$REPORT") 2>&1

echo "=== MARTINI DEVICE CONFIG + ZIMAGE-DTB BUILD ==="
echo "Candidate: Android4Lumia/android_kernel_nokia_martini @ lineage-23.1"
echo "Baseline: lumia-msm8974/android_kernel_nokia_msm8974 @ lineage-18.1-martini"

echo
echo "[1] Clone sources"
git clone --depth=1 --branch lineage-23.1 https://github.com/Android4Lumia/android_kernel_nokia_martini.git "$KERNEL_DIR"
git clone --depth=1 --branch lineage-18.1-martini https://github.com/lumia-msm8974/android_kernel_nokia_msm8974.git "$BASELINE_DIR"

echo
echo "[2] Confirm Martini DTS files"
for f in msm8974-martini.dts msm8974-martini.dtsi msm8974-martini-panel.dtsi msm8974-martini-regulator.dtsi msm8974-martini-touch.dtsi; do
  test -s "$KERNEL_DIR/arch/arm/boot/dts/$f"
  echo "FOUND: $f"
done

# This legacy 3.4 kernel only ships compiler-gcc headers through GCC 5.
# Provide a build-workspace compatibility header for the GCC 11 toolchains
# available on Ubuntu 22.04; do not modify the upstream kernel repository.
for compiler_header in "$KERNEL_DIR/include/linux/compiler-gcc11.h"; do
  if [ ! -s "$compiler_header" ]; then
    cp "$KERNEL_DIR/include/linux/compiler-gcc5.h" "$compiler_header"
  fi
done
echo "HOST_COMPILER_COMPAT_HEADER=compiler-gcc11.h (derived from compiler-gcc5.h)"
grep -nE 'model =|compatible =|msm8974-martini.dtsi' "$KERNEL_DIR/arch/arm/boot/dts/msm8974-martini.dts" || true

echo
echo "[3] Create merged candidate config"
make -C "$KERNEL_DIR" ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- msm8974_defconfig
(
  cd "$KERNEL_DIR"
  scripts/kconfig/merge_config.sh -m .config "$BASELINE_DIR/arch/arm/configs/lineage_martini_defconfig"
)
# Use the DTB basename that actually exists in this candidate source tree.
sed -i 's/^CONFIG_BUILD_ARM_APPENDED_DTB_IMAGE_NAMES=.*/CONFIG_BUILD_ARM_APPENDED_DTB_IMAGE_NAMES="msm8974-martini"/' "$KERNEL_DIR/.config"
make -C "$KERNEL_DIR" ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- olddefconfig

# The Martini baseline intentionally disables PERF_EVENTS. The candidate tree
# otherwise builds its Krait L2 PMU driver unconditionally, although arm_pmu
# declarations are hidden when CONFIG_HW_PERF_EVENTS=n. Keep the baseline
# feature setting and correctly guard these optional objects in the build workspace.
sed -i "s|^obj-\$(CONFIG_ARCH_MSM_KRAIT) += msm-krait-l2-accessors.o perf_event_msm_krait_l2.o$|obj-\$(CONFIG_HW_PERF_EVENTS) += msm-krait-l2-accessors.o perf_event_msm_krait_l2.o|" "$KERNEL_DIR/arch/arm/mach-msm/Makefile"
echo "KRAIT_L2_PMU_OBJECT_GUARD=CONFIG_HW_PERF_EVENTS"

# This legacy MSM PM code calls sched_clock() without a visible prototype
# in the candidate tree's include set. Add the kernel API prototype locally.
MSM_PM_SOURCE="$KERNEL_DIR/arch/arm/mach-msm/msm-pm.c"
if ! grep -q '^extern u64 sched_clock(void);
echo
echo "[4] Resolved device-critical options"
for key in CONFIG_ARCH_MSM8974 CONFIG_OF CONFIG_BUILD_ARM_APPENDED_DTB_IMAGE CONFIG_BUILD_ARM_APPENDED_DTB_IMAGE_NAMES CONFIG_TOUCHSCREEN_SYNAPTICS_I2C_RMI4 CONFIG_PRIMA_WLAN CONFIG_PRONTO_WLAN CONFIG_F2FS_FS CONFIG_EXT4_FS CONFIG_SECURITY_SELINUX CONFIG_MSM_KGSL CONFIG_QPNP_CHARGER CONFIG_QPNP_BMS; do
  value="$(grep -E "^$key=" "$KERNEL_DIR/.config" | head -n1 || true)"
  if [ -z "$value" ] && grep -qE "^# $key is not set$" "$KERNEL_DIR/.config"; then value="$key=n"; fi
  [ -n "$value" ] || value="$key=UNSET"
  echo "$value"
done

echo
echo "[4a] Baseline-critical options after Kconfig resolution"
for key in CONFIG_PRIMA_WLAN CONFIG_PRONTO_WLAN CONFIG_F2FS_FS CONFIG_EXT4_FS; do
  grep -E "^(# )?$key(=| is not set)" "$KERNEL_DIR/.config" || true
done
grep -E '^CONFIG_BUILD_ARM_APPENDED_DTB_IMAGE_NAMES=' "$KERNEL_DIR/.config"

echo
echo "[5] Build Martini DTB"
grep -q '^CONFIG_BUILD_ARM_APPENDED_DTB_IMAGE_NAMES="msm8974-martini"$' "$KERNEL_DIR/.config"
make -C "$KERNEL_DIR" ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j2 msm8974-martini.dtb
test -s "$KERNEL_DIR/arch/arm/boot/msm8974-martini.dtb"
echo "DTB_BUILD=SUCCESS"

echo
echo "[6] Build appended zImage-dtb"
make -C "$KERNEL_DIR" ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j2 zImage-dtb
test -s "$KERNEL_DIR/arch/arm/boot/zImage"
test -s "$KERNEL_DIR/arch/arm/boot/zImage-dtb"

mkdir -p "$GITHUB_WORKSPACE/martini-kernel-output"
cp "$KERNEL_DIR/arch/arm/boot/zImage" "$GITHUB_WORKSPACE/martini-kernel-output/zImage"
cp "$KERNEL_DIR/arch/arm/boot/zImage-dtb" "$GITHUB_WORKSPACE/martini-kernel-output/zImage-dtb"
cp "$KERNEL_DIR/arch/arm/boot/msm8974-martini.dtb" "$GITHUB_WORKSPACE/martini-kernel-output/msm8974-martini.dtb"
cp "$KERNEL_DIR/.config" "$GITHUB_WORKSPACE/martini-merged-kernel.config"

echo "ZIMAGE_DTB_BUILD=SUCCESS"
echo "RESULT=KERNEL_ZIMAGE_DTB_BUILT"
echo "NOTE=Build artifact only. Not flash-tested or boot-tested on Nokia Lumia 930."

cp "$REPORT" "$OUT"
 "$MSM_PM_SOURCE"; then
  sed -i '/^#include <linux\/tick.h>$/a extern u64 sched_clock(void);' "$MSM_PM_SOURCE"
fi
echo "MSM_PM_SCHED_CLOCK_DECLARATION=added"

echo
echo "[4] Resolved device-critical options"
for key in CONFIG_ARCH_MSM8974 CONFIG_OF CONFIG_BUILD_ARM_APPENDED_DTB_IMAGE CONFIG_BUILD_ARM_APPENDED_DTB_IMAGE_NAMES CONFIG_TOUCHSCREEN_SYNAPTICS_I2C_RMI4 CONFIG_PRIMA_WLAN CONFIG_PRONTO_WLAN CONFIG_F2FS_FS CONFIG_EXT4_FS CONFIG_SECURITY_SELINUX CONFIG_MSM_KGSL CONFIG_QPNP_CHARGER CONFIG_QPNP_BMS; do
  value="$(grep -E "^$key=" "$KERNEL_DIR/.config" | head -n1 || true)"
  if [ -z "$value" ] && grep -qE "^# $key is not set$" "$KERNEL_DIR/.config"; then value="$key=n"; fi
  [ -n "$value" ] || value="$key=UNSET"
  echo "$value"
done

echo
echo "[4a] Baseline-critical options after Kconfig resolution"
for key in CONFIG_PRIMA_WLAN CONFIG_PRONTO_WLAN CONFIG_F2FS_FS CONFIG_EXT4_FS; do
  grep -E "^(# )?$key(=| is not set)" "$KERNEL_DIR/.config" || true
done
grep -E '^CONFIG_BUILD_ARM_APPENDED_DTB_IMAGE_NAMES=' "$KERNEL_DIR/.config"

echo
echo "[5] Build Martini DTB"
grep -q '^CONFIG_BUILD_ARM_APPENDED_DTB_IMAGE_NAMES="msm8974-martini"$' "$KERNEL_DIR/.config"
make -C "$KERNEL_DIR" ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j2 msm8974-martini.dtb
test -s "$KERNEL_DIR/arch/arm/boot/msm8974-martini.dtb"
echo "DTB_BUILD=SUCCESS"

echo
echo "[6] Build appended zImage-dtb"
make -C "$KERNEL_DIR" ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j2 zImage-dtb
test -s "$KERNEL_DIR/arch/arm/boot/zImage"
test -s "$KERNEL_DIR/arch/arm/boot/zImage-dtb"

mkdir -p "$GITHUB_WORKSPACE/martini-kernel-output"
cp "$KERNEL_DIR/arch/arm/boot/zImage" "$GITHUB_WORKSPACE/martini-kernel-output/zImage"
cp "$KERNEL_DIR/arch/arm/boot/zImage-dtb" "$GITHUB_WORKSPACE/martini-kernel-output/zImage-dtb"
cp "$KERNEL_DIR/arch/arm/boot/msm8974-martini.dtb" "$GITHUB_WORKSPACE/martini-kernel-output/msm8974-martini.dtb"
cp "$KERNEL_DIR/.config" "$GITHUB_WORKSPACE/martini-merged-kernel.config"

echo "ZIMAGE_DTB_BUILD=SUCCESS"
echo "RESULT=KERNEL_ZIMAGE_DTB_BUILT"
echo "NOTE=Build artifact only. Not flash-tested or boot-tested on Nokia Lumia 930."

cp "$REPORT" "$OUT"
