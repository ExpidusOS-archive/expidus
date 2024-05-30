{ config, lib, pkgs, ... }:
with lib;
{
  config = mkMerge [
    (mkIf (pkgs.targetPlatform.isx86_64 && !pkgs.buildPlatform.isx86_64) {
      environment.stub-ld.enable = mkForce false;
    })
    {
      security.apparmor.enable = pkgs.stdenv.hostPlatform == pkgs.stdenv.buildPlatform
        && meta.availableOn pkgs.stdenv.hostPlatform pkgs.python3
        && meta.availableOn pkgs.stdenv.hostPlatform pkgs.perl;
      services.genesis-shell.enable = true;
      system.stateVersion = version;
    }
  ];
}
