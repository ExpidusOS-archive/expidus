{ config, lib, pkgs, ... }:
{
  config = lib.mkMerge [
    (lib.mkIf (config.mobile.device.name == "uefi-x86_64") {
      mobile.boot.serialConsole = "ttyS0,115200n8";

      systemd.services."serial-getty@ttyS0" = {
        enable = true;
        wantedBy = [ "multi-user.target" ];
      };
    })
    {
      users.users.demo = {
        description = "Demo User";
        group = "wheel";
        initialPassword = "1234";
        isNormalUser = true;
        createHome = true;
      };
    }
  ];
}
