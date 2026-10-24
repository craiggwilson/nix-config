{
  config.substrate.modules.ai.clients.mcp-servers.fastmail-mcp = {
    tags = [
      "profile:ai"
      "profile:personal"
    ];

    homeManager = {
      hdwlinux.ai.clients.mcpServers.fastmail.http = {
        url = "https://api.fastmail.com/mcp";
      };
    };
  };
}
