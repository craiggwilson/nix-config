{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.neofetch;
in
{
  options.hdwlinux.packages.neofetch = with types; {
    enable = mkBoolOpt false "Whether or not to enable neofetch.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [
      neofetch
    ];
  };
}
