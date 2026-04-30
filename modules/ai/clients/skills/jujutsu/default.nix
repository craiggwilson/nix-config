{
  config.substrate.modules.ai.clients.skills.jujutsu = {
    tags = [ "ai:clients" ];

    homeManager = {
      hdwlinux.ai.clients.skills.jujutsu = ./skill;
    };
  };
}
