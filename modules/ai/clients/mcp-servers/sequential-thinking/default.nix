{
  config.substrate.modules.ai.clients.mcp-servers.sequential-thinking = {
    tags = [
      "ai:clients"
    ];

    homeManager =
      { lib, pkgs, ... }:
      let
        # A script is already the thing this server is: a wrapper with no env,
        # args, prefix or contributor around it would only add a file.
        # The registry is pinned to the public npm registry because the package
        # is public and pinned to an exact version — repos with a corporate
        # .npmrc (auth'd mirror, always-auth) would otherwise break the npx
        # fetch when the mirror token expires.
        mcpPackage = pkgs.writeShellApplication {
          name = "sequential-thinking";
          runtimeInputs = [ pkgs.nodejs ];
          text = ''
            export NPM_CONFIG_REGISTRY="https://registry.npmjs.org/"
            export NPM_CONFIG_ALWAYS_AUTH="false"
            exec npx -y @modelcontextprotocol/server-sequential-thinking@2025.12.18 "$@"
          '';
        };
      in
      {
        home.packages = [ ];

        hdwlinux.ai.clients.mcpServers.sequential-thinking.stdio = {
          command = lib.getExe mcpPackage;
          args = [ ];
        };
      };
  };
}
