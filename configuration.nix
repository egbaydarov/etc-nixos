{ config, lib, pkgs, ... }:
let 
  masterSrc = fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/25.05.tar.gz";
    sha256 = "1915r28xc4znrh2vf4rrjnxldw2imysz819gzhk9qlrkqanmfsxd";
  };
  nixpkgsMaster = import masterSrc {
    config.allowUnfree = true;
  };
  yubico = pkgs.stdenv.mkDerivation {
    name = "authenticator";

    src = fetchTarball {
      url = "https://s3.byda.io/okolo-images/public-reads/yubico-authenticator-7.2.0-linux.tar.gz";
      sha256 = "10l3ixgnalm04jvx22qs9mmysqk2iq64vkkadlk3di2lhln8n6kw";
    };
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/bin
      cp -v authenticator $out/bin/
      chmod +x $out/bin/authenticator
    '';
  };
  twitchnotif = (pkgs.buildGoModule {
    name = "lf";
    src = pkgs.fetchFromGitHub {
      owner = "egbaydarov";
      repo = "twitch-notif-shit";
      rev = "master";
      sha256 = "0m2fzpqxk7hrbxsgqplkg7h2p7gv6s1miymv3gvw0cz039skag0s";
    };
    vendorHash = "sha256-DYReTxH4SHnJERbiE6rOp5XqzN3NRbICt5iNeX8Jgt8=";
  });
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
          };
        };
      };
    };
  };
  boot.kernelParams = [ "vt.global_cursor_default=0" "consoleblank=0" "amdgpu.sg_display=0" ];
  #boot.kernelPackages = pkgs.linuxPackages_6_15;
  boot.kernelPackages = nixpkgsMaster.linuxPackages_latest;
  #boot.kernelPackages = nixpkgsMaster.linuxPackagesFor (nixpkgsMaster.linux_6_14.override {
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
      lidSwitch = "ignore";
      lidSwitchDocked = "ignore";
      lidSwitchExternalPower = "ignore";
      extraConfig = ''
        IdleAction=ignore
        HandlePowerKey=ignore
        HandleSuspendKey=ignore
      '';
  };
  time.timeZone = "Europe/Belgrade";

  programs.hyprland.enable = true;
  programs.xwayland.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = null;

  i18n.defaultLocale = "en_US.UTF-8";

  fonts.packages = with nixpkgsMaster; [
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
  environment.systemPackages = [
    nixpkgsMaster.clang-tools
    nixpkgsMaster.clang
    nixpkgsMaster.cmake
    nixpkgsMaster.git
    nixpkgsMaster.lm_sensors
    nixpkgsMaster.brightnessctl
    nixpkgsMaster.fuzzel
    nixpkgsMaster.hyprpaper
    nixpkgsMaster.mesa
    nixpkgsMaster.gimp3

    nixpkgsMaster.hyprshot
    nixpkgsMaster.pulseaudio
    nixpkgsMaster.hyprcursor
    nixpkgsMaster.waybar

    #gpg
    nixpkgsMaster.pinentry-curses

    nixpkgsMaster.fuzzel
    nixpkgsMaster.wl-clipboard
    nixpkgsMaster.wezterm
    nixpkgsMaster.cliphist
    nixpkgsMaster.mako
    nixpkgsMaster.xcur2png
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
      packages = with nixpkgsMaster; [];
    };

    byda = {
      isNormalUser = true;
      packages = with nixpkgsMaster; [];
    };
  };

  specialisation = {

    boogie = {
      inheritParentConfig = true;
      configuration = {
        environment.systemPackages = with nixpkgsMaster; [
          chromium
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
        boot.extraModulePackages = with config.boot.kernelPackages; [
          (nixpkgsMaster.callPackage ./ovpn-dco.nix { kernel = config.boot.kernelPackages.kernel; })
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
            autoStart = true;
            config = ''
              config /home/boogie/openvpn/intra.ovpn
              auth-user-pass /home/boogie/openvpn/iamdumb.txt
            '';
            updateResolvConf = true;
          };
          projectsVPN = {
            autoStart = true;
            config = ''
              config /home/boogie/openvpn/projects.ovpn
              auth-user-pass /home/boogie/openvpn/iamdumb.txt
            '';
            updateResolvConf = true;
          };
          whiteVPN = {
            autoStart = true;
            config = ''
              config /home/boogie/openvpn/white.ovpn
              auth-user-pass /home/boogie/openvpn/iamdumb.txt
            '';
            updateResolvConf = true;
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
          /home/boogie/certs/OLANrootCA
          /home/boogie/certs/OLANroot.crt
          /home/boogie/certs/RCA-CA
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
            obs-ndi
            wlrobs
          ];
        };
        system.nixos.tags = [ "byda" ];
        environment.systemPackages = with nixpkgsMaster; [
          yubico
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

  # networking.networkmanager.enable = true;
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
