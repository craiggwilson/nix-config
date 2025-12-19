{
  config.substrate.modules.services.ssh-agent = {
    homeManager = {
      services.ssh-agent.enable = true;
    };
  };
}

