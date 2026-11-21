{
  config.substrate.modules.ai.clients.skills.plan-show = {
    tags = [ "profile:ai" ];

    homeManager = {
      hdwlinux.ai.clients.skills.plan-show = ./skill;
    };
  };
}
