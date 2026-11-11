{
  config.substrate.modules.programs.micro = {
    # NixOS enables nano by default; micro replaces it as the editor for the
    # system itself (root, system scripts), while the per-user config and
    # theme live in homeManager below
    nixos =
      { pkgs, ... }:
      {
        programs.nano.enable = false;
        environment.systemPackages = [ pkgs.micro ];
      };

    homeManager =
      { config, lib, ... }:
      let
        # this module applies to every system, but theming does not
        hasTheme = config.hdwlinux.theme.colors ? hexWithHashtag;
        colors = config.hdwlinux.theme.colors.hexWithHashtag;
      in
      {
        # programs.micro has no defaultEditor option, so set the editor
        # environment variables directly, as programs.helix.defaultEditor did
        home.sessionVariables = {
          EDITOR = "micro";
          VISUAL = "micro";
        };

        programs.micro = {
          enable = true;

          settings = {
            colorscheme = lib.mkIf hasTheme "hdwlinux";
            mouse = true;
            softwrap = true;
          };
        };

        # Port of the former helix "hdwlinux" theme, mapped to micro's
        # color-link groups (https://micro-editor.github.io/runtime/help/colors.html)
        xdg.configFile."micro/colorschemes/hdwlinux.micro".text = lib.mkIf hasTheme ''
          color-link default "${colors.base05},${colors.base00}"

          color-link comment "italic ${colors.base04}"
          color-link constant "${colors.base09}"
          color-link constant.bool "${colors.base09}"
          color-link constant.number "${colors.base09}"
          color-link constant.specialChar "${colors.base0C}"
          color-link constant.string "${colors.base0B}"
          color-link constant.string.url "underline ${colors.base0C}"
          color-link identifier.class "${colors.base0D}"
          color-link statement "${colors.base0E}"
          color-link type "${colors.base0A}"
          color-link type.keyword "${colors.base0E}"
          color-link symbol.operator "${colors.base0F}"
          color-link symbol.tag "${colors.base0E}"
          color-link preproc "${colors.base0E}"
          color-link special "${colors.base0C}"
          color-link underlined "underline ${colors.base0D}"
          color-link error "bold ${colors.base08}"
          color-link todo "${colors.base0A}"

          color-link selection "${colors.base05},${colors.base02}"
          color-link hlsearch "${colors.base05},${colors.base03}"
          color-link statusline "${colors.base05},${colors.base01}"
          color-link statusline.inactive "${colors.base04},${colors.base01}"
          color-link statusline.suggestions "${colors.base05},${colors.base01}"
          color-link tabbar "${colors.base04},${colors.base01}"
          color-link tabbar.active "bold ${colors.base00},${colors.base07}"
          color-link indent-char "${colors.base02}"
          color-link line-number "${colors.base04},${colors.base01}"
          color-link current-line-number "${colors.base07},${colors.base01}"
          color-link gutter-info "${colors.base04}"
          color-link gutter-error "${colors.base08}"
          color-link gutter-warning "${colors.base0A}"
          color-link diff-added "${colors.base0B}"
          color-link diff-modified "${colors.base0A}"
          color-link diff-deleted "${colors.base08}"
          color-link cursor-line "${colors.base01}"
          color-link color-column "${colors.base02}"
          color-link scrollbar "${colors.base02}"
          color-link divider "${colors.base02}"
          color-link message "${colors.base0B}"
          color-link error-message "${colors.base08}"
          color-link match-brace "${colors.base00},${colors.base0A}"
          color-link tab-error "${colors.base08}"
          color-link trailingws "${colors.base0A}"
          color-link ignore "${colors.base03}"
        '';
      };
  };
}
