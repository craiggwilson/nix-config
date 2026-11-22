{
  config.substrate.modules.users.craig.personal.ai = {
    tags = [
      "user:craig:personal"
      "profile:ai"
    ];

    homeManager = {
      hdwlinux.ai.clients.mcpServers.homeassistant.http = {
        url = "https://homeassistant.raeford.wilsonfamilyhq.com/api/mcp";
      };
    };
  };
}
