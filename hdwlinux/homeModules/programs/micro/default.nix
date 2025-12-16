{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.programs.micro;
in
{
  options.hdwlinux.programs.micro = {
    enable = lib.hdwlinux.mkEnableOption "micro" true;
  };

  config = lib.mkIf cfg.enable {
    programs.micro = {
      enable = true;
      settings = {
        colorscheme = "hdwlinux";
        mkparents = true;
        softwrap = true;
      };
    };

    home.sessionVariables = {
      EDITOR = "micro";
      VISUAL = "micro";
    };

    xdg.configFile."micro/colorschemes/hdwlinux.micro".text = ''
      color-link default "${config.hdwlinux.theme.colors.withHashtag.base05},${config.hdwlinux.theme.colors.withHashtag.base00}"
      color-link comment "${config.hdwlinux.theme.colors.withHashtag.base04}"

      color-link identifier "${config.hdwlinux.theme.colors.withHashtag.base0D}"
      color-link identifier.class "${config.hdwlinux.theme.colors.withHashtag.base0D}"
      color-link identifier.var "${config.hdwlinux.theme.colors.withHashtag.base0D}"

      color-link constant "${config.hdwlinux.theme.colors.withHashtag.base09}"
      color-link constant.number "${config.hdwlinux.theme.colors.withHashtag.base09}"
      color-link constant.string "${config.hdwlinux.theme.colors.withHashtag.base0B}"

      color-link symbol "${config.hdwlinux.theme.colors.withHashtag.base0E}"
      color-link symbol.brackets "${config.hdwlinux.theme.colors.withHashtag.base06}"
      color-link symbol.tag "${config.hdwlinux.theme.colors.withHashtag.base0D}"

      color-link type "${config.hdwlinux.theme.colors.withHashtag.base0D}"
      color-link type.keyword "${config.hdwlinux.theme.colors.withHashtag.base0F}"

      color-link special "${config.hdwlinux.theme.colors.withHashtag.base0E}"
      color-link statement "${config.hdwlinux.theme.colors.withHashtag.base0E}"
      color-link preproc "${config.hdwlinux.theme.colors.withHashtag.base0E}"

      color-link underlined "${config.hdwlinux.theme.colors.withHashtag.base0D}"
      color-link error "bold ${config.hdwlinux.theme.colors.withHashtag.base08}"
      color-link todo "bold ${config.hdwlinux.theme.colors.withHashtag.base0F}"

      color-link diff-added "${config.hdwlinux.theme.colors.withHashtag.base0B}"
      color-link diff-modified "${config.hdwlinux.theme.colors.withHashtag.base0F}"
      color-link diff-deleted "${config.hdwlinux.theme.colors.withHashtag.base08}"

      color-link gutter-error "${config.hdwlinux.theme.colors.withHashtag.base08}"
      color-link gutter-warning "${config.hdwlinux.theme.colors.withHashtag.base0F}"

      color-link statusline "${config.hdwlinux.theme.colors.withHashtag.base05},${config.hdwlinux.theme.colors.withHashtag.base01}"
      color-link tabbar "${config.hdwlinux.theme.colors.withHashtag.base05},${config.hdwlinux.theme.colors.withHashtag.base01}"
      color-link indent-char "${config.hdwlinux.theme.colors.withHashtag.base03}"
      color-link line-number "${config.hdwlinux.theme.colors.withHashtag.base03}"
      color-link current-line-number "${config.hdwlinux.theme.colors.withHashtag.base07}"

      color-link cursor-line "${config.hdwlinux.theme.colors.withHashtag.base02},${config.hdwlinux.theme.colors.withHashtag.base05}"
      color-link color-column "${config.hdwlinux.theme.colors.withHashtag.base02}"
      color-link type.extended "default"
    '';
  };
}
