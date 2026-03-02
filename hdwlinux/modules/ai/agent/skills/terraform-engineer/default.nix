{
  config.substrate.modules.ai.agent.skills.terraform-engineer = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.skills.terraform-engineer = ./skill;
    };
  };
}
