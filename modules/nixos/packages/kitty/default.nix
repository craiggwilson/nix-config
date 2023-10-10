{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.kitty;
in
{
  options.hdwlinux.packages.kitty = with types; {
    enable = mkBoolOpt false "Whether or not to enable kitty.";
    settings = mkOpt attrs { } (mdDoc "Options passed directly to home-manager's `programs.kitty.settings`.");
    extraConfig = mkStrOpt "" (mdDoc "Option passed directly to home-manager's `programs.kitty.extraConfig`.");
  };

  config.hdwlinux.home = mkIf cfg.enable {
    programs.kitty =  {
      enable = true;
      settings = mkAliasDefinitions options.hdwlinux.packages.kitty.settings;
      extraConfig = mkAliasDefinitions options.hdwlinux.packages.kitty.extraConfig;
    };
  };
}
