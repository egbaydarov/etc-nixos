{ config, lib, pkgs, ... }:
let
  packages2505 = fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/25.05.tar.gz";
    sha256 = "1915r28xc4znrh2vf4rrjnxldw2imysz819gzhk9qlrkqanmfsxd";
  };
  pkgs2505 = import packages2505 {
    config.allowUnfree = true;
    config.chromium.enableWideVine = true;
  };
  packagesUnstable = fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/3c274c4258d70f3eff1a65379111e60aa43a09bc.tar.gz";
    sha256 = "0mrv3ydbq7chhkddb8v6pydq9z71abp9bxwggn6v08m622vzsqnj";
  };
  pkgsUnstable = import packagesUnstable {
    config.allowUnfree = true;
    config.chromium.enableWideVine = true;
  };
in
{
  imports =
    [
      ./hardware-configuration-legion.nix
    ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.gc = {
    automatic = true;
    persistent = true;
    dates = "05:00:00";
    options = "--delete-older-than 7d";
  };
  services.upower.enable = true;
  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = [ "*" ];
        settings = {
          main = {
            capslock = "backspace";
            "leftmeta+leftshift+f23" = "rightmeta";
            "102nd" = "leftshift";
          };
        };
      };
    };
  };
  boot.kernelParams = [ "vt.global_cursor_default=0" "consoleblank=0" "amdgpu.sg_display=0" ];

  boot.kernelPackages = pkgs2505.linuxPackages_latest;
  #boot.kernelPackages = pkgs.linuxPackages_6_15;
  #boot.kernelPackages = pkgs2505.linuxPackagesFor (pkgs2505.linux_6_14.override {
  #  argsOverride = rec {
  #      src = pkgs.fetchurl {
  #            url = "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.14.8.tar.xz";
  #            sha256 = "sha256-YrEuzTB1o1frMgk1ZX3oTgFVKANxfa04P6fMOqSqKQU=";
  #      };
  #      version = "6.14.8";
  #      modDirVersion = "6.14.8";
  #    };
  #});
  services.pcscd.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  services.logind = {
      settings = {
        Login = {
          HandleLidSwitchDocked = "ignore";
          HandleLidSwitchExternalPower = "ignore";
          HandleLidSwitch = "ignore";
          ExtraConfig = ''
              IdleAction=ignore
              HandlePowerKey=ignore
              HandleSuspendKey=ignore
          '';
        };
      };
  };
  time.timeZone = "Europe/Belgrade";

  programs.hyprland.enable = true;
  programs.xwayland.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = null;

  i18n.defaultLocale = "en_US.UTF-8";

  fonts.packages = with pkgs2505; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.zed-mono
  ];
  environment.sessionVariables = {
    # forces wayland in some apps (Electron, Chrome)
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    __NV_PRIME_RENDER_OFFLOAD = "1";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };

  environment.systemPackages =
  let
    zen-browser = (import (builtins.fetchTarball "https://github.com/youwen5/zen-browser-flake/archive/master.tar.gz") {
      pkgs = pkgs2505;
    }).default;
  in
  [
    pkgs2505.go
    pkgs2505.gopls
    pkgs2505.nodejs_20
    (import ./cursor.nix { 
      pkgs = pkgs2505;
      lib  = pkgs2505.lib;
    })
    zen-browser
    pkgs2505.clang-tools
    pkgs2505.yubikey-manager
    pkgs2505.yubioath-flutter

    pkgs2505.clang
    pkgs2505.cmake
    pkgs2505.git
    pkgs2505.lm_sensors
    pkgs2505.brightnessctl
    pkgs2505.wpa_supplicant
    pkgs2505.fuzzel
    pkgs2505.hyprpaper
    pkgs2505.mesa
    pkgs2505.gimp3

    pkgs2505.ripgrep
    pkgs2505.fd
    pkgs2505.fzf

    pkgs2505.hyprshot
    pkgs2505.pulseaudio
    pkgs2505.hyprcursor
    pkgs2505.waybar

    #gpg
    pkgs2505.pinentry-curses

    pkgs2505.fuzzel
    pkgs2505.wl-clipboard
    pkgsUnstable.wezterm
    pkgs2505.cliphist
    pkgs2505.mako
    pkgs2505.xcur2png
    pkgs2505.lua-language-server
  ];
  services.libinput.enable = true;
  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };
  programs.hyprlock.enable = true;
  security = {
    polkit.enable = true;
    pam.services.hyprlock = {};
  };
  security.rtkit.enable = true;
  services.gnome.gnome-keyring.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  nixpkgs.config.allowUnfree = true;
  users.users = {
    boogie = {
      isNormalUser = true;
      packages = with pkgs2505; [];
    };

    byda = {
      isNormalUser = true;
      packages = with pkgs2505; [];
    };
  };

  nix.extraOptions = ''
    extra-sandbox-paths = /var/cache/clickhouse-sccache
  '';

  specialisation = {

    boogie = {
      inheritParentConfig = true;
      configuration = {
        networking.extraHosts =
        ''
          127.0.0.1 kafka-1
          127.0.0.1 kafka-2
          127.0.0.1 kafka-3
          127.0.0.1 clickhouse-1-replica
          127.0.0.1 clickhouse-1
          127.0.0.1 clickhouse-2-replica
          127.0.0.1 clickhouse-2
          127.0.0.1 clickhouse-3-replica
          127.0.0.1 clickhouse-3
          127.0.0.1 clickhouse-zookeeper
        '';
        environment.systemPackages = [
          pkgsUnstable.chromium
          pkgs2505.jq
        ];
        virtualisation.docker = {
          rootless = {
            enable = true;
            setSocketVariable = true;
          };
          enable = true;
          daemon.settings = {
            data-root = "/home/boogie/.docker/data";
          };
        };
        system.nixos.tags = [ "boogie" ];
        networking.hostName = "nixos-boogie";
        networking.firewall = {
          enable = true;
          allowedUDPPorts = [ 8888 ];
          allowedTCPPorts = [ 5960 5961 5962 5963 5964 5965 5966 5966 5967 5968 5969 5970 8000 ];
          allowPing = true;
        };
        boot.extraModulePackages = with config.boot.kernelPackages; [
          (pkgs2505.callPackage ./ovpn-dco.nix { kernel = config.boot.kernelPackages.kernel; })
        ];
        boot.kernelModules = [ "ovpn-dco-v2" ];
        services.greetd = {
          enable = true;
          settings = rec {
            initial_session = {
              command = "Hyprland";
              user = "boogie";
            };
            default_session = initial_session;
          };
        };
        services.openvpn.servers = {
          intraVPN = {
            updateResolvConf = true;
            autoStart = true;
            config = ''
              config /etc/nixos/ovpn/intra.ovpn
              auth-user-pass /etc/nixos/ovpn/iamdumb.txt
            '';
          };
          projectsVPN = {
            updateResolvConf = true;
            autoStart = true;
            config = ''
              config /etc/nixos/ovpn/projects.ovpn
              auth-user-pass /etc/nixos/ovpn/iamdumb.txt
            '';
          };
          whiteVPN = {
            updateResolvConf = true;
            autoStart = false;
            config = ''
              config /etc/nixos/ovpn/white.ovpn
              auth-user-pass /etc/nixos/ovpn/iamdumb.txt
            '';
          };
        };
        users.extraGroups.docker.members = [ "boogie" ];
        security.sudo.extraRules = [
          {
            users = [ "boogie" ];
            commands = [{command = "ALL"; options = ["NOPASSWD"];}];
          }
        ];
        security.pki.certificateFiles = [
          /home/boogie/certs/OLANroot.crt
          /home/boogie/certs/RCA-CA.crt
          /home/boogie/certs/office-SUB-CA.crt
        ];
      };
    };

    byda = {
      inheritParentConfig = true;
      configuration = {
        virtualisation.docker = {
          rootless = {
            enable = true;
            setSocketVariable = true;
          };
          enable = true;
          daemon.settings = {
            data-root = "/home/byda/.docker/data";
          };
        };
        programs.obs-studio = {
          enable = true;
          plugins =  with pkgs.obs-studio-plugins; [
            distroav
            wlrobs
          ];
        };
        system.nixos.tags = [ "byda" ];
        environment.systemPackages = with pkgs2505; [
          v4l-utils
          firefox
        ];
        networking.hostName = "nixos-dude";
        networking.wg-quick.interfaces.wgokolo.configFile = "/etc/nixos/wg/okolo.conf";
        networking.wg-quick.interfaces.wgvisi.configFile = "/etc/nixos/wg/visi.conf";
        #networking.wg-quick.interfaces.wgru.configFile = "/etc/nixos/wg/fbru.conf";
        #networking.wg-quick.interfaces.wgus.configFile = "/etc/nixos/wg/us.conf";
        networking.firewall = {
          enable = true;
          allowedUDPPorts = [ 5960 5961 5962 5963 5964 5965 5966 5966 5967 5968 5969 5970 8000 ];
          allowedTCPPorts = [ 5960 5961 5962 5963 5964 5965 5966 5966 5967 5968 5969 5970 8000 ];
          allowPing = true;
        };
        services.avahi = {
          enable = true;
          nssmdns4 = true;
          publish.enable = true;
          publish.userServices = true;
        };
        services.pcscd.enable = true;
        services.greetd = {
          enable = true;
          settings = rec {
            initial_session = {
              command = "Hyprland";
              user = "byda";
            };
            default_session = initial_session;
          };
        };
        security.sudo.extraRules = [
          {
            users = [ "byda" ];
            commands = [{command = "ALL"; options = ["NOPASSWD"];}];
          }
        ];
      };
    };
  };

  networking.networkmanager.enable = true;
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
  system.stateVersion = "24.11";
}
