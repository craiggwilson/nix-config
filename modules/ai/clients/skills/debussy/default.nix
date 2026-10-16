{
  config.substrate.modules.ai.clients.skills.debussy = {
    provides = [ "ai:clients" ];
    requires = [ "profiles:personal" ];
    tags = [
      "ai:clients"
      "users:craig:personal"
    ];

    homeManager = {
      hdwlinux.ai.clients.skills.debussy = ./skill;
    };
  };
}
