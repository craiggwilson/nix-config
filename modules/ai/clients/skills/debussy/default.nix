{
  config.substrate.modules.ai.clients.skills.debussy = {
    provides = [
      "ai:clients:skills:debussy"
      "ai:clients"
    ];
    requires = [ "profiles:personal" ];
    homeManager = {
      hdwlinux.ai.clients.skills.debussy = ./skill;
    };
  };
}
