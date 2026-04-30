{
  config.substrate.modules.ai.clients.skills.git = {
    tags = [ "ai:clients" ];

    homeManager = {
      hdwlinux.ai.clients.skills.git = ./skill;
    };
  };
}
