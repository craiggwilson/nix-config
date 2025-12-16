{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.programs.mcp-atlassian;

  mcpPackage = pkgs.writeShellScriptBin "mcp-atlassian" ''
    ${pkgs.hdwlinux.mcp-atlassian}/bin/mcp-atlassian \
    --jira-url https://jira.mongodb.org \
    --jira-personal-token $(cat ${config.hdwlinux.security.secrets.entries.jiraAccessToken.path}) \
    --confluence-url https://wiki.corp.mongodb.com \
    --confluence-personal-token $(cat ${config.hdwlinux.security.secrets.entries.confluenceAccessToken.path}) \
    "$@"
  '';
in
{
  options.hdwlinux.programs.mcp-atlassian = {
    enable = config.lib.hdwlinux.mkEnableOption "mcp-atlassian" [
      "programming"
      "work"
    ];
  };

  config = lib.mkIf cfg.enable {

    home.packages = [ mcpPackage ];

    hdwlinux = {
      mcpServers.atlassian = {
        type = "stdio";
        command = "mcp-atlassian";
        args = [ ];
      };

    };
  };
}
