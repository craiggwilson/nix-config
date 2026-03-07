{
  config.substrate.modules.ai.agent.mcp-servers.context7-mcp = {
    tags = [
      "ai:agent"
    ];

    homeManager =
      { lib, pkgs, ... }:
      {
        hdwlinux.ai.agent.mcpServers.context7-mcp.stdio = {
          command = lib.getExe pkgs.hdwlinux.context7-mcp;
          args = [ ];
        };
      };
  };
}
