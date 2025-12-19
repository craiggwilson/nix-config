{
  config.substrate.modules.programs.steam = {
    tags = [ "gui" "gaming" ];

    nixos = {
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
      };
    };
  };
}

