{ lib, pkgs }:

let
  inherit (pkgs.stdenv) hostPlatform;

  sources = {
    x86_64-linux = pkgs.fetchurl {
      url = "https://downloads.cursor.com/lab/2026.09.02-c22c1a3/linux/x64/agent-cli-package.tar.gz";
      hash = "sha256-tztZhUdiU1wPwg18zFHDtaNWqFFJEIjWCjYr5IdQ9Tw=";
    };
  };
in

pkgs.stdenv.mkDerivation {
  pname = "cursor-cli";
  version = "0-unstable-2026-08-11";

  src = sources.${hostPlatform.system};

  buildInputs = lib.optionals hostPlatform.isLinux [
    pkgs.zlib
  ];

  nativeBuildInputs = lib.optionals hostPlatform.isLinux [
    pkgs.autoPatchelfHook
    pkgs.stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mkdir -p $out/share/cursor-agent

    cp -r * $out/share/cursor-agent/

    ln -s \
      $out/share/cursor-agent/cursor-agent \
      $out/bin/cursor-agent

    runHook postInstall
  '';

  meta = {
    description = "Cursor CLI";
    homepage = "https://cursor.com/cli";
    license = lib.licenses.unfree;

    platforms = builtins.attrNames sources;
    mainProgram = "cursor-agent";

    sourceProvenance = with lib.sourceTypes; [
      binaryNativeCode
    ];
  };
}
