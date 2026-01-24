{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        packageName = "vcard-studio";
        packageVersion = "1.4.0";

        app = pkgs.stdenv.mkDerivation rec {
          pname = packageName;
          version = packageVersion;

          src = pkgs.fetchurl {
            url = "https://svn.zdechov.net/vcard-studio/bin/deb/vcard-studio_${version}_amd64.deb";
            sha256 = "sha256-NXTLUlVllqVz2S3SqgvIemGPqa/J/xoFlT8Vs0jEzuU=";
          };

          nativeBuildInputs = with pkgs; [ dpkg autoPatchelfHook makeWrapper ];

          buildInputs = with pkgs;[ cairo pango gdk-pixbuf atkmm gtk2];

          unpackPhase = ''
            runHook preUnpack

            dpkg -x $src ./app-src

            runHook postUnpack
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p "$out"
            cp -r app-src/* "$out"

            mv "$out/usr/bin/" "$out/bin"
            mv "$out/usr/share/" "$out/share"
            rmdir "$out/usr/"

            for f in "$out/share/applications/"*.desktop; do
              substituteInPlace "$f" --replace "/usr/" "$out/"
            done

            wrapProgram "$out/bin/vCardStudio" \
              --set NIX_REDIRECTS "/usr/share=$out/share"

            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "A contact management application with support for vCard file format (.vcf).";
            homepage = "https://app.zdechov.net/vcard-studio";
            license = licenses.unfree;
            platforms = with platforms; [ system ];
            sourceProvenance = with sourceTypes; [ binaryNativeCode ];
            mainProgram = "vCardStudio";
          };
        };
      in {
        packages.${packageName} = app;

        defaultPackage = self.packages.${system}.${packageName};

        devShell = pkgs.mkShell {
          inputsFrom = builtins.attrValues self.packages.${system};
        };
      }
    );
}
