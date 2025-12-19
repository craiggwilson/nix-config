{
  config.substrate.modules.programs.context7-mcp = {
    tags = [ "programming" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.hdwlinux.context7-mcp ];

        hdwlinux.mcpServers.context7-mcp = {
          type = "stdio";
          command = "context7-mcp";
          args = [ ];
        };
      };
  };
}

