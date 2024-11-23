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
    enable = lib.mkOption {
      description = "Whether to enable docker.";
      type = lib.types.bool;
      default = (lib.hdwlinux.elemPrefix "virtualization:docker" config.hdwlinux.features.tags);
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
    };
  };
}
