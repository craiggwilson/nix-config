{
  config.substrate.modules.ai.clients.skills.git = {
    provides = [ "ai:clients" ];
    tags = [ "ai:clients" ];

    homeManager = {
      hdwlinux.ai.clients.skills.git = ./skill;
    };
  };
}
