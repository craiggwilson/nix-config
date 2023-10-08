{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.vscode;
in
{
  options.hdwlinux.packages.vscode = with types; {
    enable = mkBoolOpt false "Whether or not to enable vscode.";
    settings = mkOpt attrs { } (mdDoc "Options passed directly to home-manager's `programs.vscode.userSettings`.");
    extensions = mkOpt (listOf package) { } (mdDoc "Options passed directly to home-manager's `programs.vscode.extensions`.");
  };

  config = mkIf cfg.enable {
    hdwlinux.home.programs.vscode = {
      enable = true;
      mutableExtensionsDir = true;

      userSettings = mkAliasDefinitions options.hdwlinux.packages.vscode.settings;
      extensions = mkAliasDefinitions options.hdwlinux.packages.vscode.extensions;
    };
  };
}
