{
  config.substrate.modules.programs.idea = {
    tags = [
      "desktop"
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
