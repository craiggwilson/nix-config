{
  config.substrate.modules.ai.agent.mcp-servers.evergreen-mcp-server = {
    tags = [
      "ai:agent"
    ];

    homeManager =
      { lib, pkgs, ... }:
      {
        hdwlinux.ai.agent.mcpServers.evergreen.stdio = {
          command = lib.getExe pkgs.hdwlinux.evergreen-mcp-server;
          args = [ ];
        };
      };
  };
}
