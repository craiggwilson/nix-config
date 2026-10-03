{
  config.substrate.modules.programs.evergreen = {
    tags = [
      "programming"
      "users:craig:work"
    ];

    homeManager =
      { config, lib, pkgs, wrap, ... }:
      let
        # Inner wrapper injects --config. args are interpolated verbatim into the
        # exec line, so $EVERGREEN_CONFIG expands at exec time.
        # Outer wrapper resolves the scope, putting EVERGREEN_CONFIG into the
        # environment before the inner wrapper runs.
        evergreenScript = wrap.package {
          package = wrap.package {
            package = pkgs.hdwlinux.evergreen;
            args = [
              "--config"
              "\$EVERGREEN_CONFIG"
            ];
          };
          secrets.scope = "evergreen";
        };
      in
      {
        home.packages = [
          evergreenScript
        ];

        secretspec = {
          entries = {
            EVERGREEN_API_KEY = {
              description = "Evergreen API key substituted into the composed CLI config.";
              ref = {
                vault = "Work";
                item = "evergreen";
                field = "api-key";
              };
            };
            EVERGREEN_CONFIG = {
              description = "Materialized Evergreen CLI config.";
              composed = builtins.readFile ./evergreen.yml;
              asPath = true;
            };
          };
          scopes.evergreen.secrets = [ "EVERGREEN_CONFIG" ];
        };
      };
  };
}
