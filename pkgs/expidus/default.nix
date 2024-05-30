{ callPackage, wlroots_0_17, flutter }:
{
  genesis-shell = callPackage ./genesis-shell {
    inherit flutter;
    wlroots = wlroots_0_17;
  };

  icons = callPackage ./artwork/icons.nix {};
}
