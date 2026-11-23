AM2ARM 1.6.3 — ARM64 Linux Dual Screen

This GameMaker project contains the release code and resource definitions.
asset-inputs.json lists the original artwork, music, fonts and included data
needed to open and build AM2RDualLinux.yyp.

From the repository root, follow docs/README.md to prepare the restoration
bundle once. Use your original Windows AM2R 1.1 ZIP with this project:

  python3 restoration/restore_project.py --project game/linux/dual-screen --zip "/path/to/AM2R_11.zip"
  python3 restoration/restore_project.py --project game/linux/dual-screen --check

Open AM2RDualLinux.yyp after restoring its media. See BUILDING.txt for the
toolchain, SOURCE-MAP.txt for project organization and CODE-STYLE.txt for
conventions. LICENSE.txt and THIRD-PARTY.txt preserve the game-source terms.
Keep restored media and complete game builds private.
