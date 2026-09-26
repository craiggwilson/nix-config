{
  config.substrate.modules.programs.gh = {
    tags = [ "programming" ];

    perUser =
      { pkgs, config, lib, ... }:
      let
        yaml = (pkgs.formats.yaml { });
        cfg = config.hdwlinux.programs.gh;
      in
      {
        options.hdwlinux.programs.gh = {
          extensions = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [ ];
            description = "gh extension packages installed into ~/.local/share/gh/extensions.";
          };
        };

        config = {
          packages = [ pkgs.gh ];

          files = {
            ".config/gh/config.yml".source = yaml.generate "gh-config.yml" {
              version = "1";
              git_protocol = "ssh";
              prompt = "enabled";
            };

            ".local/share/gh/extensions".source = pkgs.linkFarm "gh-extensions" (
              map (p: {
                name = p.pname or p.name;
                path = p;
              }) cfg.extensions
            );
          };

          # Credential helper (home-manager's programs.gh.gitCredentialHelper).
          hdwlinux.programs.git.configFragments = [
            {
              credential = lib.genAttrs [
                "https://github.com"
                "https://gist.github.com"
              ] (_: {
                helper = [
                  ""
                  "${pkgs.gh}/bin/gh auth git-credential"
                ];
              });
            }
          ];
        };
      };
  };
}
