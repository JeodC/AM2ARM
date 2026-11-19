"""Create one SD-card archive from the two device paths and the shared patch data."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import stat
import sys
import tempfile
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED

SOURCE = Path(__file__).resolve().parent
sys.path.insert(0, str(SOURCE/'runtime'))
from menu_entries import stage_patcher_entries

def digest(path):
    with path.open('rb') as handle:
        return hashlib.file_digest(handle,'sha256').hexdigest()

def files(root):
    for file in sorted(root.rglob('*')):
        if file.is_symlink():
            raise ValueError(f'Unexpected linked input {file}')
        if file.is_file():
            rel = file.relative_to(root)
            if any(i in {'.git','__pycache__','logs','state'} for i in rel.parts) or file.suffix == '.pyc':
                raise ValueError(f'Unexpected input {file}')
            yield rel, file

def collect(generic, direct, menus):
    members = {}
    for rel, file in files(generic):
        if rel.as_posix() == 'README.txt':
            continue
        prefix = 'AM2ARM' if rel.parts[0] == 'runtime' else 'AM2ARM/patcher'
        members[f'{prefix}/{rel}'] = file
    for rel,file in files(direct/'runtime'):
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
    for rel, file in files(SOURCE/'runtime'):
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
    members['README.txt'] = SOURCE/'README-card.txt'
    stage_patcher_entries(menus)
    for rel,file in files(menus):
        members[str(rel)] = file
    for required in ['AM2ARM/runtime/bin/Xwayland', 'AM2ARM/runtime/bin/Xvfb', 'AM2ARM/runtime/kms/libGL.so.1', 'AM2ARM/runtime/graphics/libcrusty.so']:
        if required not in members:
            raise ValueError(f'Missing handheld runtime component: {required}')
    for edition in ['standard','dual']:
        manifest=members[f'AM2ARM/patcher/patch-bundle/{edition}/assembly.json']
        if json.loads(manifest.read_text())['version'] != '1.6.2':
            raise ValueError(f'Unexpected {edition} version')
    return members

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('generic',type=Path)
    parser.add_argument('direct',type=Path)
    parser.add_argument('output',type=Path)
    args=parser.parse_args()
    if args.output.exists():
        raise SystemExit('Choose a new output path.')
    args.output.parent.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory() as temporary:
        members=collect(args.generic,args.direct,Path(temporary))
        partial=args.output.with_suffix('.partial')
        with ZipFile(partial,'x',compression=ZIP_DEFLATED,compresslevel=6) as target:
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
        partial.rename(args.output)
    print(json.dumps(dict(file=args.output.name,bytes=args.output.stat().st_size,files=len(members),sha256=digest(args.output))))

if __name__ == '__main__':
    main()
