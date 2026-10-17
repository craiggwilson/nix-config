{
  config.substrate.modules.ai.clients.skills.obsidian-markdown = {
    provides = [
      "ai:clients:skills:obsidian-markdown"
      "ai:clients"
    ];
    homeManager = {
      hdwlinux.ai.clients.skills.obsidian-markdown = ./skill;
    };
  };
}
