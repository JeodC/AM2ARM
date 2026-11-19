AM2ARM 1.6.2 — Linux Autopatcher source

From the repository root, prepare the restoration bundle using docs/README.md.
Use your original Windows AM2R 1.1 ZIP to restore the interface artwork,
fonts and audio for this patcher:

  python3 restoration/restore_project.py --project autopatcher/linux --zip "/path/to/AM2R_11.zip"
  python3 restoration/restore_project.py --project autopatcher/linux --check

asset-inputs.json lists the editable sources, restorable files and generated
inputs. Build both game editions and use make_patch_data.py with the same
original ZIP to regenerate the patch payloads. Retain your signed Android games
or Linux game archives privately for exact reconstruction checks. Independently
built games can produce different hashes. Generated inputs in the released
patcher can also be checked against the recorded hashes.

The handheld uses Python 3.11, Tk and a bundled ARM64 decoder. Read
RUNNING.txt for the installation layout and desktop-README.txt for the
optional desktop entry point. See native/unified for firmware adapters and
dependencies/README.txt for exact matching runtime sources. The handheld's
Debian xdelta3 3.0.11-dfsg-1.2 and the optional desktop decoder 3.2.2 each
retain their own license. See LICENSE and licenses/.
