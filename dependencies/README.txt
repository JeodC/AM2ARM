AM2ARM 1.6.3 corresponding runtime sources

These two archives on the AM2ARM v1.6.1 tag supply the unchanged Debian
dependency sources used by the 1.6.3 Linux launcher. Save them once for offline use.

General handheld runtime, Debian sources and packaging:
AM2ARM-1.6.1-dependency-sources.zip
https://github.com/PatchDev-AM2ARM/AM2ARM/releases/download/v1.6.1/AM2ARM-1.6.1-dependency-sources.zip
SHA-256 3e74e3f7b5ed5cd86152f4fa077f0d1c7ea6dd61937af2df34f6b59a435d0a66

Additional app-local glibc and GCC runtime used by the direct-display adapters:
AM2ARM-1.6.1-trimui-brick-dependency-sources.zip
https://github.com/PatchDev-AM2ARM/AM2ARM/releases/download/v1.6.1/AM2ARM-1.6.1-trimui-brick-dependency-sources.zip
SHA-256 21c60b35c086ce9245b73380b62de9bd6bf15e125127addcf4a4814e5149cc33

source-manifest.json and trimui-source-manifest.json identify exact versions,
file sizes, SHA-256 hashes and upstream source locations. The archives contain
the original source packages and corresponding Debian changes, build rules and
copyright notices. Install the recorded build dependencies in a Debian 12 ARM64
development environment. From the extracted source set, run dpkg-source -x on
the .dsc. In the resulting directory use dpkg-buildpackage -us -uc -b.

The ARM64 handheld decoder is Debian xdelta3 3.0.11-dfsg-1.2 (GPL-2+).
The optional desktop xdelta3 3.2.2 and the embedded Android decoder retain
their own notices. See autopatcher/linux/licenses and the Android JNI source.
The game projects and the third-party components have separate licenses.

native/linux contains the modified GL4ES source, the exact patch and pinned
upstream revision, Xwayland build instructions and native extension source.
The distributed runtime retains the library notices alongside the included
components. Obtain the separately licensed GameMaker tools and system firmware
drivers through their respective providers.

Direct display uses Crusty GLX and GL4ES from Westonpack 0.2.7.1, as supplied
in the PortMaster weston_pkg_0.2.squashfs runtime. direct-runtime.json lists
the precise squashfs URL and hash, both ARM64 member paths and their hashes.
Westonpack-LICENSE.txt retains the original notice. Westonpack's upstream
wiki lists publishing Crusty source as pending. The direct adapter's Xvfb
comes from X.Org Xwayland 22.1.9. Its source archive hash and exact Meson
options are in the same index. Firmware supplies the device's SDL/EGL layer.
https://github.com/binarycounter/Westonpack
https://github.com/binarycounter/Westonpack/wiki
https://github.com/PortsMaster/PortMaster-New/releases/tag/2025-07-24_0745
https://www.x.org/releases/individual/xserver/xwayland-22.1.9.tar.xz

The standalone Linux installer uses the Mozilla root certificate bundle from
certifi 2026.11.20 for HTTPS. The bundle and its license are in
native/unified/runtime/certificates.
https://pypi.org/project/certifi/2026.11.20/
