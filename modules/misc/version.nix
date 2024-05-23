{ lib, ... }:
with lib;
{
  config.system.nixos = {
    distroId = mkForce "expidus";
    distroName = mkForce "ExpidusOS";
  };
}
