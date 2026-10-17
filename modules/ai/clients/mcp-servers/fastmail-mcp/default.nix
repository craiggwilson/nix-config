{
  config.substrate.modules.ai.clients.mcp-servers.fastmail-mcp = {
    provides = [
      "ai:clients:mcp-servers:fastmail-mcp"
      "ai:clients"
    ];
    requires = [ "profiles:personal" ];
    homeManager = {
      hdwlinux.ai.clients.mcpServers.fastmail.http = {
        url = "https://api.fastmail.com/mcp";
      };
    };
  };
}
