{
  config.substrate.modules.programs.slack = {
    provides = [ "programs:slack" "gui" ];
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
