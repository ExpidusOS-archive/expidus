inputs:
{
  imports = [
    (import ./misc/version.nix inputs)
    (import ./misc/artwork inputs)
    ./services/wayland/genesis-shell.nix
    ./system/datafs.nix
  ];
}
