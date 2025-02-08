{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.services.ssh-agent;
in
{
  options.hdwlinux.services.ssh-agent = {
    enable = lib.hdwlinux.mkEnableOption "ssh-agent" true;
  };

  config = lib.mkIf cfg.enable {
    services.ssh-agent.enable = true;
  };
}
