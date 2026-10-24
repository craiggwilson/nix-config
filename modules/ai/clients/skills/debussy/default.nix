{
  config.substrate.modules.ai.clients.skills.debussy = {
    tags = [
      "profile:ai"
      "profile:personal"
    ];

    homeManager = {
      hdwlinux.ai.clients.skills.debussy = ./skill;
    };
  };
}
