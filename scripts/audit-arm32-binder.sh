#!/usr/bin/env bash
set -euo pipefail

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
BASE="https://raw.githubusercontent.com"
BUILD="$TMP/build"
KERNEL="$TMP/kernel"
DEVICE="$TMP/device"
mkdir -p "$BUILD/core/combo" "$KERNEL/drivers/staging/android" "$KERNEL/arch/arm/configs" "$DEVICE"

fetch() {
  local url="$1" out="$2"
  curl -fsSL --retry 3 "$url" -o "$out"
}

fetch "$BASE/LineageOS/android_build/lineage-22.1/core/board_config.mk" "$BUILD/core/board_config.mk"
fetch "$BASE/LineageOS/android_build/lineage-22.1/core/combo/TARGET_linux-arm.mk" "$BUILD/core/combo/TARGET_linux-arm.mk"
fetch "$BASE/LineageOS/android_build/lineage-22.1/core/combo/select.mk" "$BUILD/core/combo/select.mk"
fetch "$BASE/lumia-msm8974/android_kernel_nokia_msm8974/lineage-18.1-martini/drivers/staging/android/Kconfig" "$KERNEL/drivers/staging/android/Kconfig"
fetch "$BASE/lumia-msm8974/android_kernel_nokia_msm8974/lineage-18.1-martini/arch/arm/configs/lineage_martini_defconfig" "$KERNEL/arch/arm/configs/lineage_martini_defconfig"
fetch "$BASE/lumia-msm8974/android_device_nokia_martini/lineage-18.1/BoardConfig.mk" "$DEVICE/BoardConfig.mk"

grep -q 'TARGET_linux-arm.mk' "$BUILD/core/combo/select.mk"
echo "PASS: LineageOS 22.1 has a Linux ARM32 target combo"

grep -q 'TARGET_ARCH := arm' "$DEVICE/BoardConfig.mk"
grep -q 'TARGET_ARCH_VARIANT := armv7-a-neon' "$DEVICE/BoardConfig.mk"
grep -q 'TARGET_CPU_ABI := armeabi-v7a' "$DEVICE/BoardConfig.mk"
grep -q 'TARGET_ARCH := arm' "$TMP/../not-used" 2>/dev/null && true || true
echo "PASS: legacy martini board declares ARMv7 userspace ABI"

grep -q 'config ANDROID_BINDER_IPC_32BIT' "$KERNEL/drivers/staging/android/Kconfig"
grep -q 'default y' "$KERNEL/drivers/staging/android/Kconfig"
grep -q '# CONFIG_ANDROID_BINDER_IPC_32BIT is not set' "$KERNEL/arch/arm/configs/lineage_martini_defconfig"
grep -q 'TARGET_USES_64_BIT_BINDER := true' "$DEVICE/BoardConfig.mk"
grep -q 'CONFIG_ANDROID_BINDER_IPC=y' "$KERNEL/arch/arm/configs/lineage_martini_defconfig"
echo "PASS: legacy board Binder flag and kernel config are internally aligned for the non-legacy Binder ABI"
echo "NOTE: this is source-level evidence only; runtime Binder/vendor compatibility remains unproven"

grep -q 'ifeq ($(TARGET_ARCH)$(TARGET_ARCH_SUITE),)' "$BUILD/core/board_config.mk"
grep -q '$(error Target architectures not defined by board config' "$BUILD/core/board_config.mk"
echo "PASS: Android 15 board parser requires a declared target architecture"

echo "RESULT: ARM32_BINDER_SOURCE_AUDIT_PASS (not a device build or boot test)"
