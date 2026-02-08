{
  config.substrate.modules.ai.agent.mcp-servers.sequential-thinking = {
    tags = [
      "ai:agent"
    ];

    homeManager =
      { pkgs, ... }:
      let
        mcpPackage = pkgs.writeShellScriptBin "sequential-thinking" ''
          export PATH="${pkgs.nodejs}/bin:${pkgs.nodePackages.npm}/bin:$PATH"
          exec ${pkgs.nodejs}/bin/npx -y @modelcontextprotocol/server-sequential-thinking@2025.11.25 "$@"
        '';
      in
      {
        home.packages = [ mcpPackage ];

        hdwlinux.ai.agent.mcpServers.sequential-thinking.stdio = {
          command = "sequential-thinking";
          args = [ ];
        };
      };
  };
}
