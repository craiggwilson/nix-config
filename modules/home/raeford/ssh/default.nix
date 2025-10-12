{
  config,
  lib,
  pkgs,
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
    hdwlinux.security.ssh.includes = [
      (pkgs.writeText "ssh_raeford_config" ''
        Host *.${domain} *.tailc675f.ts.net
          ForwardX11 yes
      '')
    ];
  };
}
