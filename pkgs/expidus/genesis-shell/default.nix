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
  version = "0-unstable-2024-05-20";

  src = fetchFromGitHub {
    owner = "ExpidusOS";
    repo = "genesis";
    rev = "65df4ef1d2baadcb86a7f8b24802bda1e2d36195";
    hash = "sha256-nhmjxXSc6awW6wXZCuYpSD+caojUFA2Z424lGAyuFFo=";
  };

  pubspecLock = lib.importJSON ./pubspec.lock.json;

  buildInputs = lib.optionals (stdenv.isLinux) [
    pam accountsservice polkit seatd wlroots libdrm libGL libxkbcommon
    mesa vulkan-loader libdisplay-info libliftoff libinput xorg.xcbutilwm
    xorg.libX11 xorg.xcbutilerrors xorg.xcbutilimage xorg.xcbutilrenderutil
    libepoxy
  ];

  gitHashes = {
    libtokyo = "sha256-Zn30UmppXnzhs+t+EQNwAhaTPjCCxoN0a+AbH6bietg=";
    libtokyo_flutter = "sha256-Zn30UmppXnzhs+t+EQNwAhaTPjCCxoN0a+AbH6bietg=";
  };

  postInstall = ''
    mv $out/bin/genesis_shell $out/bin/genesis-shell
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
