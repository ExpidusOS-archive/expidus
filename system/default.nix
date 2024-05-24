{ config, lib, pkgs, ... }:
with lib;
{
  config = mkMerge [
    (mkIf (pkgs.targetPlatform.isx86_64 && !pkgs.buildPlatform.isx86_64) {
      environment.stub-ld.enable = mkForce false;
    })
    {
      services.genesis-shell.enable = true;
      system.stateVersion = version;
    }
  ];
}
