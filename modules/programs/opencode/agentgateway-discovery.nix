{
  config.substrate.modules.programs.opencode.agentgateway-discovery = {
    tags = [ "profile:ai" ];

    homeManager =
      { pkgs, ... }:
      let
        plugin = pkgs.runCommand "opencode-agentgateway-discovery" { } ''
          mkdir -p "$out"
          cp ${./agentgateway-discovery/server.js} "$out/server.js"
          cp ${./agentgateway-discovery/auth.js} "$out/auth.js"
          cp ${./agentgateway-discovery/model.js} "$out/model.js"
          cp ${./agentgateway-discovery/package.json} "$out/package.json"
        '';

        # Matching rules live in plugin options so discovery can run during plugin startup.
        providerGroups = map (
          g:
          {
            inherit (g) id name;
            clientFormat = g.format;
          }
          // (if g ? ownedBy then { inherit (g) ownedBy; } else { })
          // (if g ? modelIdPrefix then { inherit (g) modelIdPrefix; } else { })
        ) (import ./_agentgateway-groups.nix).groups;
      in
      {
        programs.opencode.settings.plugins = [
          {
            package = "${plugin}";
            options = {
              authIntegration = "wilsonfamilyhq";
              inherit providerGroups;
            };
          }
        ];
      };
  };
}
