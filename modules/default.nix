inputs:
{
  imports = [
    (import ./misc/version.nix inputs)
    (import ./misc/artwork inputs)
    ./security/apparmor.nix
    ./security/systemd.nix
    ./services/wayland/genesis-shell.nix
    ./system/datafs.nix
    ./system/users.nix
  ];
}
