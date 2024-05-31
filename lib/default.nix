{
  self,
  nixos-mobile,
  flake-utils,
  ...
}@inputs:
lib:
rec {
  all-devices =
    let
      expidus-devices = (builtins.filter
        (d: builtins.pathExists (../. + "/devices/${d}/default.nix"))
          (builtins.attrNames (builtins.readDir ../devices)));
      nixos-mobile-devices = (builtins.filter
        (d: builtins.pathExists ("${nixos-mobile}/devices/${d}/default.nix"))
          (builtins.attrNames (builtins.readDir "${nixos-mobile}/devices")));
    in nixos-mobile-devices ++ expidus-devices;

  mkMobileSystem = device: pkgs: modules:
    import "${nixos-mobile}" {
      inherit (pkgs) system;
      inherit pkgs device;

      configuration = { config, lib, pkgs, ... }: {
        imports = (builtins.attrValues self.nixosModules) ++ [
          ../system/default.nix
        ] ++ modules;
      };
    };

  mkSystemSet = pkgs: modules:
    let
      aarch64-multiplatform = if pkgs.hostPlatform.isAarch64 then pkgs else pkgs.pkgsCross.aarch64-multiplatform;
      gnu64 = if pkgs.hostPlatform.isx86_64 then pkgs else pkgs.pkgsCross.gnu64;
    in {
      pine64-pinephone = mkMobileSystem "pine64-pinephone" aarch64-multiplatform modules;
      llvm-pine64-pinephone = mkMobileSystem "pine64-pinephone" aarch64-multiplatform.pkgsLLVM modules;

      uefi-x86_64 = mkMobileSystem "uefi-x86_64" gnu64 modules;
      llvm-uefi-x86_64 = mkMobileSystem "uefi-x86_64" gnu64.pkgsLLVM modules;

      uefi-aarch64 = mkMobileSystem ../devices/uefi-aarch64 aarch64-multiplatform modules;
      llvm-uefi-aarch64 = mkMobileSystem ../devices/uefi-aarch64 aarch64-multiplatform.pkgsLLVM modules;
    };

  mkNamedSystemSet = name: pkgs: modules:
    lib.listToAttrs (builtins.attrValues (builtins.mapAttrs (sysname: lib.nameValuePair "${name}-${sysname}") (mkSystemSet pkgs modules)));

  genExpidusConfigurations = pkgs:
    mkSystemSet pkgs []
      // mkNamedSystemSet "demo" pkgs [
        ../system/demo.nix
      ];

  genNixOSConfigurations = expidusConfigurations:
    lib.listToAttrs
      (lib.flatten (builtins.attrValues (builtins.mapAttrs
        (system: set: builtins.attrValues (builtins.mapAttrs
          (device: lib.nameValuePair "${system}-${device}") set))
            expidusConfigurations)));

  mkFlake = {
    overlay ? f: p: {},
    mkShells ? systemSelf: {},
    mkPackages ? systemSelf: {}
  }@flake:
    let
      flakeSelf = flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = inputs.self.legacyPackages.${system}.extend overlay;

          systemSelf = {
            legacyPackages = pkgs;
            packages = mkPackages systemSelf;
            devShells = mkShells systemSelf;
          } // lib.optionalAttrs (pkgs.hostPlatform.isLinux) {
            expidusConfigurations = genExpidusConfigurations pkgs;
          };
        in systemSelf) // {
          nixosConfigurations = lib.expidus.genNixOSConfigurations flakeSelf.expidusConfigurations;
          overlays.default = overlay;
        };
    in flakeSelf;
}
