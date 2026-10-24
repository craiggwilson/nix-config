{
  config.substrate.modules.ai.clients.skills.todoist = {
    tags = [ "profile:ai" ];

    homeManager = {
      hdwlinux.ai.clients.skills.todoist = ./skill;
    };
  };
}
