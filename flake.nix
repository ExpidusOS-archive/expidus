{
  description = "The easy to use mobile and desktop operating system from Midstall Software";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixos-mobile = {
      url = "github:RossComputerGuy/mobile-nixos/fix/impure";
      flake = false;
    };
    nixos-apple-silicon = {
      url = "github:tpwrules/nixos-apple-silicon/1b16e4290a5e4a59c75ef53617d597e02078791e";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    nixos-hardware,
    nixos-mobile,
    nixos-apple-silicon,
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
        default = { ... }:
          {
            imports = import ./modules inputs;
          };
      };
    in {
      inherit overlays nixosModules;
      lib = lib.expidus;

      nixosConfigurations = lib.expidus.genNixOSConfigurations self.expidusConfigurations;
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = (nixpkgs.legacyPackages.${system}.appendOverlays (builtins.attrValues overlays)).extend (final: prev: rec {
          lib = prev.lib.extend (f: p: {
            expidus = import ./lib inputs f;
          });

          isAsahi = prev.targetPlatform.isAarch64 && prev.stdenv.isLinux;
          pkgsAsahi = if isAsahi then prev.appendOverlays [
            nixos-apple-silicon.overlays.default
            (f: p: {
              mesa = p.mesa-asahi-edge;
            })
          ] else null;
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
