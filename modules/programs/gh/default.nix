{
  config.substrate.modules.programs.gh = {
    tags = [ "programming" ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        wrap,
        ...
      }:
      let
        # gh reads GH_TOKEN (not GITHUB_API_TOKEN), and the token must not come
        # from the keyring, which is locked when no session is active. The
        # wrapper resolves the secret at exec time; preHook runs after that
        # resolution, so it can map the injected secret onto the variable gh
        # actually reads.
        hasToken = config.secretspec.entries ? GITHUB_API_TOKEN;
        gh = wrap.package {
          package = pkgs.gh;
          secrets.scope = "gh";
          preHook = ''export GH_TOKEN="$GITHUB_API_TOKEN"'';
        };
      in
      {
        programs.gh = {
          enable = true;
          package = lib.mkIf hasToken gh;
          settings = {
            git_protocol = "ssh";
            prompt = "enabled";
          };
        };

        programs.gh-dash = {
          enable = true;
        };

        secretspec.scopes.gh.secrets = lib.mkIf hasToken [
          "GITHUB_API_TOKEN"
        ];
      };
  };
}
