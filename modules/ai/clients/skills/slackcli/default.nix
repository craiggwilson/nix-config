{
  config.substrate.modules.ai.clients.skills.slackcli = {
    provides = [ "ai:clients" ];
    requires = [ "profiles:work" ];
    tags = [
      "ai:clients"
      "users:craig:work"
    ];

    homeManager = {
      hdwlinux.ai.clients.skills.slackcli = ./skill;
    };
  };
}
