{ lib, pkgs }:
pkgs.appimageTools.wrapType2 {
  pname = "cursor";
  version = "2.4.21";
  src = pkgs.fetchurl {
    #url = "https://downloads.cursor.com/production/45fd70f3fe72037444ba35c9e51ce86a1977ac11/linux/x64/Cursor-2.0.34-x86_64.AppImage";
    url = "https://downloads.cursor.com/production/80b138a7a0a948e1a798e9ed7867d76a1ba9a318/linux/x64/Cursor-3.3.27-x86_64.AppImage";
    sha256 = "sha256-xvPCp2Mx66Rmz3A1sxJXg/TnpDnjAIpDoEF6g6vcOtg=";
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

