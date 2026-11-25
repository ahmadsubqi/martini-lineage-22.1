# Minimal LineageOS 22.1 product definition.
# Hardware packages and legacy inheritance are intentionally not included yet.

$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

PRODUCT_NAME := lineage_martini
PRODUCT_DEVICE := martini
PRODUCT_BRAND := Nokia
PRODUCT_MANUFACTURER := Nokia
PRODUCT_MODEL := Lumia 930

PRODUCT_GMS_CLIENTID_BASE := android-nokia
