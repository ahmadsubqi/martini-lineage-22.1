# Minimal BoardConfig for Nokia Lumia 930 (martini).
# Boot image layout, partition sizes, fstab, Binder ABI and legacy flags are
# intentionally omitted until independently verified for Android 15.

TARGET_BOARD_PLATFORM := msm8974
TARGET_BOOTLOADER_BOARD_NAME := MSM8974

TARGET_ARCH := arm
TARGET_ARCH_VARIANT := armv7-a-neon
TARGET_CPU_ABI := armeabi-v7a
TARGET_CPU_ABI2 := armeabi
TARGET_CPU_VARIANT := krait

TARGET_KERNEL_SOURCE := kernel/nokia/msm8974
TARGET_KERNEL_CONFIG := lineage_martini_defconfig
