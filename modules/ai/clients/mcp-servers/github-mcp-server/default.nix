{
  config.substrate.modules.ai.clients.mcp-servers.github-mcp-server = {
    tags = [
      "ai:clients"
    ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        wrap,
        ...
      }:
      let
        hasToken = config.secretspec.entries ? GITHUB_API_TOKEN;
      in
      {
        config = lib.mkIf hasToken {
          hdwlinux.ai.clients.mcpServers.github.stdio = {
            command = lib.getExe (
              wrap.package {
                package = pkgs.github-mcp-server;
                secrets.scope = "github_mcp";
              }
            );
            args = [ "stdio" ];
          };
          secretspec.scopes.github_mcp.secrets = [ "GITHUB_API_TOKEN" ];
        };
      };
  };
}
