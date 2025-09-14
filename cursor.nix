{ lib, pkgs }:
pkgs.appimageTools.wrapType2 {
  pname = "cursor";
  version = "1.5.11";
  src = pkgs.fetchurl {
    url = "https://downloads.cursor.com/production/2f2737de9aa376933d975ae30290447c910fdf46/linux/x64/Cursor-1.5.11-x86_64.AppImage";
    sha256 = "sha256-PlZPgcDe6KmEcQYDk1R4uXh1R34mKuPLBh/wbOAYrAY=";
  };

  # Electron garbage
  extraPkgs = pkgs: with pkgs; [
    at-spi2-atk
    at-spi2-core
    dbus dbus-glib
    gsettings-desktop-schemas
    gtk3
    libdrm
    mesa
    libxkbcommon
    libsecret
    nspr
    nss
    zlib
    cups
    xorg.libX11
    xorg.libXext
    xorg.libXdamage
    xorg.libXtst
    xorg.libXScrnSaver
    xorg.libXcomposite
    xorg.libXfixes
    xorg.libxcb
    xorg.libXrandr
  ];

  meta = { mainProgram = "cursor"; };
}

