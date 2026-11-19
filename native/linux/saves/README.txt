Linux save transfer

Build the scoped native filesystem helper with a Debian 12 ARM64 sysroot:

  python3 build.py --sysroot /path/to/sysroot --output /path/to/project/extensions/AM2RSaveTransfer/libAM2ARMSaves.so

The launcher supplies AM2ARM_SAVE_DIR for this game's portable save folder.
The in-game folder picker lists directories and imports only the five allowed
save filenames into stages. Existing GML conversion and complete V7 validation
run before applying a selected slot or unlock records. Managed writes reject
symlinks, preserve old files, journal changes and recover interrupted restores.
The GameMaker sandbox remains enabled. Android keeps its existing SAF backend.

Run host regression checks with python3 test_transfer.py. The host C++ compiler
is only used by these checks; build.py produces the ARM64 shared library.
