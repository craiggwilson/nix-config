{
  config.substrate.modules.ai.agent.mcp-servers.mcp-nixos = {
    tags = [
      "ai:agent"
    ];

    homeManager =
      { pkgs, ... }:
      {
        hdwlinux.ai.agent.mcpServers.nixos.stdio = {
          command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
          args = [ ];
        };
      };
  };
}
