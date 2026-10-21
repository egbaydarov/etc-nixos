{ config, lib, pkgs, ... }:
let
  packagesStable = fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/26.05.tar.gz";
    sha256 = "0am8xx09fx5yf2p0wb001v0jx1g5hrfb76h4r37xph378jgk7pcr";
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

  #usb stick setup
  mountPoint = "/mnt/usb";
  usbSerial  = "001CC07CEB81BB21816E0013";
  usbGid = 989;
in
{
  imports =
    [
      ./hardware-configuration.nix
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
      wgru = {
        file = /root/wgru.age;
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
  services.nixseparatedebuginfod2.enable = true;
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
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  boot.kernelPackages = pkgsStable.linuxPackages_latest;
  # Extra SSDT working around Lenovo firmware bug:
  # \_SB.PCI0.GPP0.PEGP.GPS -> NVD1 AE_NOT_FOUND (aborts PEGP._DSM)
  boot.initrd.prepend = [
    "${pkgsStable.callPackage ./acpi-nvd1-fix { }}/acpi-nvd1-fix.cpio"
  ];

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
    # sony ds5
    KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0ce6", TAG+="uaccess", MODE="0660"
    KERNEL=="hidraw*", KERNELS=="*054C:0CE6*", TAG+="uaccess", MODE="0660"

    # thumbdrive
    ACTION=="add", SUBSYSTEM=="block", ENV{DEVTYPE}=="partition", ENV{ID_FS_TYPE}=="vfat", ENV{ID_SERIAL_SHORT}=="${usbSerial}", RUN{program}+="${pkgs.systemd}/bin/systemd-mount --no-block --collect --bind-device --options=rw,nosuid,nodev,noexec,uid=0,gid=${toString usbGid},dmask=007,fmask=117,utf8=1,shortname=mixed $devnode ${mountPoint}"
    ACTION=="remove", SUBSYSTEM=="block", ENV{DEVTYPE}=="partition", ENV{ID_SERIAL_SHORT}=="${usbSerial}", RUN{program}+="${pkgs.systemd}/bin/systemd-umount ${mountPoint}"
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
  boot.loader.efi.efiSysMountPoint = "/efi";
  boot.loader.systemd-boot.xbootldrMountPoint = "/boot";
  boot.loader.systemd-boot.editor = false;
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
    pkgsStable.bitwig-studio
    pkgsStable.go
    pkgsStable.yq
    pkgsStable.jq
    pkgsStable.python3
    pkgsStable.grpcurl
    pkgsStable.gopls
    pkgsStable.mongodb-compass
    pkgsStable.lens
    pkgsStable.nodejs
    (import ./cursor-cli.nix {
      pkgs = pkgsStable;
      lib = pkgsStable.lib;
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

    (pkgsStable.llm.withPlugins {
      llm-grok = true;
    })

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
    pkgsStable.wireshark
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

  systemd.services.set-platform-profile = {
    description = "Set ACPI platform profile to max-power";
  
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-settle.service" ];
  
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'echo max-power > /sys/firmware/acpi/platform_profile'";
    };
  };

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
  users.groups.cryptdata = { };
  users.groups.wireshark = { };
  security.wrappers.dumpcap = lib.mkIf true {
    source = "${pkgsStable.wireshark}/bin/dumpcap";
    capabilities = "cap_net_raw,cap_net_admin+eip";
    owner = "root";
    group = "wireshark";
    permissions = "u+rx,g+x";
  };
  users.groups.usbmnt = { gid = usbGid; };

  users.users = {
    boogie = {
      isNormalUser = true;
      extraGroups = [ "cryptdata" "usbmnt" ];
      packages = with pkgsStable; [];
    };

    byda = {
      isNormalUser = true;
      extraGroups = [ "cryptdata" "usbmnt" "wireshark"];
      packages = with pkgsStable; [];
    };
  };

  systemd.tmpfiles.rules = [
    "d /data 2770 root cryptdata - -"
    "d /mnt/usb 2775 root usbmnt - -"
  ];

  nix.extraOptions = ''
    extra-sandbox-paths = /var/cache/clickhouse-sccache
  '';

  system.nixos.tags = [ "root" ];

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
          allowedUDPPorts = [];
          allowedTCPPorts = [];
          allowPing = true;
        };
        boot.extraModulePackages = with config.boot.kernelPackages; [
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

          # Copy Fail / CVE-2026-31431
          install algif_aead ${pkgs.coreutils}/bin/false
         
          # Dirty Frag / CVE-2026-43284 + CVE-2026-43500
          install esp4 ${pkgs.coreutils}/bin/false
          install esp6 ${pkgs.coreutils}/bin/false
          install rxrpc ${pkgs.coreutils}/bin/false
        '';

        boot.blacklistedKernelModules = [
          "algif_aead"
          "esp4"
          "esp6"
          "rxrpc"
        ];

        services.greetd = {
          enable = true;
          settings = rec {
            initial_session = {
              command = "start-hyprland";
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
      };
    };

    byda = {
     inheritParentConfig = true;
     configuration = {
       #imports = [
       #  (builtins.getFlake "path:/home/byda/stuff/fluxcast").nixosModules.fluxcast
       #];
       #programs.fluxcast = {
       #  enable = true;
       #  users = [ "byda" ];
       #          openFirewall = true;    # trusts the p2p-+ Wi-Fi Direct interface
       #  rawSupplicant = true;   # optional: --wfd-p2p-backend wpas (TV as group owner)
       #};

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

        systemd.services."wg-quick-wgru".wantedBy = lib.mkForce [ ];
        system.nixos.tags = [ "byda" ];
        environment.systemPackages = with pkgsStable; [
          v4l-utils
          steam
        ];
        networking.hosts = {
          "204.168.166.118" = [
            "ok-stepca-hz-1.ok.lan"
            "ok-stepca-hz-1"
          ];
       
          "89.167.0.144" = [
            "ok-etcd-hz-1.ok.lan"
            "ok-etcd-hz-1"
          ];
       
          "204.168.205.158" = [
            "ok-etcd-hz-2.ok.lan"
            "ok-etcd-hz-2"
          ];
       
          "37.27.252.108" = [
            "ok-etcd-hz-3.ok.lan"
            "ok-etcd-hz-3"
          ];
        };
        networking.hostName = "nixos-dude";
        systemd.services."wg-quick-wgokolo".restartTriggers = [ /root/wgokolo.age ];
        systemd.services."wg-quick-wgru".restartTriggers = [ /root/wgru.age ];
        systemd.services."wg-quick-wgvisi".restartTriggers = [ /root/wgvisi.age ];
        networking.wg-quick.interfaces.wgokolo.configFile = config.age.secrets.wgokolo.path;
        networking.wg-quick.interfaces.wgru.configFile = config.age.secrets.wgru.path;
        networking.wg-quick.interfaces.wgvisi.configFile = config.age.secrets.wgvisi.path;
        systemd.services.NetworkManager-wait-online.enable = false;
        networking.firewall = {
          enable = true;
          allowedUDPPorts = [];
          allowedTCPPorts = [];
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
              command = "start-hyprland";
              user = "byda";
            };
            default_session = initial_session;
          };
        };
      };
    };
  };

  networking.nameservers = [ "8.8.8.8" "8.8.4.4" ];
  networking.networkmanager.enable = true;
  networking.useDHCP = lib.mkDefault true;

  # DO NOT CHANGE!
  system.stateVersion = "24.11";
}
