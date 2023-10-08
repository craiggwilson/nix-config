{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.azure;
in
{
  options.hdwlinux.packages.azure = with types; {
    enable = mkBoolOpt false "Whether or not to enable azure.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [ 
        azure-cli
    ];
  };
}

