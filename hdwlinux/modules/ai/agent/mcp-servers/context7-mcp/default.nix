{
  config.substrate.modules.ai.agent.mcp-servers.context7-mcp = {
    tags = [
      "ai:agent"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.hdwlinux.context7-mcp ];

        hdwlinux.ai.agent.mcpServers.context7-mcp.stdio = {
          command = "context7-mcp";
          args = [ ];
        };
      };
  };
}
