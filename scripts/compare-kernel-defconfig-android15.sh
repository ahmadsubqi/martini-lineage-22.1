#!/usr/bin/env bash
set -euo pipefail

OUT="martini-kernel-config-compare-android15.txt"
CANDIDATE_URL="https://raw.githubusercontent.com/Android4Lumia/android_kernel_nokia_martini/lineage-23.1/arch/arm/configs/msm8974_defconfig"
BASELINE_URL="https://raw.githubusercontent.com/lumia-msm8974/android_kernel_nokia_msm8974/lineage-18.1-martini/arch/arm/configs/lineage_martini_defconfig"

curl -fsSL "$CANDIDATE_URL" -o /tmp/candidate_defconfig
curl -fsSL "$BASELINE_URL" -o /tmp/martini_defconfig

python3 - <<'PY'
from pathlib import Path
import re

def parse(path):
    result = {}
    for line in Path(path).read_text(errors="replace").splitlines():
        line = line.strip()
        m = re.match(r"(CONFIG_[A-Za-z0-9_]+)=(.*)$", line)
        if m:
            result[m.group(1)] = m.group(2)
        else:
            m = re.match(r"# (CONFIG_[A-Za-z0-9_]+) is not set$", line)
            if m:
                result[m.group(1)] = "n"
    return result

old = parse("/tmp/martini_defconfig")
new = parse("/tmp/candidate_defconfig")
keys = [
    "CONFIG_ARCH_MSM8974",
    "CONFIG_MACH_NOKIA_MARTINI",
    "CONFIG_USE_OF",
    "CONFIG_BUILD_ARM_APPENDED_DTB_IMAGE",
    "CONFIG_BUILD_ARM_APPENDED_DTB_IMAGE_NAMES",
    "CONFIG_FB_SIMPLE",
    "CONFIG_NOKIA_CAMERA_PROBE",
    "CONFIG_TOUCHSCREEN_SYNAPTICS_I2C_RMI4",
    "CONFIG_PRIMA_WLAN",
    "CONFIG_PRONTO_WLAN",
    "CONFIG_ANDROID_BINDER_IPC",
    "CONFIG_ASHMEM",
    "CONFIG_SECURITY_SELINUX",
    "CONFIG_F2FS_FS",
    "CONFIG_EXT4_FS",
    "CONFIG_MSM_KGSL",
    "CONFIG_MSMB_CAMERA",
    "CONFIG_MSM_THERMAL",
    "CONFIG_QPNP_CHARGER",
    "CONFIG_QPNP_BMS",
]
lines = [
    "=== MARTINI KERNEL DEFCONFIG COMPARISON ===",
    "Candidate: Android4Lumia/android_kernel_nokia_martini @ lineage-23.1",
    "Candidate config: arch/arm/configs/msm8974_defconfig",
    "Baseline: lumia-msm8974/android_kernel_nokia_msm8974 @ lineage-18.1-martini",
    "Baseline config: arch/arm/configs/lineage_martini_defconfig",
    "",
    f"Baseline entries: {len(old)}",
    f"Candidate entries: {len(new)}",
    "",
    "=== DEVICE-CRITICAL CONFIG CHECK ===",
]
for key in keys:
    a, b = old.get(key, "ABSENT"), new.get(key, "ABSENT")
    status = "MATCH" if a == b else ("CANDIDATE_MISSING" if b == "ABSENT" or b == "n" else "DIFF")
    lines.append(f"{key}: baseline={a} candidate={b} status={status}")

missing_device = [k for k in ("CONFIG_MACH_NOKIA_MARTINI", "CONFIG_BUILD_ARM_APPENDED_DTB_IMAGE_NAMES") if new.get(k, "ABSENT") in ("ABSENT", "n")]
lines += [
    "",
    "=== AUTOMATED ASSESSMENT ===",
    "Candidate branch provides only generic msm8974 configs in arch/arm/configs; no martini/nokia-named defconfig was found.",
    "The baseline enables MACH_NOKIA_MARTINI and appends the msm8974-v2.2-martini DTB.",
    f"Missing critical Martini selectors in candidate generic config: {', '.join(missing_device) if missing_device else 'none detected'}",
    "DECISION=DO_NOT_USE_GENERIC_DEFCONFIG_FOR_DEVICE_BUILD",
    "A Martini-specific defconfig must be ported/reconstructed against candidate kernel Kconfig and validated before compiling a flashable image.",
    "This is a static config comparison only; no kernel build, flash, or device boot test was performed.",
]
Path("martini-kernel-config-compare-android15.txt").write_text("\n".join(lines) + "\n")
print("\n".join(lines))
PY
