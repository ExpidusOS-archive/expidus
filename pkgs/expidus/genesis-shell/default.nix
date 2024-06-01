{
  stdenv,
  lib,
  flutter,
  fetchFromGitHub,
  pam,
  accountsservice,
  polkit,
  seatd,
  wlroots,
  libdrm,
  libGL,
  libxkbcommon,
  mesa,
  vulkan-loader,
  libdisplay-info,
  libliftoff,
  libinput,
  libepoxy,
  xorg
}:
flutter.buildFlutterApplication {
  pname = "genesis-shell";
  version = "0-unstable-2024-05-30";

  src = fetchFromGitHub {
    owner = "ExpidusOS";
    repo = "genesis";
    rev = "ce327bc7dcf3fd9556361ca703f3162cf88ae207";
    hash = "sha256-L4OnLcsD7ymUFSG0YVwP+xcowlDoucsyi8ZZe5nVlKo=";
  };

  pubspecLock = lib.importJSON ./pubspec.lock.json;

  buildInputs = lib.optionals (stdenv.isLinux) [
    pam accountsservice polkit seatd wlroots libdrm libGL libxkbcommon
    mesa vulkan-loader libdisplay-info libliftoff libinput xorg.xcbutilwm
    xorg.libX11 xorg.xcbutilerrors xorg.xcbutilimage xorg.xcbutilrenderutil
    libepoxy
  ];

  gitHashes = {
    libtokyo = "sha256-ei3bgEdmmWz0iwMUBzBndYPlvNiCrDBrG33/n8PrBPI=";
    libtokyo_flutter = "sha256-ei3bgEdmmWz0iwMUBzBndYPlvNiCrDBrG33/n8PrBPI=";
  };

  postInstall = ''
    mv $out/bin/genesis_shell $out/bin/genesis-shell
    mv $out/app/etc $out/etc
    mv $out/app/share $out/share
  '';

  meta = {
    description = "The modern desktop environment for everyone on anything";
    homepage = "https://expidusos.com";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ RossComputerGuy ];
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    mainProgram = "genesis-shell";
  };
}
