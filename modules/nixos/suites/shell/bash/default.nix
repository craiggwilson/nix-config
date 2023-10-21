{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.suites.shell.bash;
in
{
  options.hdwlinux.suites.shell.bash = with types; {
    enable = mkBoolOpt false "Whether or not to enable bash and shell integrations.";
  };

  config.hdwlinux.features = mkIf cfg.enable {
    bash = {
      enable = true;
      initExtra = ''
        source ~/.profile
      '';
    };
    
    direnv.enable = true;
    fzf.enable = true;
    starship.enable = true;
    zoxide.enable = true;
  };
}
