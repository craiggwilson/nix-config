{
  config.substrate.modules.ai.clients.skills.obsidian-cli = {
    provides = [ "ai:clients:skills:obsidian-cli" "ai:clients" ];
    tags = [ "ai:clients" ];

    homeManager = {
      hdwlinux.ai.clients.skills.obsidian-cli = ./skill;
    };
  };
}
