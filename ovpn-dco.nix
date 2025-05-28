{ lib, stdenv, fetchFromGitHub, kernel, kmod }:

stdenv.mkDerivation rec {
  pname = "ovpn-dco";
  version = "0.2.20241216";

  src = fetchFromGitHub {
    owner = "OpenVPN";
    repo = "ovpn-dco";
    rev = "v${version}";
    sha256 = "sha256-Ifgo9dDNgjMxO6LQBSLuz2kWhP8cOkbdbWTHDuMVLzI=";
  };

  nativeBuildInputs = kernel.moduleBuildDependencies;

  buildPhase = ''
    make KERNEL_SRC=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build
  '';

  installPhase = ''
    mkdir -p $out/lib/modules/${kernel.modDirVersion}/updates
    cp drivers/net/ovpn-dco/ovpn-dco-v2.ko $out/lib/modules/${kernel.modDirVersion}/updates/
  '';

  meta = with lib; {
    description = "OpenVPN Data Channel Offload kernel module";
    longDescription = ''
     This kernel module allows OpenVPN to offload any data plane management to the
     linux kernel, thus allowing it to exploit any Linux low level API, while avoiding
     expensive and slow payload transfer between kernel space and user space.
    '';
    homepage = "https://github.com/OpenVPN/ovpn-dco";
    license = licenses.gpl2;
    platforms = platforms.linux;
    maintainers = with maintainers; [ ];
  };
}

