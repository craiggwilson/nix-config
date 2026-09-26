{
  config.substrate.modules.programs.ripgrep = {
    tags = [ "programming" ];

    perUser =
      { config, pkgs, ... }:
      {
        packages = [ pkgs.ripgrep ];

        env.RIPGREP_CONFIG_PATH = "${config.homeDirectory}/.config/ripgrep/ripgreprc";

        files.".config/ripgrep/ripgreprc".text = ''
          --max-columns=150
          --max-columns-preview
          --smart-case
        '';
      };
  };
}
