{
  config.substrate.modules.ai.clients.skills.git = {
    tags = [ "profile:ai" ];

    homeManager = {
      hdwlinux.ai.clients.skills.git = ./skill;
    };
  };
}
