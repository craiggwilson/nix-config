{
  config.substrate.modules.ai.agent.skills.obsidian-cli = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.skills.obsidian-cli = ./skill;
    };
  };
}
