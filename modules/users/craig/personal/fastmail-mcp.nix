{
  config.substrate.modules.users.craig.personal.fastmail-mcp = {
    tags = [
      "user:craig:personal"
      "profile:ai"
      "profile:email-management"
    ];

    homeManager = {
      hdwlinux.ai.clients.mcpServers.fastmail.http = {
        url = "https://api.fastmail.com/mcp";
      };
    };
  };
}
