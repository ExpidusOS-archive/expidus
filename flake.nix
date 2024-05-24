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
      inherit (nixpkgs) lib;

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
        default = ./modules;
      };
    in {
      inherit overlays nixosModules;

      nixosConfigurations = lib.listToAttrs
        (lib.flatten (builtins.attrValues (builtins.mapAttrs
          (system: set: builtins.attrValues (builtins.mapAttrs
            (device: lib.nameValuePair "${system}-${device}") set))
              self.expidusConfigurations)));
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = builtins.attrValues overlays;
        };
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
        expidusConfigurations = let
          mkMobileSystem = device: pkgs: modules:
            import "${nixos-mobile}" {
              inherit (pkgs) system;
              inherit pkgs device;

              configuration = { config, lib, pkgs, ... }: {
                imports = (builtins.attrValues nixosModules) ++ [
                  ./system/default.nix
                ] ++ modules;
              };
            };

          aarch64-multiplatform = if pkgs.hostPlatform.isAarch64 then pkgs else pkgs.pkgsCross.aarch64-multiplatform;
          gnu64 = if pkgs.hostPlatform.isx86_64 then pkgs else pkgs.pkgsCross.gnu64;

          mkSystemSet = modules: {
            pine64-pinephone = mkMobileSystem "pine64-pinephone" aarch64-multiplatform modules;
            llvm-pine64-pinephone = mkMobileSystem "pine64-pinephone" aarch64-multiplatform.pkgsLLVM modules;

            uefi-x86_64 = mkMobileSystem "uefi-x86_64" gnu64 modules;
            llvm-uefi-x86_64 = mkMobileSystem "uefi-x86_64" gnu64.pkgsLLVM modules;
          };

          mkNamedSystemSet = name: modules:
            lib.listToAttrs (builtins.attrValues (builtins.mapAttrs (sysname: lib.nameValuePair "${name}-${sysname}") (mkSystemSet modules)));
        in mkSystemSet []
          // mkNamedSystemSet "demo" [
            ./system/demo.nix
          ];
      }));
}
