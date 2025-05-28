{ config, lib, pkgs, ... }:
let 
  masterSrc = fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/master.tar.gz";
    sha256 = "1d1by1zy2jy0yi3kdj4a224ar2cv4s9sjssbv024rdlrjd3lc05p";
  };
  nixpkgsMaster = import masterSrc {
    config.allowUnfree = true;
  };
in
{
  imports =
    [
      ./hardware-configuration-legion.nix
    ];
  nix.gc = {
    automatic = true;
    persistent = true;
    dates = "05:00:00";
    options = "--delete-older-than 7d";
  };
  #boot.kernelPackages = pkgs.linuxPackages_6_12;
  #boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelPackages = nixpkgsMaster.linuxPackagesFor (nixpkgsMaster.linux_6_14.override {
    argsOverride = rec {
      src = pkgs.fetchurl {
            url = "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.14.8.tar.xz";
            sha256 = "sha256-YrEuzTB1o1frMgk1ZX3oTgFVKANxfa04P6fMOqSqKQU=";
      };
      version = "6.14.8";
      modDirVersion = "6.14.8";
      };
  });

  hardware.graphics.enable = true;
  hardware.graphics.extraPackages = [ pkgs.mesa.drivers ];
  time.timeZone = "Europe/Belgrade";

  programs.hyprland.enable = true;
  programs.xwayland.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = null;

  i18n.defaultLocale = "en_US.UTF-8";
  services.logind.lidSwitchExternalPower = "ignore";

  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" "FiraCode" "ZedMono" ]; })
  ];
  environment.systemPackages = [
    pkgs.clang-tools
    pkgs.clang
    pkgs.cmake
    pkgs.git
    pkgs.lm_sensors
    pkgs.brightnessctl
    pkgs.fuzzel
    pkgs.wl-clipboard
    pkgs.hyprpaper
    pkgs.pulseaudio

    nixpkgsMaster.fuzzel
    nixpkgsMaster.wl-clipboard
    nixpkgsMaster.hyprshot
    nixpkgsMaster.wezterm
    nixpkgsMaster.chromium
    nixpkgsMaster.cliphist
    nixpkgsMaster.hyprcursor
    nixpkgsMaster.mako
    nixpkgsMaster.xcur2png
  ];
  services.libinput.enable = true;
  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  nixpkgs.config.allowUnfree = true;

  specialisation = {
    mancala = {
      inheritParentConfig = true;
      configuration = {
        system.nixos.tags = [ "mancala" ];
        networking.hostName = "nixos-mancala";
        boot.extraModulePackages = with config.boot.kernelPackages; [
          (nixpkgsMaster.callPackage ./ovpn-dco.nix { kernel = config.boot.kernelPackages.kernel; })
        ];
        boot.kernelModules = [ "ovpn-dco-v2" ];
        services.openvpn.servers = {
          intraVPN = {
            autoStart = true;
            config = ''
              config /home/mancala/mancala/openvpn/intra.ovpn
              auth-user-pass /home/mancala/mancala/openvpn/iamdumb.txt
            '';
            updateResolvConf = true;
          };
          projectsVPN = {
            autoStart = true;
            config = ''
              config /home/mancala/mancala/openvpn/projects.ovpn
              auth-user-pass /home/mancala/mancala/openvpn/iamdumb.txt
            '';
            updateResolvConf = true;
          };
          whiteVPN = {
            autoStart = true;
            config = ''
              config /home/mancala/mancala/openvpn/white.ovpn
              auth-user-pass /home/mancala/mancala/openvpn/iamdumb.txt
            '';
            updateResolvConf = true;
          };
        };
        security.sudo.extraRules = [
          {
            users = [ "mancala" ];
            commands = [{command = "ALL"; options = ["NOPASSWD"];}];
          }
        ];
        users.users.mancala = {
          isNormalUser = true;
          packages = with pkgs; [];
        };
        security.pki.certificateFiles = [
          /home/mancala/mancala/certs/OLANrootCA
          /home/mancala/mancala/certs/OLANroot.crt
          /home/mancala/mancala/certs/RCA-CA
          /home/mancala/mancala/certs/RCA-CA.crt
          /home/mancala/mancala/certs/office-SUB-CA.crt
        ];
      };
    };


    byda_streamer = {
      inheritParentConfig = true;
      configuration = {
        system.nixos.tags = [ "byda" ];
        networking.hostName = "nixos-dude";
        security.sudo.extraRules = [
          {
            users = [ "byda" ];
            commands = [{command = "ALL"; options = ["NOPASSWD"];}];
          }
        ];
        users.users.byda = {
          isNormalUser = true;
          packages = with pkgs; [];
        };
      };
    };
  };


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?
}
