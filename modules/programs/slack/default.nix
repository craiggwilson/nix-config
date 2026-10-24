{
  config.substrate.modules.programs.slack = {
    tags = [
      "desktop"
      "user:craig"
      "profile:work"
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
