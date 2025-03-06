{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.programs.jujutsu;
in
{
  options.hdwlinux.programs.jujutsu = {
    enable = config.lib.hdwlinux.mkEnableOption "jujutsu" "programming";
  };

  config = lib.mkIf cfg.enable {
    programs.jujutsu = {
      enable = true;

      settings = {
        user = {
          email = config.hdwlinux.user.email;
          name = config.hdwlinux.user.fullName;
        };
      };
    };
  };
}
