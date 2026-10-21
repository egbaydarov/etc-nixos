{ config, lib, pkgs, modulesPath, ... }:
let
  unstable = import <nixos-unstable> {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    #"${builtins.fetchGit {url=https://github.com/NixOS/nixos-hardware.git;rev="9154f4569b6cdfd3c595851a6ba51bfaa472d9f3";}}/lenovo/legion/16aph8"
  ];

  hardware.cpu.amd.updateMicrocode = true;
  boot.kernelParams = [
    "amd_pstate=active"
    "amdgpu.sg_display=1"
  ];

  # AMD GPU
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  hardware.amdgpu.initrd.enable = true;

  # NVIDIA GPU
  hardware.nvidia = {
    package = (unstable.linuxPackagesFor config.boot.kernelPackages.kernel).nvidiaPackages.stable;

    dynamicBoost.enable = true;
    modesetting.enable = true;

    powerManagement = {
      enable = false;
      finegrained = false;
    };

    open = false;

    prime = {
      sync.enable = true;
      amdgpuBusId = "PCI:5:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  # Laptop power management
  services.power-profiles-daemon.enable = true;
  services.tlp.enable = false;

  # SSD
  services.fstrim.enable = true;

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

