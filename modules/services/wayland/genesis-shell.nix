{ config, lib, pkgs, options, ... }:
with lib;
let
  cfg = config.services.genesis-shell;
  tty = "tty${toString cfg.vt}";
  isMobileNixOS = options ? mobile;
in {
  options.services.genesis-shell = {
    enable = mkEnableOption "Genesis Shell";
    vt = mkOption {
      type = types.int;
      default = 1;
      description = ''
        The virtual console (tty) that greetd should use. This option also disables getty on that tty.
      '';
    };
  };

  config = mkIf cfg.enable {
    hardware.opengl.enable = mkDefault true;
    programs.feedbackd.enable = mkDefault true;

    security = {
      pam.services.genesis-shell = {
        allowNullPassword = true;
        startSession = true;
        enableGnomeKeyring = lib.mkDefault config.services.gnome.gnome-keyring.enable;
      };
      polkit.enable = mkDefault true;
    };

    services = {
      displayManager.enable = mkDefault true;
      accounts-daemon.enable = mkDefault true;
      upower.enable = mkDefault true;
    };

    users = {
      users.genesis-shell = {
        isSystemUser = true;
        uid = 198;
        group = "genesis-shell";
        extraGroups = [
          "dialout"
          "video"
          "wheel"
        ];
      };
      groups.genesis-shell = {
        gid = 198;
      };
    };

    systemd.services = {
      "autovt@${tty}".enable = false;
      genesis-shell = {
        aliases = [ "display-manager.service" ];

        unitConfig = {
          Wants = [
            "systemd-user-sessions.service"
          ];
          After = [
            "systemd-user-sessions.service"
            "getty@${tty}.service"
            "plymouth-quit-wait.service"
          ];
          Conflicts = [
            "getty@${tty}.service"
          ];
        };

        serviceConfig = {
          ExecStart = "${getExe pkgs.cage} -- ${getExe pkgs.expidus.genesis-shell} --display-manager";
          User = "genesis-shell";
          UtmpIdentifier = "%n";
          UtmpMode = "user";
          TTYPath = "/dev/${tty}";
          TTYReset = "yes";
          TTYVHangup = "yes";
          TTYVTDisallocate = "yes";
          StandardInput = "tty-fail";
          StandardOutput = "journal";
          StandardError = "journal";
          PAMName = "genesis-shell";
        };

        environment = mkIf (isMobileNixOS && config.mobile.device.name == "pine64-pinephone") {
          LIBGL_ALWAYS_SOFTWARE = "1";
        };

        restartIfChanged = false;
        wantedBy = [ "graphical.target" ];
      };
    };
  };

  meta.maintainers = with lib.maintainers; [ RossComputerGuy ];
}
