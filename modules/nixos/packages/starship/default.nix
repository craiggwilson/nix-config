{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.starship;
in
{
  options.hdwlinux.packages.starship = with types; {
    enable = mkBoolOpt false "Whether or not to enable starship.";
    settings = mkOpt attrs { } (mdDoc "Options to pass directly to `programs.starship.settings`.");
  };

  config = mkIf cfg.enable {
    hdwlinux.home.programs.starship = {
      enable = true;
      enableBashIntegration = mkAliasDefinitions options.hdwlinux.packages.bash.enable;
      settings = mkAliasDefinitions options.hdwlinux.packages.starship.settings;
    };
  };
}
