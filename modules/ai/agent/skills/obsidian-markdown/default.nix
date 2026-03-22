{
  config.substrate.modules.ai.agent.skills.obsidian-markdown = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.skills.obsidian-markdown = ./skill;
    };
  };
}
