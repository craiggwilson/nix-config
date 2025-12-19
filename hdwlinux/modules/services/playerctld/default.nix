{
  config.substrate.modules.services.playerctld = {
    tags = [ "gui" "audio" ];

    homeManager = {
      services.playerctld.enable = true;
    };
  };
}

