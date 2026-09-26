{
  config.substrate.modules.programs.bat = {
    tags = [ "programming" ];

    perUser =
      { config, pkgs, ... }:
      {
        packages = [ pkgs.bat ];

        # bat reads the standard XDG location; no wrapping needed.
        # NOTE: --map-syntax for ghostty is the shell-integration HM's
        # programs.ghostty used to contribute; lives here (bat's config),
        # while ghostty contributes the syntax definition file below.
        files.".config/bat/config".text = ''
          --map-syntax='${config.homeDirectory}/.config/ghostty/config:Ghostty Config'
          --theme=base16
        '';

        files.".config/bat/syntaxes/ghostty.sublime-syntax".source = "${pkgs.ghostty}/share/bat/syntaxes/ghostty.sublime-syntax";
      };
  };
}
