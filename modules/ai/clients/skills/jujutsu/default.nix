{
  config.substrate.modules.ai.clients.skills.jujutsu = {
    tags = [ "profile:ai" ];

    homeManager = {
      hdwlinux.ai.clients.skills.jujutsu = ./skill;
    };
  };
}
