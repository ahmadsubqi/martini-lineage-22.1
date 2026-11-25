# Minimal device makefile for the Android 15 bring-up.
# Add overlays, init files, proprietary files and HAL packages only after
# each dependency has been checked against the LineageOS 22.1 source tree.

LOCAL_PATH := device/nokia/martini

PRODUCT_DEVICE := martini
PRODUCT_NAME := lineage_martini
PRODUCT_BRAND := Nokia
PRODUCT_MODEL := Lumia 930

# Intentionally no legacy PRODUCT_PACKAGES or PRODUCT_COPY_FILES here.
