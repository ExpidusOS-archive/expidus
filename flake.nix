{
  description = "The easy to use mobile and desktop operating system from Midstall Software";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixos-mobile = {
      url = "github:RossComputerGuy/mobile-nixos/fix/impure";
      flake = false;
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    nixos-hardware,
    nixos-mobile,
    flake-utils,
    ...
  }@inputs:
    let
      lib = nixpkgs.lib.extend (final: prev: {
        expidus = import ./lib inputs final;
      });

      overlays = rec {
        crosspkgs = final: prev: {
          pkgsCross = prev.lib.filterAttrs
            (name: pkgsCross:
              pkgsCross.targetPlatform.parsed.kernel.name == prev.targetPlatform.parsed.kernel.name
                && prev.lib.meta.availableOn pkgsCross.targetPlatform pkgsCross.flutter
                && !pkgsCross.targetPlatform.isAndroid)
            prev.pkgsCross;
        };
        default = import ./pkgs/overlay.nix;
      };

      nixosModules = {
        default = import ./modules inputs;
      };
    in {
      inherit overlays nixosModules;
      lib = lib.expidus;

      nixosConfigurations = lib.expidus.genNixOSConfigurations self.expidusConfigurations;
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = (import nixpkgs {
          inherit system;
          overlays = builtins.attrValues overlays;
        }).extend (final: prev: {
          lib = prev.lib.extend (f: p: {
            expidus = import ./lib inputs f;
          });
        });
      in {
        legacyPackages = pkgs;
        packages = let
          cleanSet = set: builtins.removeAttrs set [ "override" "overrideDerivation" "recurseForDerivations" ];
          genSet = pkgsName: pkgSet:
            lib.listToAttrs (builtins.attrValues (lib.mapAttrs (pkgName: lib.nameValuePair "${pkgsName}-${pkgName}") pkgSet));

          base = cleanSet pkgs.expidus;
          llvm = genSet "llvm" (cleanSet pkgs.pkgsLLVM.expidus);
        in base // llvm;
      } // (lib.optionalAttrs (pkgs.hostPlatform.isLinux) {
        expidusConfigurations = lib.expidus.genExpidusConfigurations pkgs;
      }));
}
