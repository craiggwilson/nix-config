{
  config.substrate.modules.ai.clients.mcp-servers.fastmail-mcp = {
    tags = [
      "ai:clients"
      "users:craig:personal"
    ];

    homeManager = { ... }: {
      hdwlinux.ai.clients.mcpServers.fastmail.http = {
        url = "https://api.fastmail.com/mcp";
      };
    };
  };
}
