inputs:
{
  imports = [
    (import ./misc/version.nix inputs)
    ./services/wayland/genesis-shell.nix
    ./system/datafs.nix
  ];
}
