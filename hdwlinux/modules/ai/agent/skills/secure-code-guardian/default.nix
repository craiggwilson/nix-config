{
  config.substrate.modules.ai.agent.skills.secure-code-guardian = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.skills.secure-code-guardian = ./skill;
    };
  };
}
