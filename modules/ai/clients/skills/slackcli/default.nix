{
  config.substrate.modules.ai.clients.skills.slackcli = {
    provides = [
      "ai:clients:skills:slackcli"
      "ai:clients"
    ];
    requires = [ "profiles:work" ];
    homeManager = {
      hdwlinux.ai.clients.skills.slackcli = ./skill;
    };
  };
}
