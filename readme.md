# Knock

Perform the following conversions with one command:
* ACSM → EPUB
* ACSM → PDF
* (Soon: AAX → M4B)

![CLI demonstration](demo.png)

*This software does not utilize Adobe Digital Editions nor Wine. It is completely free and open-source software written natively for Linux.*

## Setup and Installation

* For NixOS users, include this flake in your system `flake.nix`. Then run `knock ~/path/to/my-book.acsm` to use.
    ```nix
    {
        inputs.knock.url = "github:BentonEdmondson/knock";
        outputs = { self, knock }: { /* knock.defaultPackage.x86_64-linux is the package */ };
    }
    ```
* For non-NixOS, use the latest [release](https://github.com/BentonEdmondson/knock/releases). It is large because it includes all dependencies, allowing it to run on any system with an x86_64 Linux kernel. It was built using [`nix bundle`](https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-bundle.html). Use it by doing the following:
    1. Download `knock-version-x86_64-linux` and open a terminal
    1. Navigate to the folder within which `knock-version-x86_64-linux` resides (e.g. `cd ~/Downloads`)
    1. Run `mv knock-version-x86_64-linux knock` to rename it to `knock`
    1. Run `chmod +x knock` to make it executable
    1. Run `./knock ~/path/to/my-book.acsm` to convert the ebook

        If you receive an error that says something like `./nix/store/...: not found` or `./nix/store/...: No such file or directory` then you might not have user namespaces enabled. Try running the following to fix it:

        ```
        echo "kernel.unprivileged_userns_clone=1" >> /etc/sysctl.conf
        sudo reboot
        ```
        If you receive an error that says something like `E_AUTH_FAILED http://adeactivate.adobe.com/adept/SignInDirect xxxx@xxxxxxxx.com CUS05051` then you might have over (at least) 10 digit password for Adobe. Try changing it to 10 digit password and try the command again.

    1. Optionally move the executable to `~/bin` (for your user) or `/usr/local/bin/` (for all users) to allow it to run from anywhere (might not work on some distributions)

## Recommended Workflows

Before buying your ebook/audiobook, check if it is available for free on [Project Gutenberg](https://gutenberg.org/) (ebooks) or [LibriVox](https://librivox.org/) (audiobooks).

If you're looking for an ebook reader or audiobook player, I recommend [Foliate](https://johnfactotum.github.io/foliate/) for the former and [Cozy](https://cozy.sh/) for the latter.

## Verified Book Sources

Knock should work on any ACSM file, but it has been specifically verified to work on ACSM files from the following:

* [eBooks.com](https://www.ebooks.com/en-us/)
* [Rakuten Kobo](https://www.kobo.com/us/en)
* [Google Books](https://books.google.com/)
* [Hugendubel.de](https://www.hugendubel.de/de/) (German)

## The Name

The name comes from the [D&D 5e spell](https://roll20.net/compendium/dnd5e/Knock#content) for freeing locked items:

> ### Knock
> *2nd level transmutation*\
> **Casting Time**: 1 action\
> **Range**: 60 feet\
> **Components**: V\
> **Duration**: Instantaneous\
> **Classes**: Bard, Sorcerer, Wizard\
> Choose an object that you can see within range. The object can be a door, a box, a chest, a set of manacles, a padlock, or another object that contains a mundane or magical means that prevents access. A target that is held shut by a mundane lock or that is stuck or barred becomes unlocked, unstuck, or unbarred. If the object has multiple locks, only one of them is unlocked. If you choose a target that is held shut with arcane lock, that spell is suppressed for 10 minutes, during which time the target can be opened and shut normally. When you cast the spell, a loud knock, audible from as far away as 300 feet, emanates from the target object.

## Dependencies

* [`libgourou`](http://indefero.soutade.fr/p/libgourou/) for using the ACSM file to download the corresponding encrypted EPUB/PDF file from Adobe's servers
* [`rmdrm`](https://github.com/BentonEdmondson/rmdrm/) for decrypting the Adobe ADEPT-encrypted EPUB/PDF files
* [`Audible`](https://github.com/mkb79/Audible) for fetching the Audible decryption key used to decrypt AAX files
* [`ffmpeg`](https://www.ffmpeg.org/) for converting AAX files to M4B files using the Audible decryption key

These are already included in all releases and in the Nix flake of course.

## License

This software is licensed under GPLv3.
