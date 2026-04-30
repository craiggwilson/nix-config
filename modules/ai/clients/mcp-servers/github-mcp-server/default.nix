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
        ...
      }:
      let
        secrets = config.hdwlinux.security.secrets.entries;
        hasSecrets = secrets ? githubApiToken;

        mcpPackage = pkgs.writeShellScriptBin "github-mcp-server" ''
          GITHUB_PERSONAL_ACCESS_TOKEN=$(cat ${secrets.githubApiToken.path}) ${pkgs.github-mcp-server}/bin/github-mcp-server "$@"
        '';
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
