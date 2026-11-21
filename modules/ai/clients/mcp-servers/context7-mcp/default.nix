{
  config.substrate.modules.ai.clients.mcp-servers.context7-mcp = {
    tags = [
      "profile:ai"
    ];

    homeManager =
      { lib, pkgs, ... }:
      {
        hdwlinux.ai.clients.mcpServers.context7-mcp.stdio = {
          command = lib.getExe pkgs.hdwlinux.context7-mcp;
          args = [ ];
        };

        hdwlinux.ai.clients.mcpServers.context7.http = {
          url = "https://mcp.context7.com/mcp";
          headers.CONTEXT7_API_KEY.secret = "CONTEXT7_API_KEY";
          oauth = false;
        };

        secretspec.entries.CONTEXT7_API_KEY = {
          description = "Context7 API key for authenticated documentation lookups.";
          ref = {
            vault = "Craig";
            item = "Context7";
            field = "api_key";
          };
        };
      };
  };
}
