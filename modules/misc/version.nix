{ config, lib, options, ... }:
with lib;
let
  isMobileNixOS = options ? mobile;
in
{
  config = {
    system.nixos = {
      distroId = mkForce "expidus";
      distroName = mkForce "ExpidusOS";
    };
    services.getty.greetingLine = mkBefore ''<<< Welcome to ExpidusOS ${config.system.nixos.label}${optionalString (isMobileNixOS) " on ${config.mobile.device.name}"} (\m) - \l >>>'';
  };
}
