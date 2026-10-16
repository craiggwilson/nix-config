{
  config.substrate.modules.programs.idea = {
    provides = [ "programs:idea" "programming" ];
    requires = [
      "gui"
      "profiles:work"
    ];
    tags = [
      "gui"
      "programming"
      "users:craig:work"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.jetbrains.idea
        ];
      };
  };
}
