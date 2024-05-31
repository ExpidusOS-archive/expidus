{
  self,
  nixos-mobile,
  nixpkgs,
  ...
}@inputs:
{
  system ? builtins.currentSystem,
  pkgs ? self.legacyPackages.${system},
  lib ? pkgs.lib,
  modules ? [],
  specialArgs ? {},
}:
let
  evalConfig = import "${nixpkgs}/nixos/lib/eval-config.nix";

  baseModules = lib.lists.flatten [
    (import ../modules/default.nix inputs)
    (import "${nixos-mobile}/modules/module-list.nix")
    (import "${nixpkgs}/nixos/modules/module-list.nix")
  ];

  evalModules = evalConfig {
    inherit modules pkgs system baseModules lib specialArgs;
  };

  outputs = evalModules.config.mobile.outputs // evalModules.config.mobile.outputs.${evalModules.config.mobile.system.type};
in
evalModules // {
  inherit evalModules baseModules outputs modules;
  class = "expidus";
}
