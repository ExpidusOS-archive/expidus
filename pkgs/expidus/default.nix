{ callPackage, wlroots_0_17 }:
{
  genesis-shell = callPackage ./genesis-shell {
    wlroots = wlroots_0_17;
  };

  icons = callPackage ./artwork/icons.nix {};
}
