{
  config.substrate.modules.programs.jira-cli = {
    tags = [ "profile:team-collaboration" ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        cfg = config.hdwlinux.programs.jira-cli;
      in
      {
        options.hdwlinux.programs.jira-cli.package = lib.mkOption {
          default = pkgs.jira-cli-go;
          description = "Jira CLI package to install; null disables installation.";
          type = lib.types.nullOr lib.types.package;
        };

        config.home.packages = lib.optional (cfg.package != null) cfg.package;
      };
  };
}
