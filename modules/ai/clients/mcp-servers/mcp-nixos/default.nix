{
  config.substrate.modules.ai.clients.mcp-servers.mcp-nixos = {
    tags = [
      "ai:clients"
    ];

    homeManager =
      { lib, pkgs, ... }:
      {
        hdwlinux.ai.clients.mcpServers.nixos.stdio = {
          command = lib.getExe pkgs.mcp-nixos;
          args = [ ];
        };
      };
  };
}
