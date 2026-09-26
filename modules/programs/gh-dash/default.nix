{
  config.substrate.modules.programs.gh-dash = {
    tags = [ "programming" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.gh-dash ];

        hdwlinux.programs.gh.extensions = [ pkgs.gh-dash ];

        files.".config/gh-dash/config.yml".source = (pkgs.formats.yaml { }).generate "gh-dash-config.yml" { };
      };
  };
}
