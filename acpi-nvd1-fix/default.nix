# Builds an uncompressed cpio archive containing an extra ACPI SSDT that the
# kernel installs at boot via the initrd "ACPI table upgrade" mechanism
# (https://docs.kernel.org/admin-guide/acpi/initrd_table_override.html).
#
# Use from configuration.nix:
#   boot.initrd.prepend = [ "${pkgs.callPackage ./acpi-nvd1-fix { }}/acpi-nvd1-fix.cpio" ];
{
  stdenvNoCC,
  acpica-tools,
  cpio,
}:

stdenvNoCC.mkDerivation {
  name = "acpi-nvd1-fix";
  src = ./ssdt-nvd1-fix.dsl;
  dontUnpack = true;

  nativeBuildInputs = [
    acpica-tools
    cpio
  ];

  buildPhase = ''
    runHook preBuild
    # -ve: only report errors/warnings; fail the build on any warning too.
    iasl -ve -we -p ssdt-nvd1-fix "$src"
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p kernel/firmware/acpi "$out"
    cp ssdt-nvd1-fix.aml kernel/firmware/acpi/ssdt-nvd1-fix.aml
    find kernel -exec touch -h -d @1 {} +
    # The kernel requires newc format, uncompressed, with files under kernel/firmware/acpi/
    printf '%s\n' kernel kernel/firmware kernel/firmware/acpi kernel/firmware/acpi/ssdt-nvd1-fix.aml \
      | cpio -o -H newc -R 0:0 --reproducible --quiet > "$out/acpi-nvd1-fix.cpio"
    runHook postInstall
  '';
}
