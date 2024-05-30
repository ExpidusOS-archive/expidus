{
  stdenv,
  lib,
  fetchFromGitHub,
  imagemagick
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "expidus-icons";
  version = "0-unstable-2024-05-29";

  src = fetchFromGitHub {
    owner = "ExpidusOS";
    repo = "artwork";
    rev = "de1fba2dae176264fbb22031799b7e163f35dc1b";
    hash = "sha256-vhCb8/25LMdrhBRy29lUl+/C7UZvJtTaxIRnFuKqomE=";
  };

  sourceRoot = "${finalAttrs.src.name}/icons";

  strictDeps = true;

  nativeBuildInputs = [
    imagemagick
  ];

  makeFlags = [
    "prefix=${placeholder "out"}"
  ];

  enableParallelBuilding = true;

  meta = with lib; {
    description = "Icons of the Nix logo, in Freedesktop Icon Directory Layout";
    homepage = "https://github.com/ExpidusOS/artwork";
    license = licenses.mit;
    maintainers = with maintainers; [ RossComputerGuy ];
    platforms = platforms.all;
  };
})
