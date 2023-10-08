{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.pamixer;
in
{
  options.hdwlinux.packages.pamixer = with types; {
    enable = mkBoolOpt false "Whether or not to enable pamixer.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [
      pamixer
    ];
  };
}
