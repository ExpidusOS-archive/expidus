{
  self,
  nixos-mobile,
  flake-utils,
  ...
}@inputs:
lib:
let
  expidus-devices = (builtins.filter
    (d: builtins.pathExists (../. + "/devices/${d}/default.nix"))
      (builtins.attrNames (builtins.readDir ../devices)));
  nixos-mobile-devices = (builtins.filter
    (d: builtins.pathExists ("${nixos-mobile}/devices/${d}/default.nix"))
      (builtins.attrNames (builtins.readDir "${nixos-mobile}/devices")));
in
rec {
  all-devices = nixos-mobile-devices ++ expidus-devices;

  isExpidusDevice = device: (lib.lists.findFirst (item: item == device) null expidus-devices) == device;
  isNixOSMobileDevice = device: (lib.lists.findFirst (item: item == device) null nixos-mobile-devices) == device;

  getDevicePath = device:
    if isExpidusDevice device then
      ../. + "/devices/${device}/default.nix"
    else if isNixOSMobileDevice device then
      "${nixos-mobile}/devices/${device}/default.nix"
    else throw "Unknown device ${device}";

  evalConfig = import ./eval-config.nix inputs;

  mkMobileSystem = device: pkgs: modules:
    evalConfig {
      inherit (pkgs) system;
      inherit pkgs lib;

      modules = modules ++ [
        (getDevicePath device)
        ../system/default.nix
      ];
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

      uefi-aarch64 = mkMobileSystem "uefi-aarch64" aarch64-multiplatform modules;
      llvm-uefi-aarch64 = mkMobileSystem "uefi-aarch64" aarch64-multiplatform.pkgsLLVM modules;
    };

  mkNamedSystemSet = name: pkgs: modules:
    lib.listToAttrs (builtins.attrValues (builtins.mapAttrs (sysname: lib.nameValuePair "${name}-${sysname}") (mkSystemSet pkgs modules)));

  genExpidusConfigurations = pkgs:
    mkSystemSet pkgs [
      ../system/default.nix
    ]
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
