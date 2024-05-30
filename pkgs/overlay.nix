final: prev:
rec {
  flutterPackages = prev.recurseIntoAttrs (prev.callPackage ./development/compilers/flutter {});
  flutter = flutterPackages.stable;
  flutter322 = flutterPackages.v3_22;
  flutter319 = flutterPackages.v3_19;
  flutter316 = flutterPackages.v3_16;
  flutter313 = flutterPackages.v3_13;

  expidus = prev.expidus.override {
    inherit (final.buildPackages) flutterPackages;
  } // (final.callPackages ./expidus {
    inherit (final.buildPackages) flutter;
  });
}
