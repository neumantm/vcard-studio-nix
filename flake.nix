{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
  };

  outputs = { self, nixpkgs }: let
    lib = nixpkgs.lib;
    supportedSystem = lib.lists.subtractLists [
      "x86_64-freebsd" # while evaluating deps: error: infinite recursion encountered
    ] lib.systems.flakeExposed;
    eachSupportedSystem = lib.genAttrs supportedSystem;
  in {
    packages = eachSupportedSystem (system:{
        vcard-studio = nixpkgs.legacyPackages.${system}.callPackage ./default.nix { inherit system; };
      }
    );

    defaultPackage = eachSupportedSystem (system:
      builtins.head (builtins.attrValues self.packages.${system})
    );

    devShell = eachSupportedSystem (system:
      nixpkgs.legacyPackages.${system}.mkShell {
        inputsFrom = builtins.attrValues self.packages.${system};
      }
    );
  };
}
