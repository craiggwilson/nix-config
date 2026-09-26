{
  config.substrate.modules.ai.clients.skills.kb = {
    tags = [ "ai:clients" ];

    homeManager = {
      hdwlinux.ai.clients.skills.kb = ./skill;
    };

    perUser = {
      hdwlinux.ai.clients.skills.kb = ./skill;
    };
  };
}
