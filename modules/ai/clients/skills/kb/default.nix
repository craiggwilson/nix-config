{
  config.substrate.modules.ai.clients.skills.kb = {
    provides = [ "ai:clients:skills:kb" "ai:clients" ];
    tags = [ "ai:clients" ];

    homeManager = {
      hdwlinux.ai.clients.skills.kb = ./skill;
    };
  };
}
