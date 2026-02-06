{
  config.substrate.modules.ai.agent.mcp-servers.github-mcp-server = {
    tags = [
      "programming"
      "ai:mcp"
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
          home.packages = [ mcpPackage ];

          hdwlinux.ai.agent.mcpServers.github.stdio = {
            command = "github-mcp-server";
            args = [ "stdio" ];
          };
        };
      };
  };
}
