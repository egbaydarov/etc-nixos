{ config, lib, pkgs, ... }:
{
  systemd.extraConfig = ''
    DefaultCPUAccounting=yes
  '';
  systemd.slices."ui.slice" = {
    description = "Interactive UI slice";
    CPUWeight   = 2048;        # ~20 × the default weight
    AllowedCPUs  = "0";
  };
  systemd.slices."apps.slice" = {
    description = "Desktop apps slice";
    CPUQuota    = "90%";
  };
  systemd.user.slice = "apps.slice";
  services.greetd.settings.initial_session.command =
    "systemd-run --user --scope -p Slice=ui.slice Hyprland";
}
