{ callPackage, fetchzip, fetchFromGitHub, dart, lib, stdenv, targetPackages, pkgs }:
let
  mkCustomFlutter = args: callPackage "${pkgs.path}/pkgs/development/compilers/flutter/flutter.nix" args;
  wrapFlutter = flutter: callPackage "${pkgs.path}/pkgs/development/compilers/flutter/wrapper.nix" {
    inherit flutter;
    inherit (targetPackages) atk cairo harfbuzz libepoxy pango libdeflate zlib;
  };
  getPatches = dir:
    let files = builtins.attrNames (builtins.readDir dir);
    in if (builtins.pathExists dir) then map (f: dir + ("/" + f)) files else [ ];
  mkFlutter =
    { version
    , engineVersion
    , dartVersion
    , flutterHash
    , dartHash
    , patches
    , pubspecLock
    , artifactHashes
    }:
    let
      args = {
        inherit version engineVersion patches pubspecLock artifactHashes;

        dart = dart.override {
          version = dartVersion;
          sources = {
            "${dartVersion}-x86_64-linux" = fetchzip {
              url = "https://storage.googleapis.com/dart-archive/channels/stable/release/${dartVersion}/sdk/dartsdk-linux-x64-release.zip";
              sha256 = dartHash.x86_64-linux;
            };
            "${dartVersion}-aarch64-linux" = fetchzip {
              url = "https://storage.googleapis.com/dart-archive/channels/stable/release/${dartVersion}/sdk/dartsdk-linux-arm64-release.zip";
              sha256 = dartHash.aarch64-linux;
            };
            "${dartVersion}-x86_64-darwin" = fetchzip {
              url = "https://storage.googleapis.com/dart-archive/channels/stable/release/${dartVersion}/sdk/dartsdk-macos-x64-release.zip";
              sha256 = dartHash.x86_64-darwin;
            };
            "${dartVersion}-aarch64-darwin" = fetchzip {
              url = "https://storage.googleapis.com/dart-archive/channels/stable/release/${dartVersion}/sdk/dartsdk-macos-arm64-release.zip";
              sha256 = dartHash.aarch64-darwin;
            };
          };
        };
        src = fetchFromGitHub {
          owner = "flutter";
          repo = "flutter";
          rev = version;
          hash = flutterHash;
        };
      };
    in
    (mkCustomFlutter args).overrideAttrs (prev: next: {
      passthru = next.passthru // rec {
        inherit wrapFlutter mkCustomFlutter mkFlutter;
        buildFlutterApplication = callPackage ../../../build-support/flutter {
          flutter = wrapFlutter (mkCustomFlutter args);
          inherit (targetPackages) glib;
        };
      };
    });

  flutterVersions = lib.mapAttrs'
    (version: _:
      let
        versionDir = "${pkgs.path}/pkgs/development/compilers/flutter/versions/${version}";
        data = lib.importJSON (versionDir + "/data.json");
      in
      lib.nameValuePair "v${version}" (wrapFlutter (mkFlutter ({
        patches = (getPatches "${pkgs.path}/pkgs/development/compilers/flutter/patches") ++ (getPatches (versionDir + "/patches"));
      } // data))))
    (builtins.readDir "${pkgs.path}/pkgs/development/compilers/flutter/versions");
in
flutterVersions // {
  stable = flutterVersions.${lib.last (lib.naturalSort (builtins.attrNames flutterVersions))};
  inherit wrapFlutter mkFlutter;
}
