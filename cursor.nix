{ lib, pkgs }:
pkgs.appimageTools.wrapType2 {
  pname = "cursor";
  version = "3.14.7";
  src = pkgs.fetchurl {
    url = "https://downloads.cursor.com/production/a758f2241ca99fecf380180b6cbdbbce0f1f42cf/linux/x64/Cursor-3.14.7-x86_64.AppImage";
    sha256 = "sha256-+nvthb0R7tvAH9t1cd4BqIrcjq16Sy2VycLWovjB2wg=";
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

