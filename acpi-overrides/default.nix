# ACPI initrd overrides for Lenovo Legion:
#  1) SSDT1..SSDT18 passthrough + patched SSDT19 (OEM rev 2) so WLAN._DSM/_S0W
#     duplicates from firmware SSDT19 no longer collide with the DSDT.
#  2) Extra SSDT nvd1.aml (OEM Table ID NVD1FIX) aliasing EC0.NVD1 into root
#     scope for the PEGP.GPS AE_NOT_FOUND bug.
#  3) Extra SSDT pdos.aml (OEM Table ID PEGPDOS) stubbing PEGP._DOS so
#     acpi_video stops warning about _DOD without _DOS.
#
# Kernel matches overrides by signature+OEM ID+OEM Table ID and requires
# override oem_revision > firmware oem_revision. All Lenovo SSDTs share
# OEM Table ID "CB-01   ", so SSDT19 can only be replaced by overriding
# SSDT1..SSDT19 in XSDT order.
#
# Use from configuration.nix:
#   boot.initrd.prepend = [
#     "${pkgs.callPackage ./acpi-overrides { }}/acpi-overrides.cpio"
#   ];
{
  stdenvNoCC,
  acpica-tools,
  cpio,
  python3,
}:

stdenvNoCC.mkDerivation {
  name = "acpi-overrides";
  src = ./.;

  nativeBuildInputs = [
    acpica-tools
    cpio
    python3
  ];

  buildPhase = ''
    runHook preBuild
    mkdir -p outaml

    # Bump OEM revision on SSDT1..18 and fix ACPI checksum (sum of bytes == 0).
    python3 - <<'PY'
from pathlib import Path
import struct

def fix(data: bytes, rev: int) -> bytes:
    b = bytearray(data)
    struct.pack_into("<I", b, 24, rev)
    b[9] = 0
    b[9] = (-sum(b)) & 0xFF
    if sum(b) & 0xFF:
        raise SystemExit("checksum failed")
    return bytes(b)

for i in range(1, 19):
    src = Path(f"firmware/ssdt{i}.dat")
    dst = Path(f"outaml/ssdt{i:02d}.aml")
    data = fix(src.read_bytes(), 2)
    # basic header sanity
    assert data[0:4] == b"SSDT", src
    dst.write_bytes(data)
    print(f"prepared {dst} ({len(data)} bytes)")
PY

    # Patched SSDT19 (no WLAN._DSM / WLAN._S0W), OEM rev 2
    iasl -ve -we -p outaml/ssdt19 ./ssdt19-wlan-fix.dsl

    # NVD1 root-scope alias; short filename avoids MAX_CPIO_FILE_NAME warn
    iasl -ve -we -p outaml/nvd1 ./ssdt-nvd1-fix.dsl

    # PEGP._DOS stub (silences acpi_video firmware bug warning)
    iasl -ve -we -p outaml/pdos ./ssdt-pegp-dos.dsl

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p kernel/firmware/acpi "$out"

    # Order matters: find_cpio walks in archive order; first 19 SSDTs must
    # align with firmware XSDT SSDT1..SSDT19.
    for i in $(seq -w 1 19); do
      cp "outaml/ssdt$i.aml" "kernel/firmware/acpi/ssdt$i.aml"
    done
    # iasl may emit ssdt19.aml without zero-pad; normalize
    if [ ! -f kernel/firmware/acpi/ssdt19.aml ] && [ -f outaml/ssdt19.aml ]; then
      cp outaml/ssdt19.aml kernel/firmware/acpi/ssdt19.aml
    fi
    cp outaml/nvd1.aml kernel/firmware/acpi/nvd1.aml
    cp outaml/pdos.aml kernel/firmware/acpi/pdos.aml

    find kernel -exec touch -h -d @1 {} +

    {
      printf '%s\n' kernel kernel/firmware kernel/firmware/acpi
      for i in $(seq -w 1 19); do
        printf '%s\n' "kernel/firmware/acpi/ssdt$i.aml"
      done
      printf '%s\n' kernel/firmware/acpi/nvd1.aml
      printf '%s\n' kernel/firmware/acpi/pdos.aml
    } | cpio -o -H newc -R 0:0 --reproducible --quiet > "$out/acpi-overrides.cpio"

    runHook postInstall
  '';
}
