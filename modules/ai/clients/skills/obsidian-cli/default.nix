{
  config.substrate.modules.ai.clients.skills.obsidian-cli = {
    provides = [ "ai:clients" ];
    tags = [ "ai:clients" ];

    homeManager = {
      hdwlinux.ai.clients.skills.obsidian-cli = ./skill;
    };
  };
}
