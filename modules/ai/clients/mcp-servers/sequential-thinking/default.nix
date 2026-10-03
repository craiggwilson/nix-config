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
        mcpPackage = pkgs.writeShellApplication {
          name = "sequential-thinking";
          runtimeInputs = [ pkgs.nodejs ];
          text = ''
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
