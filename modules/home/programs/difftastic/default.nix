{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.difftastic;
in
{
  options.hdwlinux.programs.difftastic = {
    enable = lib.hdwlinux.mkEnableOption "difftastic" true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.difftastic ];

    programs.git.extraConfig = lib.mkIf config.hdwlinux.programs.git.enable {
      diff = {
        external = "${pkgs.difftastic}/bin/difft";
        tool = "difftastic";
      };
      difftool.prompt = false;
      "difftool \"difftastic\"" = {
        cmd = ''${pkgs.difftastic}/bin/difft "$MERGED" "$LOCAL" "${config.hdwlinux.theme.colors.base0D}" "${config.hdwlinux.theme.colors.base02}" "$REMOTE" "${config.hdwlinux.theme.colors.base0D}" "${config.hdwlinux.theme.colors.base02}"'';
      };
      pager.difftool = true;
    };

    programs.jujutsu.settings = lib.mkIf config.hdwlinux.programs.jujutsu.enable {
      merge-tools.difft = {
        program = "${pkgs.difftastic}/bin/difft";
        diff-args = [
          "--color=always"
          "$left"
          "$right"
        ];
      };

      ui = {
        diff-formatter = "difft";
      };
    };
  };
}
