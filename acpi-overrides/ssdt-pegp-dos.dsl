/*
 * Stub _DOS on NVIDIA PEGP so Linux acpi_video stops warning:
 *   ACPI: video: [Firmware Bug]: ACPI(PEGP) defines _DOD but not _DOS
 *
 * Firmware SSDT7 defines PEGP._DOD but omits _DOS. The iGPU path
 * (\_SB.PCI0.GP17.VGA) already has a matching no-op _DOS that stores Arg0.
 * This extra SSDT (unique OEM Table ID) is *installed* by the initrd
 * upgrade path — it does not replace SSDT7.
 */
DefinitionBlock ("", "SSDT", 2, "LENOVO", "PEGPDOS ", 0x00000001)
{
    External (\_SB.PCI0.GPP0.PEGP, DeviceObj)

    Scope (\_SB.PCI0.GPP0.PEGP)
    {
        Name (DOSA, Zero)
        Method (_DOS, 1, NotSerialized)  // _DOS: Disable Output Switching
        {
            DOSA = Arg0
        }
    }
}
