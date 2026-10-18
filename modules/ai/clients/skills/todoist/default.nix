{
  config.substrate.modules.ai.clients.skills.todoist = {
    tags = [ "ai:clients" ];

    homeManager = {
      hdwlinux.ai.clients.skills.todoist = ./skill;
    };
  };
}
