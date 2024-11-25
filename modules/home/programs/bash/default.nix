{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.programs.bash;
in
{
  options.hdwlinux.programs.bash = {
    enable = lib.hdwlinux.mkEnableOption "bash" true;
  };

  config = lib.mkIf cfg.enable {
    programs.bash = {
      enable = true;
      initExtra = ''
        source ~/.profile
      '';
      enableVteIntegration = true;
      historyControl = [
        "ignoredups"
        "ignorespace"
      ];
      historyIgnore = [
        "cd"
        "exit"
        "ls"
      ];
    };
  };
}
