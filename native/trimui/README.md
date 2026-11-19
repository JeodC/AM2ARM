# TrimUI vibration bridge

The native bridge connects the game's haptics extension to the handheld motor for its built-in controller. Other controllers use the evdev backend. The matching Python bridge, input profiles and menu launcher are in [native/unified](../unified/).

Build the shared library on a development host with Clang, LLD and a Debian 12 ARM64 sysroot. Run from this directory.

```sh
SYSROOT=/path/to/sysroot sh native/rumble/build.sh libAM2ARMHaptics.so
python3 -B -m unittest test_rumble_bridge
```

The host check compiles the bridge and exercises vibration, stop and controller selection. The device package keeps the known library hashes in its rumble metadata. Its bridge handles the motor voltage and restores it on exit. See the [NextUI motor implementation](https://github.com/LoveRetro/NextUI/blob/b6ec1343c0a2636ddaf2502fde52cff237c67377/workspace/tg5040/platform/platform.c).
