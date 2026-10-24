{
  config.substrate.modules.programs.idea = {
    tags = [
      "desktop"
      "profile:programming"
      "user:craig"
      "profile:work"
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
