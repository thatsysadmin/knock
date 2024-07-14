{
  inputs = {
    nixpkgs.url = "git+https://github.com/nixos/nixpkgs";
    flake-utils.url = "git+https://github.com/numtide/flake-utils";
    gourou-src = {
      url = "git+https://forge.soutade.fr/soutade/libgourou";
      flake = false;
    };
    updfparser-src = {
      url = "git+https://forge.soutade.fr/soutade/updfparser";
      flake = false;
    };
    base64-src = {
      url = "git+https://gist.github.com/tomykaira/f0fd86b6c73063283afe550bc5d77594";
      flake = false;
    };
    pugixml-src = {
      url = "git+https://github.com/zeux/pugixml";
      flake = false;
    };
  };

  outputs = flakes:
    flakes.flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ]
      (system:
        let
          version = "1.3.3";
          self = flakes.self.packages.${system};
          nixpkgs = flakes.nixpkgs.legacyPackages.${system}.pkgsStatic;
          nixpkgs-dyn = flakes.nixpkgs.legacyPackages.${system};
          nixpkgs-fmt = flakes.nixpkgs-fmt.defaultPackage.${system};
          gourou-src = flakes.gourou-src;
          updfparser-src = flakes.updfparser-src;
          base64-src = flakes.base64-src;
          pugixml-src = flakes.pugixml-src;
          cxx = "${nixpkgs.stdenv.cc}/bin/${nixpkgs.stdenv.cc.targetPrefix}c++";
          ar = "${nixpkgs.stdenv.cc.bintools.bintools_bin}/bin/${nixpkgs.stdenv.cc.targetPrefix}ar";
          obj-flags = "-O3 -static";
        in
        rec {
          packages.updfparser = derivation {
            name = "updfparser";
            inherit system;
            builder = "${nixpkgs.bash}/bin/bash";
            PATH = "${nixpkgs.coreutils}/bin";
            args = [
              "-c"
              ''
                ${cxx} \
                  -c ${updfparser-src}/src/*.cpp \
                  -I ${updfparser-src}/include \
                  ${obj-flags}
                mkdir -p $out/lib
                ${ar} crs $out/lib/libupdfparser.a *.o
              ''
            ];
          };
          packages.gourou = derivation {
            name = "gourou";
            inherit system;
            builder = "${nixpkgs.bash}/bin/bash";
            PATH = "${nixpkgs.coreutils}/bin";
            args = [
              "-c"
              ''
                shopt -s extglob
                ${cxx} \
                  -c \
                  ${gourou-src}/src/!(pugixml).cpp \
                  ${pugixml-src}/src/pugixml.cpp \
                  -I ${base64-src} \
                  -I ${gourou-src}/include \
                  -I ${pugixml-src}/src \
                  -I ${updfparser-src}/include \
                  ${obj-flags}
                mkdir -p $out/lib
                ${ar} crs $out/lib/libgourou.a *.o
              ''
            ];
          };
          packages.utils-common = derivation {
            name = "utils-common";
            inherit system;
            builder = "${nixpkgs.bash}/bin/bash";
            PATH = "${nixpkgs.coreutils}/bin";
            args = [
              "-c"
              ''
                ${cxx} \
                  -c ${gourou-src}/utils/drmprocessorclientimpl.cpp \
                     ${gourou-src}/utils/utils_common.cpp \
                  -I ${gourou-src}/utils \
                  -I ${gourou-src}/include \
                  -I ${pugixml-src}/src \
                  -I ${nixpkgs.openssl.dev}/include \
                  -I ${nixpkgs.curl.dev}/include \
                  -I ${nixpkgs.zlib.dev}/include \
                  -I ${nixpkgs.libzip.dev}/include \
                  ${obj-flags}
                mkdir -p $out/lib
                ${ar} crs $out/lib/libutils-common.a *.o
              ''
            ];
          };
          packages.knock = derivation {
            name = "knock";
            inherit system;
            builder = "${nixpkgs.bash}/bin/bash";
            PATH = "${nixpkgs.coreutils}/bin";
            args = [
              "-c"
              ''
                mkdir -p $out/bin
                ${cxx} \
                  -o $out/bin/knock \
                  ${./src/knock.cpp} \
                  -D KNOCK_VERSION='"${version}"' \
                  --std=c++17 \
                  -Wextra -Wall -s \
                  -Wl,--as-needed -static \
                  ${self.utils-common}/lib/libutils-common.a \
                  ${self.gourou}/lib/libgourou.a \
                  ${self.updfparser}/lib/libupdfparser.a \
                  -Wl,--start-group \
                  ${nixpkgs.libzip}/lib/libzip.a \
                  ${nixpkgs.libnghttp2}/lib/libnghttp2.a \
                  ${nixpkgs.libidn2.out}/lib/libidn2.a \
                  ${nixpkgs.libunistring}/lib/libunistring.a \
                  ${nixpkgs.libssh2}/lib/libssh2.a \
                  ${nixpkgs.zstd.out}/lib/libzstd.a \
                  ${nixpkgs.zlib}/lib/libz.a \
                  ${nixpkgs.openssl.out}/lib/libcrypto.a \
                  ${nixpkgs.curl.out}/lib/libcurl.a \
                  ${nixpkgs.libpsl.out}/lib/libpsl.a \
                  ${nixpkgs.openssl.out}/lib/libssl.a \
                  -static-libgcc -static-libstdc++ \
                  -Wl,--end-group \
                  -I ${gourou-src}/utils \
                  -I ${gourou-src}/include \
                  -I ${pugixml-src}/src \
                  -I ${nixpkgs.openssl.dev}/include \
                  -I ${nixpkgs.curl.dev}/include \
                  -I ${nixpkgs.zlib.dev}/include \
                  -I ${nixpkgs.libzip.dev}/include
              ''
            ];
          };
          packages.default = self.knock;
          packages.tests = nixpkgs-dyn.stdenv.mkDerivation {
            name = "tests";
            src = ./tests;
            buildInputs = [
              (nixpkgs-dyn.python3.withPackages (p: [
                p.beautifulsoup4
                p.requests
              ]))
            ];
            patchPhase = ''
              substituteInPlace tests.py --replace "./result/bin/knock" "${self.knock}/bin/knock"
            '';
            installPhase = ''
              mkdir -p $out/bin
              cp tests.py $out/bin/tests
              chmod +x $out/bin/tests
            '';
          };
          packages.formatter = nixpkgs.writeShellScriptBin "formatter" ''
            set -x
            ${nixpkgs-dyn.clang-tools}/bin/clang-format -i --verbose ./src/*.cpp
            ${nixpkgs-dyn.nixpkgs-fmt}/bin/nixpkgs-fmt .
            ${nixpkgs-dyn.black}/bin/black ./tests
          '';
        }
      );
}
