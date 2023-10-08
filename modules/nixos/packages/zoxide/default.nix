{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.zoxide;
in
{
  options.hdwlinux.packages.zoxide = with types; {
    enable = mkBoolOpt false "Whether or not to enable zoxide.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.programs.zoxide = {
      enable = true;
      enableBashIntegration = config.hdwlinux.packages.bash.enable;
    };
  };
}
