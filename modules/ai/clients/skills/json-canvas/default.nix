{
  config.substrate.modules.ai.clients.skills.json-canvas = {
    tags = [ "ai:clients" ];

    homeManager = {
      hdwlinux.ai.clients.skills.json-canvas = ./skill;
    };
  };
}
