{
  self,
  nixos-mobile,
  ...
}@inputs:
lib:
rec {
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
    };

  mkNamedSystemSet = name: pkgs: modules:
    lib.listToAttrs (builtins.attrValues (builtins.mapAttrs (sysname: lib.nameValuePair "${name}-${sysname}") (mkSystemSet pkgs modules)));
}
