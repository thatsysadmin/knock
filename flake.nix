{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    gourou-src = {
      url   = "git://soutade.fr/libgourou.git";
      type  = "git";
      ref   = "master";
      flake = false;
    };
    updfparser-src = {
      url   = "git://soutade.fr/updfparser.git";
      type  = "git";
      ref   = "master";
      flake = false;
    };
    base64-src = {
      url = "git+https://gist.github.com/f0fd86b6c73063283afe550bc5d77594.git";
      flake = false;
    };
    pugixml-src = {
      url   = "github:zeux/pugixml/latest";
      flake = false;
    };
  };

  outputs = flakes: let
    self = flakes.self.packages.x86_64-linux;
    nixpkgs = flakes.nixpkgs.legacyPackages.x86_64-linux.pkgsStatic;
    gourou-src = flakes.gourou-src;
    updfparser-src = flakes.updfparser-src;
    base64-src = flakes.base64-src;
    pugixml-src = flakes.pugixml-src;
    cxx = "${nixpkgs.stdenv.cc}/bin/x86_64-unknown-linux-musl-g++";
    ar = "${nixpkgs.stdenv.cc.bintools.bintools_bin}/bin/x86_64-unknown-linux-musl-ar";
    obj-flags = "-O2 -static";
  in rec {
    packages.x86_64-linux.libzip-static = nixpkgs.libzip.overrideAttrs (prev: {
      cmakeFlags = (prev.cmakeFlags or []) ++ [
        "-DBUILD_SHARED_LIBS=OFF"
        "-DBUILD_EXAMPLES=OFF"
        "-DBUILD_DOC=OFF"
        "-DBUILD_TOOLS=OFF"
        "-DBUILD_REGRESS=OFF"
      ];
      outputs = ["out"];
    });
    packages.x86_64-linux.base64 = derivation {
      name = "updfparser";
      system = "x86_64-linux";
      builder = "${nixpkgs.bash}/bin/bash";
      PATH = "${nixpkgs.coreutils}/bin";
      args = ["-c" ''
        mkdir -p $out/include/base64
        cp ${base64-src}/Base64.h $out/include/base64/Base64.h
      ''];
    };
    packages.x86_64-linux.updfparser = derivation {
      name = "updfparser";
      system = "x86_64-linux";
      builder = "${nixpkgs.bash}/bin/bash";
      PATH = "${nixpkgs.coreutils}/bin";
      args = [ "-c" ''
        ${cxx} \
          -c ${updfparser-src}/src/*.cpp \
          -I ${updfparser-src}/include \
          ${obj-flags}
        mkdir -p $out/lib
        ${ar} crs $out/lib/libupdfparser.a *.o
      '' ];
    };
    packages.x86_64-linux.gourou = derivation {
      name = "gourou";
      system = "x86_64-linux";
      builder = "${nixpkgs.bash}/bin/bash";
      PATH = "${nixpkgs.coreutils}/bin";
      args = [ "-c" ''
        ${cxx} \
          -c \
          ${gourou-src}/src/*.cpp \
          ${pugixml-src}/src/pugixml.cpp \
          -I ${self.base64}/include \
          -I ${gourou-src}/include \
          -I ${pugixml-src}/src \
          -I ${updfparser-src}/include \
          ${obj-flags}
        mkdir -p $out/lib $out/debug
        ${ar} crs $out/lib/libgourou.a *.o
        cp *.o $out/debug
      '' ];
    };
    packages.x86_64-linux.utils-common = derivation {
      name = "utils-common";
      system = "x86_64-linux";
      builder = "${nixpkgs.bash}/bin/bash";
      PATH = "${nixpkgs.coreutils}/bin";
      args = [ "-c" ''
        ${cxx} \
          -c ${gourou-src}/utils/drmprocessorclientimpl.cpp \
             ${gourou-src}/utils/utils_common.cpp \
          -I ${gourou-src}/utils \
          -I ${gourou-src}/include \
          -I ${pugixml-src}/src \
          -I ${nixpkgs.openssl.dev}/include \
          -I ${nixpkgs.curl.dev}/include \
          -I ${nixpkgs.zlib.dev}/include \
          -I ${self.libzip-static}/include \
          ${obj-flags}
        mkdir -p $out/lib
        ${ar} crs $out/lib/libutils-common.a *.o
      '' ];
    };
    packages.x86_64-linux.knock = derivation {
      name = "knock";
      system = "x86_64-linux";
      builder = "${nixpkgs.bash}/bin/bash";
      PATH = "${nixpkgs.coreutils}/bin";
      args = [ "-c" ''
        mkdir -p $out/bin
        ${cxx} \
          -o $out/bin/knock \
          ${./src/knock.cpp} \
          -Wl,--as-needed -static \
          ${self.utils-common}/lib/libutils-common.a \
          ${self.gourou}/lib/libgourou.a \
          ${self.updfparser}/lib/libupdfparser.a \
          -Wl,--start-group \
          ${self.libzip-static}/lib/libzip.a \
          ${nixpkgs.libnghttp2}/lib/libnghttp2.a \
          ${nixpkgs.libidn2.out}/lib/libidn2.a \
          ${nixpkgs.libunistring}/lib/libunistring.a \
          ${nixpkgs.libssh2}/lib/libssh2.a \
          ${nixpkgs.zstd.out}/lib/libzstd.a \
          ${nixpkgs.zlib}/lib/libz.a \
          ${nixpkgs.openssl.out}/lib/libcrypto.a \
          ${nixpkgs.curl.out}/lib/libcurl.a \
          ${nixpkgs.openssl.out}/lib/libssl.a \
          -static-libgcc -static-libstdc++ \
          -Wl,--end-group \
          -I ${gourou-src}/utils \
          -I ${gourou-src}/include \
          -I ${pugixml-src}/src \
          -I ${nixpkgs.openssl.dev}/include \
          -I ${nixpkgs.curl.dev}/include \
          -I ${nixpkgs.zlib.dev}/include \
          -I ${self.libzip-static}/include
      '' ];
    };
    defaultPackage.x86_64-linux = self.knock;
  };
}