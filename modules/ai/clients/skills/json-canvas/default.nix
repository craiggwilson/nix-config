{
  config.substrate.modules.ai.clients.skills.json-canvas = {
    provides = [
      "ai:clients:skills:json-canvas"
      "ai:clients"
    ];
    homeManager = {
      hdwlinux.ai.clients.skills.json-canvas = ./skill;
    };
  };
}
