{
  config.substrate.modules.services.easyeffects = {
    tags = [ "gui" "audio" ];

    homeManager = {
      services.easyeffects = {
        enable = true;
      };
    };
  };
}

