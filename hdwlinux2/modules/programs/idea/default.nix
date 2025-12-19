{
  config.substrate.modules.programs.idea = {
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
