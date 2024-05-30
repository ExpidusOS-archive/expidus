final: prev:
rec {
  flutterPackages = prev.callPackages ./development/compilers/flutter {};
  flutter = flutterPackages.stable;

  expidus = prev.expidus // (final.callPackages ./expidus {});
}
