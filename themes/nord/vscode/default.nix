{ lib, pkgs, config, ... }:
{
  hdwlinux.packages.vscode = {
    extensions = with pkgs.vscode-extensions; [
      #TODO: nord deep extension
    ];

    settings = {
      "workbench.colorTheme" = "Nord Deep";
    };
  };
}
