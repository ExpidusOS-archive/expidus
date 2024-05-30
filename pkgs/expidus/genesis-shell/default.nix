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
    rev = "b5ccec5f4fb001c82308393c2cbf1614901a8a6b";
    hash = "sha256-EFGjdN+lvB3xQ+k32hjVFDLaiQHQuCda/r3b/O2/ZgE=";
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
