{
  config.substrate.modules.ai.agent.skills.google-docs-skill = {
    tags = [
      "ai:agent"
    ];

    homeManager =
      { config, pkgs, ... }:
      let
        gems = pkgs.bundlerEnv {
          name = "google-docs-skill-gems";
          ruby = pkgs.ruby;
          gemdir = ./_gems;
        };
      in
      {
        hdwlinux = {
          ai.agent.skills.google-docs-skill = pkgs.runCommand "google-docs-skill" { } ''
            mkdir -p $out/bin
            cp -r ${./skill}/* $out/
            chmod +x $out/scripts/*.rb

            cat > $out/bin/ruby <<WRAPPER
            #!${pkgs.bash}/bin/bash
            exec ${gems}/bin/bundle exec ${gems.wrappedRuby}/bin/ruby "\$@"
            WRAPPER
            chmod +x $out/bin/ruby
          '';

          security.secrets.entries.googleDocsApiOauth = {
            path = "${config.xdg.configHome}/google-docs-skill/client_secret.json";
            reference = "op://Work/google-api-oauth/client_secret.json";
            mode = "0600";
          };
        };
      };
  };
}
