# Alex-ROM

Platform changes for an Android phone that behaves like a display: when the screen turns on, it opens the home screen instead of the lock screen. The color-matrix change from the [Try Android development](https://source.android.com/docs/setup/start#launch_cuttlefish) guide is included, and Cuttlefish is told to draw that matrix into the framebuffer you see at `https://localhost:8443`.

This repository is not a full Android source tree. Follow the guide to download, build, and launch Cuttlefish, then apply these files on top.

## 1. Get and build Android

On a Linux workstation, follow [Try Android development](https://source.android.com/docs/setup/start) through **Launch Cuttlefish**:

- `repo init --partial-clone -b android-latest-release -u https://android.googlesource.com/platform/manifest`
- `repo sync -c -j8`
- `source build/envsetup.sh`
- `lunch aosp_cf_x86_64_only_phone-aosp_current-userdebug`
- `m`
- Install Cuttlefish host packages as the guide describes, then `launch_cvd --daemon`
- Open `https://localhost:8443`

Use the `adb` built with the tree (`out/host/linux-x86/bin/adb`). Cuttlefish is `0.0.0.0:6520`.

## 2. Apply Alex-ROM

From this repository:

```bash
./apply.sh /path/to/aosp
```

That copies five files into the tree:

| Path | What it does |
| --- | --- |
| `device/google/cuttlefish/vsoc_x86_64_only/phone/aosp_cf.mk` | Sets `ro.lockscreen.disable.default` and `ro.vendor.display.wake_to_home` for this phone |
| `frameworks/base/.../LockPatternUtils.java` | Honors `ro.lockscreen.disable.default` on a device that already booted, so no lock screen is shown when there is no PIN, pattern, or password |
| `frameworks/base/.../PhoneWindowManager.java` | On every display wakeup, starts the home screen when `ro.vendor.display.wake_to_home` is set |
| `frameworks/native/.../SurfaceFlinger.cpp` | The guide's color-matrix edit in `updateColorMatrixLocked()` |
| `device/generic/goldfish/hals/hwc3/Display.cpp` | On virtio-gpu (`ro.hardware.gralloc=minigbm`), do not advertise `SKIP_CLIENT_COLOR_TRANSFORM`, so the matrix is visible in the Cuttlefish stream |

A PIN, pattern, or password still keeps the lock screen.

## 3. Rebuild and update the device

From the AOSP tree, with the same `lunch` target:

```bash
source build/envsetup.sh
lunch aosp_cf_x86_64_only_phone-aosp_current-userdebug
m
```

`aosp_cf.mk` is part of the vendor image, so install the new vendor image (or rebuild and relaunch Cuttlefish) before the two properties take effect. `framework`, `services`, `surfaceflinger`, and `com.android.hardware.graphics.composer.ranchu` must be rebuilt.

`adb sync` on this target stops at `simpleperf_app_runner` with `remote update_capabilities failed: Operation not permitted`. Push the rebuilt binaries instead, then reboot:

```bash
adb -s 0.0.0.0:6520 root
adb -s 0.0.0.0:6520 remount
adb -s 0.0.0.0:6520 push $ANDROID_PRODUCT_OUT/system/framework/framework.jar /system/framework/framework.jar
adb -s 0.0.0.0:6520 push $ANDROID_PRODUCT_OUT/system/framework/services.jar /system/framework/services.jar
adb -s 0.0.0.0:6520 push $ANDROID_PRODUCT_OUT/system/bin/surfaceflinger /system/bin/surfaceflinger
adb -s 0.0.0.0:6520 push $ANDROID_PRODUCT_OUT/vendor/apex/com.android.hardware.graphics.composer.ranchu.apex /vendor/apex/com.android.hardware.graphics.composer.ranchu.apex
adb -s 0.0.0.0:6520 reboot
```

After reboot, turn the Cuttlefish display off and on. The `https://localhost:8443` panel should show the home screen with the color change, not the lock screen.

The same `lunch` target and `m` flow is what the guide uses to program a physical device image; flash that image with the device's fastboot instructions after `m` finishes. The wake-to-home properties are set only on `aosp_cf_x86_64_only_phone`.
