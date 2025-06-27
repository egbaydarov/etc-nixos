{ config, lib, pkgs, modulesPath, ... }:
let
  twitchNotif = buildGoModule rec {
    pname = "twitch-notif";
    version = "0.3.4";

    src = fetchFromGitHub {
      owner = "egbaydarov";
      repo = "twitch-notif-shit";
      rev = "master";
      sha256 = "0m2fzpqxk7hrbxsgqplkg7h2p7gv6s1miymv3gvw0cz039skag0s";
    };

    vendorSha256 = "1879j77k96684wi554rkjxydrj8g3hpp0kvxz03sd8dmwr3lh83j";

#    ldflags = [
#      "-s -w -X github.com/knqyf263/pet/cmd.version=${version}"
#    ];

    #nativeBuildInputs = [musl];

    CGO_ENABLED = 0;

    ldflags = [
#      "-linkmode external"
#      "-extldflags '-static -L${musl}/lib'"
    ];

    meta = with lib; {
      description = "";
      homepage = "https://github.com/egbaydarov/twitch-notif-shit";
      license = licenses.mit;
      maintainers = with maintainers; [ egbaydarov ];
    };
  };
in
{
  environment.systemPackages = [
    twitchNotif
  ];
}
