{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.raeford.ssh;
  domain = config.hdwlinux.networking.domain or "raeford.wilsonfamilyhq.com";
in
{
  options.hdwlinux.raeford.ssh = {
    enable = config.lib.hdwlinux.mkEnableOption "raeford office SSH configuration" "raeford";
  };

  config = lib.mkIf cfg.enable {
    hdwlinux.security.ssh.matchBlocks = {
      "raeford-hosts" = {
        host = "*.${domain} *.tailc675f.ts.net";
        forwardX11 = true;
      };
    };
  };
}
