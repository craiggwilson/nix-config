{
  config.substrate.modules.ai.clients.skills.kb = {
    provides = [ "ai:clients" ];
    tags = [ "ai:clients" ];

    homeManager = {
      hdwlinux.ai.clients.skills.kb = ./skill;
    };
  };
}
