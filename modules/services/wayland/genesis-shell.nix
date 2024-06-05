{ config, lib, pkgs, options, ... }:
with lib;
let
  cfg = config.services.genesis-shell;
  tty = "tty${toString cfg.vt}";
  isMobileNixOS = options ? mobile;

  commandArgs = optional cfg.displayManager "--display-manager";
in {
  options.services.genesis-shell = {
    enable = mkEnableOption "Genesis Shell";
    package = mkOption {
      type = types.package;
      defaultText = literalExpression "pkgs.expidus.genesis-shell";
      description = ''
        The package used for Genesis Shell
      '';
    };
    vt = mkOption {
      type = types.int;
      default = 1;
      description = ''
        The virtual console (tty) that greetd should use. This option also disables getty on that tty.
      '';
    };
    displayManager = (mkEnableOption "Genesis Shell's display manager") // { default = true; };
    user = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        The user to run Genesis Shell as, only has an effect when the display manager option is disabled.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.displayManager -> cfg.user != null;
        message = "Cannot run Genesis Shell as a specific user without disabling the display manager feature.";
      }
      {
        assertion = cfg.displayManager -> cfg.user == null;
        message = "When running Genesis Shell with the display manager feature disabled, a user must be specified.";
      }
    ];

    hardware = {
      opengl.enable = mkDefault true;
      sensor.iio.enable = mkDefault true;
    };

    programs.feedbackd.enable = mkDefault true;

    security = {
      pam.services.genesis-shell = {
        allowNullPassword = true;
        startSession = true;
        makeHomeDir = true;
        setEnvironment = true;
        enableAppArmor = config.security.apparmor.enable;
        enableGnomeKeyring = lib.mkDefault config.services.gnome.gnome-keyring.enable;
      };
      polkit.enable = mkDefault true;
    };

    services = {
      genesis-shell.package = mkDefault pkgs.expidus.genesis-shell;
      dbus.packages = [ cfg.package ];
      displayManager.enable = mkDefault true;
      accounts-daemon.enable = mkDefault true;
      homed.enable = mkDefault true;
      upower.enable = mkDefault true;
    };

    users = mkIf (!cfg.displayManager) {
      users.genesis-shell = {
        isSystemUser = true;
        uid = 198;
        group = "genesis-shell";
        extraGroups = [
          "dialout"
          "video"
          "wheel"
          "shadow"
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
          ExecStart = "${getExe pkgs.cage} -- ${getExe cfg.package} ${concatStringsSep " " commandArgs}";
          Type = "simple";
          User = if cfg.displayManager then "genesis-shell" else cfg.user;
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
          Restart = "on-failure";
          AmbientCapabilities = "CAP_AUDIT_CONTROL";
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
