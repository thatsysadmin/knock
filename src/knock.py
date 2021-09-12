#!/usr/bin/env python3

import subprocess, magic, shutil, click
from pathlib import Path
from getpass import getpass
from handle_acsm import handle_acsm
from xdg import xdg_config_home

__version__ = "1.0.0-alpha"

@click.version_option()
@click.command()
@click.argument(
    "file",
    type=click.Path(
        exists=True,
        file_okay=True,
        dir_okay=False,
        readable=True,
        resolve_path=True
    )
)
def main(file):
    file = Path(file)

    # make the config dir if it doesn't exist
    (xdg_config_home() / 'knock').mkdir(parents=True, exist_ok=True)

    file_type = file.suffix[1:].upper()

    if file_type == 'ACSM':
        click.echo('Received an ACSM (Adobe) file...')
        handle_acsm(file)
    else:
        click.echo(f'Error: Files of type {file.suffix[1:].upper()} are not supported.\n', err=True)
        click.echo('Only the following file types are currently supported:', err=True)
        click.echo('  * ACSM (Adobe)\n')
        click.echo('Please open a feature request at:', err=True)
        click.echo(f'  https://github.com/BentonEdmondson/knock/issues/new?title=Support%20{file_type}%20Files&labels=enhancement', err=True)
        sys.exit(1)

if __name__ == "__main__":
    main()