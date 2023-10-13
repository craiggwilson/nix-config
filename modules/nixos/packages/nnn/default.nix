{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.nnn;
in
{
  options.hdwlinux.packages.nnn = with types; {
    enable = mkBoolOpt false "Whether or not to enable nnn.";
  };

  config.hdwlinux.home.programs.nnn = mkIf cfg.enable {
    enable = true;
    plugins = with pkgs; [

    ];
  };
}
