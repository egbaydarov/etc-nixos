{ config, lib, pkgs, ... }:
let
  packagesStable = fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/25.11.tar.gz";
    sha256 = "1zn1lsafn62sz6azx6j735fh4vwwghj8cc9x91g5sx2nrg23ap9k";
  };
  pkgsStable = import packagesStable {
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
      "${builtins.fetchTarball "https://github.com/ryantm/agenix/archive/fcdea223397448d35d9b31f798479227e80183f6.tar.gz"}/modules/age.nix"
    ];

  age = {
    identityPaths = [ 
      "/root/.ssh/id_ed25519"
    ];
    secrets = {
      ovpnpass = {
        file = /root/ovpnpass.age;
      };
      wgokolo = {
        file = /root/wgokolo.age;
      };
      wgvisi = {
        file = /root/wgvisi.age;
      };
      ivpn = {
        file = /root/i.age;
      };
      pvpn = {
        file = /root/p.age;
      };
      whvpn = {
        file = /root/wh.age;
      };
      u2f_keys = {
        file = /root/u2f_keys.age;
      };
    };
  };

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
  boot.kernelParams = [ "amdgpu.sg_display=1" ];

  boot.kernelPackages = pkgsStable.linuxPackages_latest;
  #boot.kernelPackages = pkgsStable.linuxPackages_6_18;

  # way to use custom kernel
  #boot.kernelPackages = pkgsStable.linuxPackagesFor (pkgsStable.linux_6_14.override {
  #  argsOverride = rec {
  #      src = pkgs.fetchurl {
  #            url = "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.18.tar.xz";
  #            sha256 = "sha256-kQakYF2p4x/xdlnZWHgrgV+VkaswjQOw7iGq1sfc7Us=";
  #      };
  #      version = "6.18.0";
  #      structuredExtraConfig = with pkgs.lib; with pkgs.lib.kernel; {
  #        BCACHEFS_POSIX_ACL = mkForce unset;
  #        ZPOOL = mkForce unset;
  #      };
  #      modDirVersion = "6.18.0";
  #    };
  #});

  services.pcscd.enable = true;
  services.udev.extraRules = ''
    # Match via vendor/product attributes
    KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0ce6", TAG+="uaccess", MODE="0660"
  
    # Match via parent kernel device string
    KERNEL=="hidraw*", KERNELS=="*054C:0CE6*", TAG+="uaccess", MODE="0660"
  '';
  services.udev.packages = [ pkgsStable.yubikey-personalization ];
  services.yubikey-agent.enable = true;
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

  fonts.packages = with pkgsStable; [
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

  xdg.mime = {
    enable = true;
    defaultApplications = {
      # Folders → kitty + nvim
      "inode/directory" = "kitty.desktop";
      # All other zen
      "x-scheme-handler/http"     = "zen.desktop";
      "x-scheme-handler/https"    = "zen.desktop";
      "x-scheme-handler/ssh"      = "zen.desktop";
      "application/xhtml+xml"     = "zen.desktop";
      "application/x-sh"          = "zen.desktop";
      "application/x-shellscript" = "zen.desktop";
      "text/*"                    = "zen.desktop";
      "image/*"                   = "gimp.desktop";
    };
  };


  environment.systemPackages =
  let
    zen-browser = (import (builtins.fetchTarball "https://github.com/egbaydarov/zen-browser-flake/archive/master.tar.gz") {
      pkgs = pkgsStable;
    }).default;
  in
  [
    pkgsStable.go
    pkgsStable.yq
    pkgsStable.jq
    pkgsStable.python3
    pkgsStable.grpcurl
    pkgsStable.gopls
    pkgsStable.mongodb-compass
    pkgsStable.lens
    pkgsStable.nodejs_20
    (import ./easy-dotnet.nix {
      buildDotnetGlobalTool = pkgsStable.buildDotnetGlobalTool;
      dotnetCorePackages = pkgsStable.dotnetCorePackages;
      lib  = pkgsStable.lib;
    })
    (import ./cursor.nix { 
      pkgs = pkgsStable;
      lib  = pkgsStable.lib;
    })
    (pkgs.callPackage "${builtins.fetchTarball "https://github.com/ryantm/agenix/archive/fcdea223397448d35d9b31f798479227e80183f6.tar.gz"}/pkgs/agenix.nix" {})
    zen-browser
    pkgsStable.clang-tools
    pkgsStable.yubikey-manager
    pkgsStable.yubioath-flutter
    pkgsStable.pam_u2f
    pkgsStable.sshfs

    pkgsStable.clang
    pkgsStable.cmake
    pkgsStable.git
    pkgsStable.lm_sensors
    pkgsStable.brightnessctl
    pkgsStable.wpa_supplicant
    pkgsStable.fuzzel
    pkgsStable.hyprpaper
    pkgsStable.mesa
    pkgsStable.gimp3
    pkgsStable.droidcam

    pkgsStable.ripgrep
    pkgsStable.fd
    pkgsStable.fzf

    pkgsStable.hyprshot
    pkgsStable.pulseaudio
    pkgsStable.hyprcursor
    pkgsStable.waybar

    #gpg
    pkgsStable.pinentry-curses
    pkgsStable.fuzzel
    (pkgsStable.wtype.overrideAttrs (old: {
      src = pkgsStable.fetchFromGitHub {
        owner = "atx";
        repo = "wtype";
        rev = "v0.4";
        hash = "sha256-TfpzAi0mkXugQn70MISyNFOXIJpDwvgh3enGv0Xq8S4=";
      };
    }))
    pkgsStable.wtype
    pkgsStable.wl-clipboard
    pkgsStable.hyprpolkitagent
    pkgsStable.kitty
    pkgsStable.foot
    pkgsStable.tmux
    pkgsStable.cliphist
    pkgsStable.mako
    pkgsStable.xcur2png
    pkgsStable.keepassxc
    pkgsStable.lua-language-server
  ];

  # for yubi
  hardware.gpgSmartcards.enable = true;
  services.libinput.enable = true;
  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };
  programs.hyprlock.enable = true;
  security = {
    polkit.enable = true;
    pam = {
      u2f = {
        control = "sufficient";
        #control = "required";
        enable = true;
        settings = {
          pinverification = 1;
          #debug = true;
          authfile = config.age.secrets.u2f_keys.path;
          userpresence = 1;
          cue = true;
        };
      };
      services = {
        login = { u2fAuth = true; unixAuth = false; };
        sudo = { u2fAuth = true; unixAuth = false; };
        su   = { u2fAuth = true; unixAuth = false; };
        "polkit-1" = { u2fAuth = true; unixAuth = false; };
        hyprlock = {};
      };
    };
  };
  environment.shellAliases = {
    root = "pkexec bash -l";
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
      packages = with pkgsStable; [];
    };

    byda = {
      isNormalUser = true;
      packages = with pkgsStable; [];
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
        virtualisation.docker = {
          rootless = {
            enable = true;
            setSocketVariable = true;
            daemon.settings = {
             data-root = "/home/boogie/.docker/data";
            };
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
          #(pkgsStable.callPackage ./ovpn-dco.nix { kernel = config.boot.kernelPackages.kernel; })
          v4l2loopback
        ];
        boot.kernelModules = [ 
          "ovpn-dco-v2"
          "v4l2loopback"
        ];
        boot.extraModprobeConfig = ''
          # exclusive_caps: will only show device when actually streaming
          # card_label: Name of virtual camera, how it'll show up in Zoom, Teams
          # https://github.com/umlaeute/v4l2loopback
          options v4l2loopback exclusive_caps=1 card_label="Network Cam"
        '';
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
          iVPN = {
            updateResolvConf = true;
            autoStart = true;
            config = ''
              config ${config.age.secrets.ivpn.path}
              auth-user-pass ${config.age.secrets.ovpnpass.path}
            '';
          };
          pVPN = {
            updateResolvConf = true;
            autoStart = true;
            config = ''
              config ${config.age.secrets.pvpn.path}
              auth-user-pass ${config.age.secrets.ovpnpass.path}
            '';
          };
          whVPN = {
            updateResolvConf = true;
            autoStart = false;
            config = ''
              config ${config.age.secrets.whvpn.path}
              auth-user-pass ${config.age.secrets.ovpnpass.path}
            '';
          };
        };
        users.extraGroups.docker.members = [ "boogie" ];
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
            daemon.settings = {
              data-root = "/home/byda/.docker/data";
            };
          };
        };
        programs.obs-studio = {
          enable = true;
          plugins =  with pkgs.obs-studio-plugins; [
            distroav
            wlrobs
          ];
        };
        boot.extraModulePackages = with config.boot.kernelPackages; [
          v4l2loopback
        ];
        boot.kernelModules = [ 
          "v4l2loopback"
        ];
          boot.extraModprobeConfig = ''
          # exclusive_caps: will only show device when actually streaming
          # card_label: Name of virtual camera, how it'll show up in Zoom, Teams
          # https://github.com/umlaeute/v4l2loopback
          options v4l2loopback exclusive_caps=1 card_label="Network Cam"
        '';

        systemd.services."wg-quick-wgvisi".wantedBy = lib.mkForce [ ];
        system.nixos.tags = [ "byda" ];
        environment.systemPackages = with pkgsStable; [
          v4l-utils
          steam
        ];
        networking.hostName = "nixos-dude";
        networking.wg-quick.interfaces.wgokolo.configFile = config.age.secrets.wgokolo.path;
        networking.wg-quick.interfaces.wgvisi.configFile = config.age.secrets.wgvisi.path;
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
