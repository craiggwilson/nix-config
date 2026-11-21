{
  config.substrate.modules.ai.clients.skills.agent-team = {
    tags = [ "profile:ai" ];

    homeManager = {
      hdwlinux.ai.clients.skills.agent-team = ./skill;
    };
  };
}
