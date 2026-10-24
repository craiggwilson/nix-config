{
  config.substrate.modules.ai.clients.skills.obsidian-cli = {
    tags = [ "profile:ai" ];

    homeManager = {
      hdwlinux.ai.clients.skills.obsidian-cli = ./skill;
    };
  };
}
