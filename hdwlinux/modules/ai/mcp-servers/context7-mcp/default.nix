{
  config.substrate.modules.programs.context7-mcp = {
    tags = [
      "programming"
      "ai:mcp"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.hdwlinux.context7-mcp ];

        hdwlinux.ai.mcpServers.context7-mcp.stdio = {
          command = "context7-mcp";
          args = [ ];
        };
      };
  };
}
