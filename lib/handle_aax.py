from xdg import xdg_config_home
from utils import open_fake_terminal, close_fake_terminal, run
import audible, click, sys

def handle_aax(aax_path):
    authcode_path = xdg_config_home().joinpath('knock', 'aax', 'authcode')

    # make the config dir if it doesn't exist
    authcode_path.parent.mkdir(parents=True, exist_ok=True)

    m4b_path = aax_path.with_suffix('.m4b')
    cover_path = aax_path.parent.joinpath('cover.jpg')
    chapters_path = aax_path.with_suffix('.chapters.txt')

    if m4b_path.exists():
        click.echo(f"Error: {m4b_path} must be moved out of the way or deleted.", err=True)
        sys.exit(1)

    if cover_path.exists():
        click.echo(f"Error: {cover_path} must be moved out of the way or deleted.", err=True)
        sys.exit(1)

    if chapters_path.exists():
        click.echo(f"Error: {chapters_path} must be moved out of the way or deleted.", err=True)
        sys.exit(1)

    if not authcode_path.exists():
        click.echo('This device does not have an Audible decryption key.')

        email = click.prompt("Enter your Audible account's email address")
        password = click.prompt("Enter your Audible account's password", hide_input=True)
        locale = click.prompt("Enter your locale (e.g. 'us', 'ca', 'jp', etc)")

        open_fake_terminal(f'audible.auth.Authenticator.from_login("{email}", "{locale}").get_activation_bytes()')

        try:
            authcode = audible.auth.Authenticator.from_login(
                username=email,
                password=password,
                locale=locale
            ).get_activation_bytes()
            authcode_path.write_text(authcode)
        except Exception as error:
            click.echo(error, err=True)
            close_fake_terminal(1)

        close_fake_terminal(0)

    click.echo('Decrypting the file...')

    authcode = authcode_path.read_text()

    def cleanup():
        cover_path.unlink(missing_ok=True)
        chapters_path.unlink(missing_ok=True)

    run([
        'AAXtoMP3',
        '--authcode', authcode,
        '-e:m4b',
        '-t', str(aax_path.parent),
        '-D', '.',
        '-F', str(aax_path.stem),
        str(aax_path)
    ], cleanser=cleanup)

    cleanup()

    click.secho(f'DRM-free M4B file created:\n{aax_path.with_suffix(".m4b")}', fg='green')
