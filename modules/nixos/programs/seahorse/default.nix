{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.programs.seahorse;
in
{
  options.hdwlinux.programs.seahorse = {
    enable = lib.hdwlinux.mkEnableOption "seahorse" config.hdwlinux.services.gnome-keyring.enable;
  };

  config = lib.mkIf cfg.enable {
    programs.seahorse = {
      enable = true;
    };
  };
}
