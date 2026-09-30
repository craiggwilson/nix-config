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
        secrets = config.hdwlinux.security.secrets.entries;
        hasSecrets = secrets ? githubApiToken;

        mcpPackage = wrap.withShell {
          package = pkgs.github-mcp-server;
          preHook = ''export GITHUB_PERSONAL_ACCESS_TOKEN="$(cat ${secrets.githubApiToken.path})"'';
        };
      in
      {
        config = lib.mkIf hasSecrets {
          hdwlinux.ai.clients.mcpServers.github.stdio = {
            command = lib.getExe mcpPackage;
            args = [ "stdio" ];
          };
        };
      };
  };
}
