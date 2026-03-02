{
  config.substrate.modules.ai.agent.skills.nix-engineer = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.skills.nix-engineer = ./skill;
    };
  };
}
