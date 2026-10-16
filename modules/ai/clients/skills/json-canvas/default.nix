{
  config.substrate.modules.ai.clients.skills.json-canvas = {
    provides = [ "ai:clients" ];
    tags = [ "ai:clients" ];

    homeManager = {
      hdwlinux.ai.clients.skills.json-canvas = ./skill;
    };
  };
}
