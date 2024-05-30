{ config, lib, ... }:
with lib;
{
  config = mkMerge [
    (mkIf config.security.apparmor.enable {
      services.dbus.apparmor = mkForce "required";
    })
  ];
}
