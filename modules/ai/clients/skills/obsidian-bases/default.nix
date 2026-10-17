{
  config.substrate.modules.ai.clients.skills.obsidian-bases = {
    provides = [
      "ai:clients:skills:obsidian-bases"
      "ai:clients"
    ];
    homeManager = {
      hdwlinux.ai.clients.skills.obsidian-bases = ./skill;
    };
  };
}
