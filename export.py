# requires:
# python libs: sh, click
# git
# godot
# wine + rcedit

from sh import git
from sh import godot
from sh import wine
import click

from pathlib import Path
from shutil import copyfile, make_archive
from zipfile import ZipFile

game_name = ['HexaMaze']
platforms = [('HTML5', 'html5'), ('Windows Desktop', 'windows'), ('Linux/X11', 'linux')]

rc_edit = '/home/jas/bin/rcedit-x64.exe'
copyright_text = 'Copyright Jasmin Bom 2019'
exports_dir = '/home/jas/dev/godot/exports'

def main():
    print('fetching version')
    version_file = Path('VERSION')
    version = str(git.describe('--tags')).strip()
    short_version = version.rsplit('-', maxsplit=1)[0]
    print('new version: {} ({})'.format(version, short_version))
    with version_file.open('w') as f:
        f.write(version)
    print('VERSION file created')
    export_dir = Path(exports_dir).resolve() / '-'.join(game_name)
    export_dir.mkdir(exist_ok=True)
    export_dir /= version
    export_dir.mkdir(exist_ok=True)
    print('export directory: {}'.format(export_dir))

    for platform, short_platform in platforms:
        platform_export_dir = export_dir / '-'.join(game_name + [short_platform, short_version])
        platform_export_dir.mkdir(exist_ok=True)
        export_path = platform_export_dir / '-'.join(game_name)
        if short_platform == 'windows':
            export_path = export_path.with_suffix('.exe')
        print('exporting {} to {}'.format(platform, export_path))
        godot('--export', platform, export_path)

        license_file = Path(__file__).parent / 'LICENSE'
        copyfile(license_file, Path(platform_export_dir) / 'LICENSE')

        if short_platform == 'html5':
            export_path.rename(export_path.with_name('index').with_suffix('.html'))

        if short_platform == 'windows':
            wine(rc_edit, export_path, '--set-icon', 'icon.ico')
            wine(rc_edit, export_path, '--set-file-version', short_version[1:])
            wine(rc_edit, export_path, '--set-product-version', short_version[1:])
            wine(rc_edit, export_path, '--set-version-string', 'CompanyName', '-'.join(game_name))
            wine(rc_edit, export_path, '--set-version-string', 'ProductName', '-'.join(game_name))
            wine(rc_edit, export_path, '--set-version-string', 'FileDescription', '-'.join(game_name))
            wine(rc_edit, export_path, '--set-version-string', 'OriginalFilename', export_path.name)
            wine(rc_edit, export_path, '--set-version-string', 'LegalCopyright', copyright_text)

        archive_path = export_dir / ('-'.join(game_name + [short_platform, short_version]) + '.zip')
        print('archiving to {}'.format(archive_path))
        make_archive(archive_path.with_suffix(''), 'zip', platform_export_dir)

        with ZipFile(archive_path, 'r') as f:
            print(f.namelist())

    version_file.unlink()

if __name__ == '__main__':
    main()