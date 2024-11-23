{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.virtualization.docker;
in
{
  options.hdwlinux.virtualization.docker = {
    enable = config.lib.hdwlinux.features.mkEnableOption "docker" "virtualization:docker";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
    };
  };
}
