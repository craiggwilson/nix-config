{
  config.substrate.modules.ai.clients.skills.slackcli = {
    tags = [
      "ai:clients"
      "users:craig:work"
    ];

    homeManager = {
      hdwlinux.ai.clients.skills.slackcli = ./skill;
    };
  };
}
