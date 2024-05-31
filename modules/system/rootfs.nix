{ config, lib, ... }:
with lib;
{
  config = {
    mobile.generatedFilesystems.rootfs = mkDefault {
      label = mkForce "EXPIDUS_SYSTEM";
    };

    fileSystems."/" = mkForce {
      device = "/dev/disk/by-label/${config.mobile.generatedFilesystems.rootfs.label}";
      fsType = "ext4";
      autoResize = false;
    };
  };
}
