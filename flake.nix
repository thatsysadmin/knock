{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    rmdrm.url = "github:BentonEdmondson/rmdrm";
    rmdrm.inputs.nixpkgs.follows = "nixpkgs";

    benpkgs.url = "github:BentonEdmondson/benpkgs";
    benpkgs.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = flakes: let
    nixpkgs = flakes.nixpkgs.legacyPackages.x86_64-linux;
    libgourou-utils = flakes.libgourou-utils.defaultPackage.x86_64-linux;
    rmdrm = flakes.rmdrm.defaultPackage.x86_64-linux;
    benpkgs = flakes.benpkgs.packages.x86_64-linux;
  in {
    defaultPackage.x86_64-linux = nixpkgs.python3Packages.buildPythonApplication rec {
      pname = "knock";
      version = "1.1.0-alpha";
      src = ./.;

      nativeBuildInputs = [ nixpkgs.makeWrapper ];

      buildInputs = [
        rmdrm
        benpkgs.libgourou
        nixpkgs.ffmpeg
      ];

      propagatedBuildInputs = [
        benpkgs.Audible
        nixpkgs.python3Packages.python_magic
        nixpkgs.python3Packages.xdg
        nixpkgs.python3Packages.click
      ];

      format = "other";

      installPhase = ''
        mkdir -p $out/bin $out/${nixpkgs.python3.sitePackages}
        cp lib/*.py $out/${nixpkgs.python3.sitePackages}
        cp src/knock.py $out/bin/knock
        wrapProgram $out/bin/knock --prefix PATH : ${nixpkgs.lib.makeBinPath buildInputs}
      #'';

      meta = {
        description = "A CLI tool to convert ACSM files to DRM-free EPUB/PDF files";
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