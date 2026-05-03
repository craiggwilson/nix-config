{
  config.substrate.modules.ai.clients.mcp-servers.evergreen-mcp-server = {
    tags = [
      "ai:clients"
      "users:craig:work"
    ];

    homeManager =
      { lib, pkgs, ... }:
      {
        hdwlinux.ai.clients.mcpServers.evergreen.stdio = {
          command = lib.getExe pkgs.hdwlinux.evergreen-mcp-server;
          args = [ ];
        };
      };
  };
}
