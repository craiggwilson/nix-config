{
  config.substrate.modules.programs.steam = {
    tags = [
      "desktop"
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
