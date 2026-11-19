#!/usr/bin/env python3
"""Prepare the v1.6.2 checkout catalog for Project Restore Tool 0.3.0."""
import argparse
import json
from pathlib import Path
import shutil
import tempfile
import zipfile

from restore_project import RestoreError, check_file, digest_file, is_redirect, local_path, read_json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
PACK_NAME = 'AM2ARM-Source-Restore-1.6.1.zip'
PACK = {'size': 294100942, 'sha256': 'a5aae1330c3226d0b3945ddae4264b766a91132740b0cb346a5a09fe5c0d6484'}
MEMBERS = ('manifest.json', 'assets.xdelta', 'patcher-assets/manifest.json', 'patcher-assets/assets.xdelta')
PREFIX = 'AM2ARM-Source-Restore/bundle/'


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')


def copy_payloads(pack, destination):
    with zipfile.ZipFile(pack) as archive:
        for name in MEMBERS:
            member = archive.getinfo(PREFIX + name)
            target = destination / name
            target.parent.mkdir(parents=True, exist_ok=True)
            with archive.open(member) as source, target.open('xb') as out:
                shutil.copyfileobj(source, out)
    for folder in (destination, destination / 'patcher-assets'):
        manifest = read_json(folder / 'manifest.json')
        if not check_file(folder / 'assets.xdelta', manifest['patch']):
            raise RestoreError('The extracted delta failed its checksum.')


def make_catalog(destination):
    references = read_json(HERE / 'projects.json')
    catalog = {'schema': 1, 'tool_version': '0.3.0', 'projects': {},
               'bundle_sha256': digest_file(destination / 'manifest.json'),
               'asset_bundles': {'patcher-assets': digest_file(destination / 'patcher-assets/manifest.json')}}
    for name, fingerprint in references['projects'].items():
        manifest_path = local_path(ROOT, name + '/asset-inputs.json')
        if not manifest_path.is_file() or digest_file(manifest_path) != fingerprint:
            raise RestoreError('Expected the original v1.6.2 manifest in ' + name)
        entry = read_json(manifest_path)
        bundle_name = entry.get('bundle_path')
        wanted = catalog['asset_bundles'][bundle_name] if bundle_name else catalog['bundle_sha256']
        if entry['bundle_sha256'] != wanted:
            raise RestoreError('The payload pack does not match the media for ' + name)
        entry.update(manifest_sha256=fingerprint, compatible_releases=[references['snapshot']])
        relative = 'projects/' + fingerprint + '.json'
        target = destination / relative
        write_json(target, entry)
        catalog['projects'][fingerprint] = [
            {'path': relative, 'size': target.stat().st_size, 'sha256': digest_file(target)}]
    write_json(destination / 'catalog.json', catalog)


def same_bundle(staged, output):
    if is_redirect(output) or not output.is_dir():
        return False
    for source in staged.rglob('*'):
        if source.is_file():
            existing = local_path(output, source.relative_to(staged).as_posix())
            if not check_file(existing, {'size': source.stat().st_size, 'sha256': digest_file(source)}):
                return False
    return True


def prepare(pack, output):
    if not check_file(pack, PACK):
        raise RestoreError('Select the original ' + PACK_NAME + ' from the AM2ARM v1.6.1 release.')
    output = output.absolute()
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='.source-restore-', dir=output.parent) as temporary:
        staged = Path(temporary) / 'bundle'
        copy_payloads(pack, staged)
        make_catalog(staged)
        # Publish the complete directory in one rename. An existing bundle is preserved.
        if not output.exists() and not is_redirect(output):
            try:
                staged.rename(output)
                return
            except OSError:
                if not output.exists():
                    raise
        if not same_bundle(staged, output):
            raise RestoreError('This output already contains different files. Choose a fresh --output folder.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('pack', type=Path, help=PACK_NAME + ' downloaded from v1.6.1')
    parser.add_argument('--output', type=Path, default=HERE / 'bundle', help='Prepared bundle directory')
    args = parser.parse_args()
    try:
        prepare(args.pack, args.output)
    except (OSError, ValueError, KeyError, zipfile.BadZipFile, RestoreError) as error:
        parser.exit(1, str(error) + '\n')
    print('Project Restore Tool bundle ready in', args.output)


if __name__ == '__main__':
    main()
