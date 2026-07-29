{
  config.substrate.modules.ai.clients.skills.debussy = {
    tags = [
      "ai:clients"
      "users:craig:personal"
    ];

    homeManager = {
      hdwlinux.ai.clients.skills.debussy = toString ./skill;
    };
  };
}
