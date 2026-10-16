{
  config.substrate.modules.programs.steam = {
    provides = [ "programs:steam" "gaming" ];
    requires = [ "gui" ];
    tags = [
      "gui"
      "gaming"
    ];

    nixos = {
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
      };
    };
  };
}
