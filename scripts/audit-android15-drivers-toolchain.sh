#!/usr/bin/env bash
set -u
ROOT="\${GITHUB_WORKSPACE:-.}"
WORK="\${RUNNER_TEMP:-/tmp}/martini-driver-audit"
OUT="$ROOT/driver-toolchain-audit"
KERNEL_REPO="https://github.com/lumia-msm8974/android_kernel_nokia_msm8974.git"
DEVICE_REPO="https://github.com/lumia-msm8974/android_device_nokia_martini.git"
VENDOR_REPO="https://github.com/lumia-msm8974/android_vendor_nokia_martini.git"
COMMON_REPO="https://github.com/lumia-msm8974/android_device_oppo_msm8974-common.git"
mkdir -p "$OUT"; rm -rf "$WORK"; mkdir -p "$WORK"
clone_repo() {
  local url="$1" ref="$2" dir="$3"
  if git clone --depth 1 --branch "$ref" "$url" "$dir"; then
    echo "CLONE_OK $url $ref $(git -C "$dir" rev-parse HEAD)"
  else
    echo "CLONE_FAILED $url $ref"; return 1
  fi
}
{
  echo "# Martini Android 15 driver and toolchain audit"
  echo
  echo "- Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "- Device: Nokia Lumia 930 / martini / MSM8974 / ARMv7"
  echo "- Target: Android 15 / LineageOS 22.1"
  echo
  echo "## 1. Toolchain availability"
  for tool in arm-linux-gnueabi-gcc arm-linux-gnueabihf-gcc clang make bc bison flex; do
    if command -v "$tool" >/dev/null 2>&1; then
      echo "- $tool: $(command -v "$tool")"
      "$tool" --version 2>/dev/null | head -n 1 || true
    else
      echo "- $tool: NOT_FOUND"
    fi
  done
  echo
  echo "## 2. Legacy source revisions"
} | tee "$OUT/ANDROID15_DRIVER_TOOLCHAIN_AUDIT.md"
clone_repo "$KERNEL_REPO" "lineage-18.1-martini" "$WORK/kernel" >> "$OUT/ANDROID15_DRIVER_TOOLCHAIN_AUDIT.md" 2>&1 || true
clone_repo "$DEVICE_REPO" "lineage-18.1" "$WORK/device" >> "$OUT/ANDROID15_DRIVER_TOOLCHAIN_AUDIT.md" 2>&1 || true
clone_repo "$VENDOR_REPO" "lineage-18.1" "$WORK/vendor" >> "$OUT/ANDROID15_DRIVER_TOOLCHAIN_AUDIT.md" 2>&1 || true
clone_repo "$COMMON_REPO" "lineage-18.1-lumia" "$WORK/common" >> "$OUT/ANDROID15_DRIVER_TOOLCHAIN_AUDIT.md" 2>&1 || true
{
  echo
  echo "## 3. Kernel driver source signals"
  if [ -d "$WORK/kernel" ]; then
    for pattern in kgsl msm_drm mdss mdp dsi panel msm_camera camera_v2 qcom_audio wcd9xxx msm8974-battery qpnp regulator thermal charger wakelock; do
      count="$(find "$WORK/kernel/drivers" "$WORK/kernel/arch/arm/mach-msm" -iname "*$pattern*" 2>/dev/null | wc -l)"
      echo "- $pattern: $count matching source paths"
    done
    echo
    echo "### Kernel configuration signals"
    DEFCONFIG="$WORK/kernel/arch/arm/configs/lineage_martini_defconfig"
    for key in CONFIG_MODULES CONFIG_MODULE_UNLOAD CONFIG_MODVERSIONS CONFIG_PM CONFIG_PM_RUNTIME CONFIG_CPU_FREQ CONFIG_THERMAL CONFIG_MSM_KGSL CONFIG_MSMB_CAMERA CONFIG_SND CONFIG_SND_SOC CONFIG_USB_CONFIGFS CONFIG_ANDROID_LOW_MEMORY_KILLER; do
      line="$(grep -E "^(# )?\${key}(=| is not set)" "$DEFCONFIG" 2>/dev/null || true)"
      [ -n "$line" ] && echo "- $key: $line" || echo "- $key: not explicitly set"
    done
  else
    echo "- Kernel checkout unavailable; source scan skipped."
  fi
  echo
  echo "## 4. Device-tree HAL and proprietary dependency signals"
  for tree in device common; do
    if [ -d "$WORK/$tree" ]; then
      echo "### $tree"
      grep -RhoE 'android\.hardware\.[A-Za-z0-9_.-]+@[0-9.]+' "$WORK/$tree" --include='*.mk' --include='*.xml' --include='*.rc' 2>/dev/null | sort -u | sed 's/^/- /' || true
      echo "- Proprietary file-list entries: $(find "$WORK/$tree" \( -iname '*proprietary*' -o -name 'vendor*.mk' \) 2>/dev/null | wc -l)"
    else
      echo "- $tree checkout unavailable."
    fi
  done
  if [ -d "$WORK/vendor" ]; then
    echo "- Vendor repository tracked files: $(git -C "$WORK/vendor" ls-files | wc -l)"
    echo "- Vendor blob/library candidates: $(git -C "$WORK/vendor" ls-files | grep -E '\.(so|bin|mbn|elf|ta)$' | wc -l)"
  else
    echo "- Vendor checkout unavailable."
  fi
  echo
  echo "## 5. Kernel compile smoke test"
} | tee -a "$OUT/ANDROID15_DRIVER_TOOLCHAIN_AUDIT.md"
if [ -d "$WORK/kernel" ] && command -v arm-linux-gnueabi-gcc >/dev/null 2>&1 && command -v make >/dev/null 2>&1; then
  (
    cd "$WORK/kernel"
    export ARCH=arm
    export CROSS_COMPILE=arm-linux-gnueabi-
    make lineage_martini_defconfig
    make -j2
  ) > "$OUT/kernel-build-smoke.log" 2>&1
  result=$?
  {
    echo "- Result: $([ "$result" -eq 0 ] && echo PASS || echo FAIL) (exit $result)"
    echo "- Compiler: $(arm-linux-gnueabi-gcc --version | head -n 1)"
    echo "- Full output: kernel-build-smoke.log artifact"
    tail -n 35 "$OUT/kernel-build-smoke.log" || true
  } | tee -a "$OUT/ANDROID15_DRIVER_TOOLCHAIN_AUDIT.md"
else
  echo "- Result: NOT_RUN (kernel checkout, cross-compiler, or make unavailable)." | tee -a "$OUT/ANDROID15_DRIVER_TOOLCHAIN_AUDIT.md"
fi
{
  echo
  echo "## 6. Decision"
  echo "**AUDIT_ONLY** — source presence and a legacy-kernel compile smoke test do not establish Android 15 compatibility. No full Android build, device boot, HAL validation, or flashing was performed."
  echo
  echo "Do not change boot layout, partition sizes, Binder ABI, SELinux boot arguments, or flash images based on this report alone."
} | tee -a "$OUT/ANDROID15_DRIVER_TOOLCHAIN_AUDIT.md"
