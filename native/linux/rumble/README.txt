Linux controller vibration

Both Linux editions use this native evdev extension. linux_keys passes the
selected controller GUID and the game's existing left/right vibration values.
The Vibration preference, controller availability and window focus gate output.
Gameplay events, their timing and Android's vibration backend are unchanged.

Build with an ARM64 Debian 12 development sysroot and Clang/LLD:

  SYSROOT=/path/to/sysroot sh build-rumble.sh libAM2ARMHaptics.so

Copy the result into extensions/AM2RHaptics/ before compiling either Linux
GameMaker project. Include the generated library alongside runner and game.unx
in the installed game's data folder. The library requires the usual C/math
runtime and Linux input headers; it adds no background service.

Only a matching controller with FF_RUMBLE support is used. If several matching
devices cannot be distinguished, no motor is driven. The extension never grabs
input or changes driver settings. Devices without an accessible force-feedback
interface continue without vibration. Unchanged strength is refreshed at most
four times per second, with a 600 ms effect lifetime to bound stalled output.
Zero strength, disabled vibration and lost focus stop and release the effect.

The syscall-boundary regression test runs on a development PC without touching
real input devices:

  cc -Wall -Wextra -Werror -fsanitize=address,undefined -g rumble.c test-rumble.c -Wl,--wrap=glob,--wrap=globfree,--wrap=open,--wrap=close,--wrap=ioctl,--wrap=write,--wrap=clock_gettime -lm -o test-rumble
  ./test-rumble

References:
https://docs.kernel.org/input/ff.html
https://manual.gamemaker.io/beta/en/GameMaker_Language/GML_Reference/Game_Input/GamePad_Input/gamepad_set_vibration.htm

Physical verification: the area-clear earthquake vibrated and stopped correctly
on an RG DS with stock Linux. The same backend compiled for Dual Screen.
Other firmware and controller motors require separate hardware verification.
