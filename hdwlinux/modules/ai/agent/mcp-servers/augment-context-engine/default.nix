{
  config.substrate.modules.ai.agent.mcp-servers.augment-context-engine = {
    tags = [
      "ai:agent"
      "users:craig:work"
    ];

    homeManager =
      { lib, pkgs, ... }:
      {
        hdwlinux.ai.agent.mcpServers.augment-context-engine.stdio = {
          command = lib.getExe pkgs.hdwlinux.auggie;
          args = [
            "--mcp"
            "--mcp-auto-workspace"
          ];
        };
      };
  };
}
