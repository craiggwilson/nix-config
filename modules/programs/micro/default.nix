{
  config.substrate.modules.programs.micro = {
    tags = [ "programming" ];

    homeManager =
      { config, ... }:
      let
        colors = config.hdwlinux.theme.colors.withHashtag;
      in
      {
        programs.micro = {
          enable = true;
          settings = {
            colorscheme = "hdwlinux";
            mkparents = true;
            softwrap = true;
            tabsize = 2;
            tabstospaces = true;
          };
        };

        home.sessionVariables = {
          EDITOR = "micro";
          VISUAL = "micro";
        };

        xdg.configFile."micro/colorschemes/hdwlinux.micro".text = ''
          color-link default "${colors.base05},${colors.base00}"
          color-link comment "${colors.base04}"

          color-link identifier "${colors.base0D}"
          color-link identifier.class "${colors.base0D}"
          color-link identifier.var "${colors.base0D}"

          color-link constant "${colors.base09}"
          color-link constant.number "${colors.base09}"
          color-link constant.string "${colors.base0B}"

          color-link symbol "${colors.base0E}"
          color-link symbol.brackets "${colors.base06}"
          color-link symbol.tag "${colors.base0D}"

          color-link type "${colors.base0D}"
          color-link type.keyword "${colors.base0F}"

          color-link special "${colors.base0E}"
          color-link statement "${colors.base0E}"
          color-link preproc "${colors.base0E}"

          color-link underlined "${colors.base0D}"
          color-link error "bold ${colors.base08}"
          color-link todo "bold ${colors.base0F}"

          color-link diff-added "${colors.base0B}"
          color-link diff-modified "${colors.base0F}"
          color-link diff-deleted "${colors.base08}"

          color-link gutter-error "${colors.base08}"
          color-link gutter-warning "${colors.base0F}"

          color-link statusline "${colors.base05},${colors.base01}"
          color-link tabbar "${colors.base05},${colors.base01}"
          color-link indent-char "${colors.base03}"
          color-link line-number "${colors.base03}"
          color-link current-line-number "${colors.base07}"

          color-link cursor-line "${colors.base02},${colors.base05}"
          color-link color-column "${colors.base02}"
          color-link type.extended "default"
        '';
      };
  };
}

