{
  config.substrate.modules.programs.slack = {
    tags = [
      "desktop"
      "profile:team-collaboration"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.slack
          pkgs.hdwlinux.slackcli
        ];
      };
  };
}
