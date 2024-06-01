inputs:
{ config, options, lib, pkgs, ... }:
with lib;
let
  isMobileNixOS = options ? mobile;
in
{
  disabledModules = [
    "${inputs.nixos-mobile}/stage-2-splash.nix"
  ];

  config = mkMerge [
    (mkIf isMobileNixOS {
      mobile = {
        beautification.splash = mkForce true;
        boot.stage-1 = {
          kernel.logo.logo = mkForce ./logo2.svg;
          gui.logo = mkForce ./logo2.svg;
        };
      };

      boot.postBootCommands = ''
        # Reset the VT console.
        # The Mobile NixOS stage-1 can be rude.
        for d in /sys/class/vtconsole/vtcon*; do
          if ${pkgs.busybox}/bin/grep 'frame buffer' "$d/name"; then
            echo 1 > "$d/bind"
          fi
        done
        # Though directly rudely show the stage-2 splash.
        ${pkgs.ply-image}/bin/ply-image --clear=0x000000 ${pkgs.expidus.icons}/share/icons/hicolor/256x256/apps/expidus.png > /dev/null 2>&1
      '';
    })
    (mkIf (isMobileNixOS == false) {
      boot.plymouth = {
        enable = mkDefault true;
        theme = mkDefault "spinner";
      };
    })
    {
      environment.systemPackages = with pkgs; [
        expidus.icons
      ];
    }
  ];
}
