{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    "${builtins.fetchGit {url=https://github.com/NixOS/nixos-hardware.git;rev="9154f4569b6cdfd3c595851a6ba51bfaa472d9f3";}}/lenovo/legion/16aph8"
  ];

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.cpu.amd.updateMicrocode = lib.mkDefault true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
        FastConnectable = true;
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };

  boot.initrd.systemd.enable = true;
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-uuid/e60d8d5d-bae6-4687-8868-9b6f7274311c";
  boot.initrd.luks.devices."cryptroot".crypttabExtraOpts = [
      "fido2-device=auto"
  ];

  fileSystems."/" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [
      "subvol=@root"
      "compress=zstd:3"
      "noatime"
    ];
  };
  fileSystems."/efi" = {
    device = "/dev/disk/by-uuid/27C0-F16F";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/2C56-F529";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  swapDevices = [ ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}

