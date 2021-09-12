from xdg import xdg_config_home
import click, sys, shutil, subprocess
from run import run

def handle_acsm(acsm_path):
    drm_path = acsm_path.with_suffix('.drm')
    adobe_dir = xdg_config_home() / 'knock' / 'acsm'

    if drm_path.exists():
        click.echo(f"Error: {drm_path} must be moved out of the way or deleted.", err=True)
        sys.exit(1)

    adobe_dir.mkdir(parents=True, exist_ok=True)

    if (
        not (adobe_dir / 'device.xml').exists()
        or not (adobe_dir / 'activation.xml').exists()
        or not (adobe_dir / 'devicesalt').exists()
    ):
        shutil.rmtree(str(adobe_dir))
        click.echo('This device is not registered with Adobe.')
        email = click.prompt("Enter your Adobe account's email address")
        password = click.prompt("Enter your Adobe account's password", hide_input=True)
        click.echo('Registering this device with Adobe...')

        run(
            [
                'adept-register',
                '-u', email,
                '-O', str(adobe_dir)
            ],
            stdin=password+'\n',
            cleanser=lambda:shutil.rmtree(str(adobe_dir))
        )

    click.echo('Downloading the EPUB file from Adobe...')

    run([
        'adept-download',
        '-d', str(adobe_dir.joinpath('device.xml')),
        '-a', str(adobe_dir.joinpath('activation.xml')),
        '-k', str(adobe_dir.joinpath('devicesalt')),
        '-o', str(drm_path),
        '-f', str(acsm_path)
    ])

    drm_file_type = magic.from_file(str(args.drm_file), mime=True)
    if drm_file_type == 'application/epub+zip':
        decryption_command = 'inept-epub'
    elif drm_file_type == 'application/pdf':
        decryption_command = 'inept-pdf'
    else:
        click.echo(f'Error: Received file of media type {drm_file_type}.', err=True)
        click.echo('Only the following ACSM conversions are currently supported:', err=True)
        click.echo('  * ACSM -> EPUB', err=True)
        click.echo('  * ACSM -> PDF', err=True)
        click.echo('Please open a feature request at:', err=True)
        click.echo(f'  https://github.com/BentonEdmondson/knock/issues/new?title=Support%20{drm_file_type}%20Files&labels=enhancement', err=True)
        sys.exit(1)

    click.echo('Decrypting the file...')

    run([
        decryption_command,
        str(args.adobe_dir.joinpath('activation.xml')),
        str(args.drm_file),
        str(args.epub_file)
    ])

    args.drm_file.unlink()

    click.secho(f'DRM-free EPUB file created:\n{str(args.epub_file)}', color='green')