import click, subprocess, sys

# run a command and display output in a styled terminal
# cleanser is called if the command returns a >0 exit code
def run(command: [str], stdin: str = '', cleanser = lambda: None) -> int:

    # newline and set styles
    click.secho('', fg='white', bg='black', bold=True, reset=False)

    # show command
    click.echo('knock> ' + ' '.join(command))

    # remove bold
    click.secho('', fg='white', bg='black', bold=False, reset=False)
    result = subprocess.run(
        command,
        stderr=subprocess.STDOUT,
        input=stdin.encode(),
        check=False # don't throw Python error if returncode isn't 0
    )

    # show returncode in bold, then reset styles
    click.secho(f'\nknock[{result.returncode}]>', bold=True)

    # newline
    click.echo('')

    if result.returncode > 0:
        cleanser()
        click.echo(f'Error: Command returned error code {result.returncode}.', err=True)
        sys.exit(1)
    
    return result.returncode