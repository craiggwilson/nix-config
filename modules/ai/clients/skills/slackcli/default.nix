{
  config.substrate.modules.ai.clients.skills.slackcli = {
    tags = [
      "profile:ai"
      "user:craig"
      "profile:work"
    ];

    homeManager = {
      hdwlinux.ai.clients.skills.slackcli = ./skill;
    };
  };
}
