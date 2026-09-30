{
  config.substrate.modules.ai.clients.mcp-servers.sequential-thinking = {
    tags = [
      "ai:clients"
    ];

    homeManager =
      {
        lib,
        pkgs,
        wrap,
        ...
      }:
      let
        mcpPackage = wrap.withShell {
          package = pkgs.nodejs;
          exe = "npx";
          args = [
            "-y"
            "@modelcontextprotocol/server-sequential-thinking@2025.12.18"
          ];
          runtimeInputs = [ pkgs.nodejs ];
        };
      in
      {
        hdwlinux.ai.clients.mcpServers.sequential-thinking.stdio = {
          command = lib.getExe mcpPackage;
          args = [ ];
        };
      };
  };
}
