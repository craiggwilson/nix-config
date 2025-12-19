{
  config.substrate.modules.programs."1password" = {
    tags = [ "security:passwordmanager" ];
    nixos =
      {
        lib,
        hasTag,
        ...
      }:
      {
        programs._1password.enable = true;

        programs._1password-gui = lib.mkIf (hasTag "gui") {
          enable = true;
        };

        security.pam.services."1password".enableGnomeKeyring = hasTag "gui";
      };
    homeManager =
      {
        hasTag,
        lib,
        pkgs,
        ...
      }:
      {
        hdwlinux.apps.passwordManager = lib.mkIf (hasTag "gui") {
          package = pkgs._1password-gui;
          argGroups = {
            toggle = [ "--toggle" ];
            lock = [ "--lock" ];
            quickaccess = [ "--quick-access" ];
          };
        };
      };
  };
}
