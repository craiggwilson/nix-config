{
  config.substrate.modules.locations.raeford.networking = {
    tags = [ "location:raeford" ];

    generic = {
      hdwlinux.networking.domain = "raeford.wilsonfamilyhq.com";
      hdwlinux.networking.lanCidrs = [ "192.168.10.0/24" ];
    };

    nixos = {
      # Keep LAN names resolvable even when WARP bypasses local DNS.
      networking.extraHosts = ''
        192.168.1.6 controller.raeford.wilsonfamilyhq.com
        192.168.10.52 blackflame blackflame.raeford.wilsonfamilyhq.com
        192.168.10.53 unsouled.raeford.wilsonfamilyhq.com
        192.168.100.50 agents.wilsonfamilyhq.com auth.wilsonfamilyhq.com hindsight.wilsonfamilyhq.com homeassistant.raeford.wilsonfamilyhq.com paperless.raeford.wilsonfamilyhq.com synology.raeford.wilsonfamilyhq.com yuvomi.raeford.wilsonfamilyhq.com
        192.168.100.51 wintersteel.raeford.wilsonfamilyhq.com
        192.168.150.71 printer.raeford.wilsonfamilyhq.com
      '';
    };
  };
}
