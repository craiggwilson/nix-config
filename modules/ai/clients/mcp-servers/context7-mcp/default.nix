{
  config.substrate.modules.ai.clients.mcp-servers.context7-mcp = {
    tags = [
      "ai:clients"
    ];

    homeManager =
      { lib, pkgs, ... }:
      {
        hdwlinux.ai.clients.mcpServers.context7-mcp.stdio = {
          command = lib.getExe pkgs.hdwlinux.context7-mcp;
          args = [ ];
        };
      };
  };
}
