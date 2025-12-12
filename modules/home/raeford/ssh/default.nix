{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.raeford.ssh;
in
{
  options.hdwlinux.raeford.ssh = {
    enable = config.lib.hdwlinux.mkEnableOption "raeford office SSH configuration" "raeford";
  };

  config = lib.mkIf cfg.enable {
    hdwlinux.security.ssh.matchBlocks = {
      raeford = {
        host = "*.${config.hdwlinux.networking.domain}";
        forwardX11 = true;
      };
      tailnet = lib.mkIf config.hdwlinux.networking.tailscale.enable {
        host = "*.${config.hdwlinux.networking.tailscale.tailnet}";
        forwardX11 = true;
      };
    };
  };
}
