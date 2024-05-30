final: prev:
rec {
  dart = prev.callPackage ./development/compilers/dart {};

  flutterPackages = prev.callPackages ./development/compilers/flutter {
    inherit dart;
  };

  flutter = flutterPackages.stable;

  expidus = prev.expidus // (final.callPackages ./expidus {});
}
