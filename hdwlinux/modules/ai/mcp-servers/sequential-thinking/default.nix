{
  config.substrate.modules.programs.sequential-thinking = {
    tags = [
      "programming"
      "ai:mcp"
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

        hdwlinux.ai.mcpServers.sequential-thinking = {
          type = "stdio";
          command = "sequential-thinking";
          args = [ ];
        };
      };
  };
}
