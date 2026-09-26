{
  config.substrate.modules.ai.clients.skills.obsidian-cli = {
    tags = [ "ai:clients" ];

    homeManager = {
      hdwlinux.ai.clients.skills.obsidian-cli = ./skill;
    };

    perUser = {
      hdwlinux.ai.clients.skills.obsidian-cli = ./skill;
    };
  };
}
