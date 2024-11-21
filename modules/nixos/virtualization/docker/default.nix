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
    enable = lib.hdwlinux.mkEnableTagsOpt "docker" [
      "virtualization:docker"
    ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
    };
  };
}
