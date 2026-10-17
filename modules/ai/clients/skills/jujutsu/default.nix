{
  config.substrate.modules.ai.clients.skills.jujutsu = {
    provides = [
      "ai:clients:skills:jujutsu"
      "ai:clients"
    ];
    homeManager = {
      hdwlinux.ai.clients.skills.jujutsu = ./skill;
    };
  };
}
