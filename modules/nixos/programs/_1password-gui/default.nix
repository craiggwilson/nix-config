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
    enable = lib.mkOption {
      description = "Whether to enable the 1password-gui.";
      type = lib.types.bool;
      default = (
        lib.hdwlinux.elemsAll [
          "gaming"
          "security:passwordmanager"
        ] config.hdwlinux.features.tags
      );

    };
  };

  config = lib.mkIf cfg.enable {
    programs._1password-gui = {
      enable = true;
    };

    security.pam.services."1password".enableGnomeKeyring = true;
  };
}
