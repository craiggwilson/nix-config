{
  config.substrate.modules.ai.clients.skills.git = {
    provides = [
      "ai:clients:skills:git"
      "ai:clients"
    ];
    homeManager = {
      hdwlinux.ai.clients.skills.git = ./skill;
    };
  };
}
