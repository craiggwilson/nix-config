{
  config.substrate.modules.ai.clients.skills.obsidian-bases = {
    provides = [ "ai:clients" ];
    tags = [ "ai:clients" ];

    homeManager = {
      hdwlinux.ai.clients.skills.obsidian-bases = ./skill;
    };
  };
}
