{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    libgourou-utils.url = "github:BentonEdmondson/libgourou-utils";
    libgourou-utils.inputs.nixpkgs.follows = "nixpkgs";

    inept-epub.url = "github:BentonEdmondson/inept-epub";
    inept-epub.inputs.nixpkgs.follows = "nixpkgs";

    benpkgs.url = "github:BentonEdmondson/benpkgs";
    benpkgs.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, ... }@flakes: let
    nixpkgs = flakes.nixpkgs.legacyPackages.x86_64-linux;
    libgourou-utils = flakes.libgourou-utils.defaultPackage.x86_64-linux;
    inept-epub = flakes.inept-epub.defaultPackage.x86_64-linux;
    benpkgs = flakes.benpkgs.packages.x86_64-linux;
  in {
    defaultPackage.x86_64-linux = nixpkgs.python3Packages.buildPythonApplication {
      pname = "knock";
      version = "1.0.0-alpha";
      src = self;

      propagatedBuildInputs = [
        nixpkgs.python3Packages.python_magic
        nixpkgs.python3Packages.xdg
        nixpkgs.python3Packages.click
        libgourou-utils
        inept-epub
        benpkgs.Audible
        benpkgs.AAXtoMP3
      ];

      format = "other";

      installPhase = ''
        mkdir -p $out/bin $out/${nixpkgs.python3.sitePackages}
        cp lib/*.py $out/${nixpkgs.python3.sitePackages}
        cp src/knock.py $out/bin/knock
      '';

      meta = {
        description = "A CLI tool to convert ACSM files to DRM-free EPUB files";
        homepage = "https://github.com/BentonEdmondson/knock";
        license = [ nixpkgs.lib.licenses.gpl3Only ];
        maintainers = [{
          name = "Benton Edmondson";
          email = "bentonedmondson@gmail.com";
        }];
        # potentially others, but I'm only listed those tested
        platforms = [ "x86_64-linux" ];
      };
    };
  };
}