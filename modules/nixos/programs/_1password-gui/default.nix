{
  options,
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs._1password-gui;
in
{
  options.hdwlinux.programs._1password-gui = {
    enable = lib.hdwlinux.mkEnableTagsOpt "1password-gui" [ "gui" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    programs._1password-gui = {
      enable = true;
    };

    security.pam.services."1password".enableGnomeKeyring = true;
  };
}
