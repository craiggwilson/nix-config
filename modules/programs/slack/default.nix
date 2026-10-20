{
  config.substrate.modules.programs.slack = {
    tags = [
      "desktop"
      "users:craig:work"
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
