# martini Android 15 device-tree skeleton

This directory is the new LineageOS 22.1 porting baseline. It is deliberately
minimal and is **not build-ready**.

## Included
- Product discovery: `AndroidProducts.mk`
- Product identity and LineageOS phone inheritance: `lineage_martini.mk`
- Minimal device makefile: `device.mk`
- Conservative board identity, ARMv7 declarations and kernel source/config
  references: `BoardConfig.mk`

## Deliberately not carried forward
- Legacy boot image base, offsets, page size, appended-DTB flags and XZ ramdisk
- Partition sizes, fstab and recovery configuration
- `TARGET_USES_64_BIT_BINDER` and `TARGET_HAS_MEMFD_BACKPORT`
- HIDL service package list, vendor copy rules and legacy Oppo inheritance
- SELinux permissive/enforcing boot arguments
- Legacy overlays, init scripts, properties and proprietary blobs

These values must be validated against the exact LineageOS 22.1 build system,
the Lumia 930 boot chain, the real partition map, and the required vendor
interfaces before being restored.

## Next validation gates
1. Verify product discovery and makefile parsing against the pinned
   LineageOS 22.1 source.
2. Resolve ARM32 userspace and Binder ABI support.
3. Audit kernel 3.4.113 compatibility and toolchain requirements.
4. Port each HAL/VINTF/init dependency and verify matching vendor blobs.
5. Reconstruct boot and partition configuration from verified device data.

No image produced from this skeleton should be flashed.
