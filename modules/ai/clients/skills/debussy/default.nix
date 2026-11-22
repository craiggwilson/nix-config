{
  config.substrate.modules.ai.clients.skills.debussy = {
    tags = [
      "profile:ai"
      "profile:music-notation"
    ];

    homeManager = {
      hdwlinux.ai.clients.skills.debussy = ./skill;
    };
  };
}
