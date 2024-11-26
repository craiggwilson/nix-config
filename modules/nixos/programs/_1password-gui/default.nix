{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.programs._1password-gui;
in
{
  options.hdwlinux.programs._1password-gui = {
    enable = config.lib.hdwlinux.mkEnableOption "1password-gui" [
      "gui"
      "security:passwordmanager"
    ];
  };

  config = lib.mkIf cfg.enable {
    programs._1password-gui = {
      enable = true;
    };

    security.pam.services."1password".enableGnomeKeyring = true;
  };
}
