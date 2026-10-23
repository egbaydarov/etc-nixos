/*
 * Fix for:
 *   ACPI BIOS Error (bug): Could not resolve symbol
 *   [\_SB.PCI0.GPP0.PEGP.GPS.NVD1], AE_NOT_FOUND
 *
 * Lenovo firmware bug: SSDT7 ("LENOVO" / "CB-01   ") declares
 *   External (NVD1, UnknownObj)
 * at root scope and reads NVD1 unqualified inside
 * \_SB.PCI0.GPP0.PEGP.GPS (GPS fun 19).  The object actually lives at
 *   \_SB.PCI0.LPC0.EC0.NVD1   (3-bit field in OperationRegion PECM, DSDT)
 * so the parent-scope walk PEGP -> GPP0 -> PCI0 -> _SB -> \ never finds it
 * and the whole PEGP._DSM is aborted.
 *
 * All firmware SSDTs on this machine share the same OEM ID / OEM Table ID,
 * so SSDT7 cannot be safely *replaced* via the initrd upgrade mechanism
 * (it would override the first matching SSDT instead).  Instead this table
 * uses a distinct OEM Table ID and is *added* by the kernel, and simply
 * aliases the real field into root scope so the lookup succeeds.
 */
DefinitionBlock ("", "SSDT", 2, "LENOVO", "NVD1FIX", 0x00000001)
{
    External (\_SB.PCI0.LPC0.EC0.NVD1, FieldUnitObj)

    Scope (\)
    {
        Alias (\_SB.PCI0.LPC0.EC0.NVD1, NVD1)
    }
}
