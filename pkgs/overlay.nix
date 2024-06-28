pkgs: prev: with pkgs;
rec {
  flutterPackages = flutterPackages-source;

  expidus = prev.expidus // (callPackages ./expidus {
    inherit flutter;
  });
}
