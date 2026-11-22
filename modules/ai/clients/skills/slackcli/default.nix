{
  config.substrate.modules.ai.clients.skills.slackcli = {
    tags = [
      "profile:ai"
      "profile:team-collaboration"
    ];

    homeManager = {
      hdwlinux.ai.clients.skills.slackcli = ./skill;
    };
  };
}
