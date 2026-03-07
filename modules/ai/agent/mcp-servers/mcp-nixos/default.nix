{
  config.substrate.modules.ai.agent.mcp-servers.mcp-nixos = {
    tags = [
      "ai:agent"
    ];

    homeManager =
      { lib, pkgs, ... }:
      {
        hdwlinux.ai.agent.mcpServers.nixos.stdio = {
          command = lib.getExe pkgs.mcp-nixos;
          args = [ ];
        };
      };
  };
}
