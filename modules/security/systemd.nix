{ config, lib, ... }:
let
  gettyConfig = {
    serviceConfig = {
      ProtectSystem = "strict";
      ProtectKernelLogs = "true";
      ProtectProc = "invisible";
    };
  };
in
{
  config.systemd.services = {
    "getty@" = gettyConfig;
    "serial-getty@" = gettyConfig;
    "autovt@" = gettyConfig;
    "container-getty@" = gettyConfig;
    console-getty = gettyConfig;
  };
}
