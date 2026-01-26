{ lib, pkgs }:
pkgs.appimageTools.wrapType2 {
  pname = "cursor";
  version = "2.4.21";
  src = pkgs.fetchurl {
    #url = "https://downloads.cursor.com/production/45fd70f3fe72037444ba35c9e51ce86a1977ac11/linux/x64/Cursor-2.0.34-x86_64.AppImage";
    url = "https://downloads.cursor.com/production/dc8361355d709f306d5159635a677a571b277bcc/linux/x64/Cursor-2.4.21-x86_64.AppImage";
    sha256 = "sha256-OOjANfVHMlRN1uWq2jNmK/RqI4Q5NTlN/19Nl2jWiKI=";
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

