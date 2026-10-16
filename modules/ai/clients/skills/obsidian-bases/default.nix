{
  config.substrate.modules.ai.clients.skills.obsidian-bases = {
    provides = [ "ai:clients:skills:obsidian-bases" "ai:clients" ];
    tags = [ "ai:clients" ];

    homeManager = {
      hdwlinux.ai.clients.skills.obsidian-bases = ./skill;
    };
  };
}
