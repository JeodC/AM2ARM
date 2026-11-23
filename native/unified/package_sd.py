"""Build the standalone SD-card ZIP from the common patcher and both edition manifests."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import stat
import sys
import tempfile
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED

SOURCE = Path(__file__).resolve().parent
sys.path.insert(0, str(SOURCE/'runtime'))
sys.path.insert(0, str(SOURCE/'menus'))
from launch_layout import APP, card_shortcuts

WESTONPACK = {Path('graphics/libGL.so.1'), Path('graphics/libcrusty.so')}

def digest(path):
    with path.open('rb') as handle:
        return hashlib.file_digest(handle,'sha256').hexdigest()

def files(root, exclude=()):
    if not root.is_dir():
        raise ValueError(f'Missing input directory: {root}')
    for file in sorted(root.rglob('*')):
        rel = file.relative_to(root)
        if rel in exclude or '__pycache__' in rel.parts or file.suffix == '.pyc':
            continue
        if file.is_symlink():
            raise ValueError(f'Unexpected linked input {file}')
        if file.is_file():
            if (any(i in {'.git','logs','state'} for i in rel.parts)
                    or file.name.lower() in {'am2r.exe','data.win','game.unx','runner','data.sav','extras.sav'}):
                raise ValueError(f'Unexpected input {file}')
            yield rel, file

def collect(generic, direct, patcher_source, patch_bundle=None, version=None):
    members = {}
    for rel, file in files(generic, {Path('runtime')/name for name in WESTONPACK}):
        if rel.as_posix() == 'README.txt' or rel.parts[0] == 'patch-bundle':
            continue
        prefix = 'AM2ARM' if rel.parts[0] == 'runtime' else 'AM2ARM/patcher'
        if (rel.parts[0] == 'input' and rel.as_posix() != 'input/README.txt'
                or prefix.endswith('/patcher') and file.suffix.lower() == '.zip'):
            raise ValueError(f'Unexpected input in patcher directory: {rel}')
        members[f'{prefix}/{rel}'] = file
    bundle = patch_bundle if patch_bundle is not None else generic/'patch-bundle'
    versions = []
    for edition in ('standard', 'dual'):
        for name in ('assembly.json', 'game_data.xdelta', 'wrapper.bin'):
            file = bundle/edition/name
            if file.is_symlink() or not file.is_file() or not file.stat().st_size:
                raise ValueError(f'Missing or invalid edition input: {file}')
            members[f'AM2ARM/patcher/patch-bundle/{edition}/{name}'] = file
        manifest = json.loads((bundle/edition/'assembly.json').read_text())
        versions.append(manifest.get('version'))
    if (not isinstance(versions[0], str) or not re.fullmatch(r'[0-9]+(?:[.][0-9]+)+', versions[0])
            or versions[1] != versions[0] or (version is not None and version != versions[0])):
        raise ValueError(f'Edition versions must match each other and the requested release: {versions}')
    for rel,file in files(direct/'runtime', WESTONPACK):
        if len(rel.parts) == 1:
            if not (SOURCE/'runtime'/rel).is_file():
                raise ValueError(f'Missing public replacement for {rel}')
            continue
        dst = f'AM2ARM/runtime/{rel}'
        if dst in members and digest(members[dst]) != digest(file):
            if str(rel) != 'bin/xkbcomp':
                raise ValueError(f'Inconsistent shared component: {rel}')
            if digest(members[dst]) != digest(direct/'runtime/bin/xkbcomp.bin'):
                raise ValueError('xkbcomp binary mismatch')
        members[dst] = file
    for rel, file in files(SOURCE/'runtime', WESTONPACK):
        members['AM2ARM/runtime/'+str(rel)] = file
    name = 'vendor/xdelta3/linux-arm64/xdelta3'
    decoder = direct/'patcher'/(name+'.bin')
    generic_decoder = generic/(name+'.bin')
    if not generic_decoder.is_file():
        generic_decoder = members['AM2ARM/patcher/'+name]
    if digest(generic_decoder) != digest(decoder):
        raise ValueError('xdelta decoder mismatch')
    members['AM2ARM/patcher/'+name] = direct/'patcher'/name
    members['AM2ARM/patcher/'+name+'.bin'] = decoder
    members['AM2ARM/patcher/assets/app-icon.png'] = direct/'patcher/assets/app-icon.png'
    members['AM2ARM/launch.sh'] = SOURCE/'launch.sh'
    patcher_code = {'handheld_gui.py': 'handheld_gui.py', 'linux_patcher.py': 'linux_patcher.py',
                    'launch.sh': 'handheld-launch.sh', 'compatibility-check.sh': 'compatibility-check.sh'}
    for destination in members:
        relname = destination.removeprefix('AM2ARM/patcher/')
        if '/' not in relname and relname.endswith('.py'):
            patcher_code[relname] = relname
    for destination, source_name in patcher_code.items():
        file = patcher_source/source_name
        if file.is_symlink() or not file.is_file():
            raise ValueError(f'Missing patcher source: {file}')
        members['AM2ARM/patcher/'+destination] = file
    for required in ['AM2ARM/runtime/bin/Xwayland', 'AM2ARM/runtime/bin/Xvfb', 'AM2ARM/runtime/kms/libGL.so.1']:
        if required not in members:
            raise ValueError(f'Missing handheld runtime component: {required}')
    members['launch.sh'] = SOURCE/'menus/payload.sh'
    return members


def write_archive(path, members):
    if path.exists():
        raise ValueError('Choose a new output path.')
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='.am2arm-zip-', dir=path.parent) as folder:
        partial = Path(folder)/'archive'
        with ZipFile(partial,'x') as target:
            for name,file in sorted(members.items()):
                info=ZipInfo(name,(2000,1,1,0,0,0))
                mode=0o755 if os.access(file,os.X_OK) else 0o644
                info.create_system=3
                info.external_attr=(stat.S_IFREG | mode) << 16
                info.compress_type=ZIP_DEFLATED
                with file.open('rb') as source, target.open(info,'w') as output:
                    shutil.copyfileobj(source,output,1024*1024)
        with ZipFile(partial) as archive:
            if set(archive.namelist()) != set(members) or archive.testzip():
                raise RuntimeError('The completed package does not match the staged files.')
        os.link(partial,path)
    print(json.dumps(dict(file=path.name,bytes=path.stat().st_size,files=len(members),
                          sha256=digest(path))),flush=True)


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('generic',type=Path)
    parser.add_argument('direct',type=Path)
    parser.add_argument('output', type=Path, help='New standalone SD-card ZIP')
    parser.add_argument('--patcher-source', type=Path, default=SOURCE.parent.parent/'autopatcher/linux')
    parser.add_argument('--patch-bundle', type=Path, help='Edition patches, defaulting to generic/patch-bundle')
    parser.add_argument('--version', help='Require this release in both edition manifests')
    args = parser.parse_args()
    if os.path.lexists(args.output):
        parser.error('Choose a new output path.')
    if not (args.patcher_source/'handheld_gui.py').is_file():
        parser.error('Supply the Linux Autopatcher source directory with --patcher-source.')
    with tempfile.TemporaryDirectory() as folder:
        stage=Path(folder)
        payload=collect(args.generic,args.direct,args.patcher_source,args.patch_bundle,args.version)
        modes=stage/'executables.txt'
        modes.write_text(''.join(name+'\n' for name,file in sorted(payload.items())
                                 if name.startswith('AM2ARM/') and os.access(file, os.X_OK)))
        payload['executables.txt']=modes
        for rel, file in files(SOURCE/'menus/dependencies'):
            payload[f'dependencies/{rel}'] = file
        payload['licenses/README.txt'] = SOURCE/'menus/README-licenses.txt'
        card = {APP+'/'+name: file for name,file in payload.items()}
        write_archive(args.output, {**card, **card_shortcuts(stage/'card'),
                                    'AM2ARM-READ-ME.txt': SOURCE/'README-card.txt'})


if __name__ == '__main__':
    main()
