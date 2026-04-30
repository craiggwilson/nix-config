{
  config.substrate.modules.ai.clients.mcp-servers.sequential-thinking = {
    tags = [
      "ai:clients"
    ];

    homeManager =
      { lib, pkgs, ... }:
      let
        mcpPackage = pkgs.writeShellScriptBin "sequential-thinking" ''
          export PATH="${pkgs.nodejs}/bin:$PATH"
          exec ${pkgs.nodejs}/bin/npx -y @modelcontextprotocol/server-sequential-thinking@2025.11.25 "$@"
        '';
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
