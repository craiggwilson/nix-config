{
  config.substrate.modules.ai.clients.skills.kb = {
    tags = [ "profile:ai" ];

    homeManager = {
      hdwlinux.ai.clients.skills.kb = ./skill;
    };
  };
}
