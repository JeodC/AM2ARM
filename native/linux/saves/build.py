"""Build the Linux save extension with the same sysroot as the game."""
from pathlib import Path
import argparse
import subprocess

p = argparse.ArgumentParser()
p.add_argument('--sysroot', type=Path, required=True)
p.add_argument('--output', type=Path, required=True)
args = p.parse_args()
source = Path(__file__).resolve().parent
sysroot = args.sysroot.resolve()
gcc = sysroot / 'usr/lib/gcc/aarch64-linux-gnu/12'
args.output.parent.mkdir(parents=True, exist_ok=True)
subprocess.run(['clang++', '--target=aarch64-linux-gnu', '--sysroot=' + str(sysroot),
    '--gcc-install-dir=' + str(gcc), '-std=c++17', '-O2', '-fPIC', '-shared',
    '-fuse-ld=lld', '-Wall', '-Wextra', '-Werror', '-Wl,-z,defs',
    '-ffile-prefix-map=' + str(source) + '=/am2arm-save-transfer',
    str(source / 'save_transfer.cpp'), '-o', str(args.output)], check=True)
subprocess.run(['llvm-strip', '--strip-unneeded', str(args.output)], check=True)
