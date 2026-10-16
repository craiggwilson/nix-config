{
  config.substrate.modules.programs.slack = {
    provides = [ "gui" ];
    requires = [ "profiles:work" ];
    tags = [
      "gui"
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
