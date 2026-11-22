{
  config.substrate.modules.programs.idea = {
    tags = [
      "desktop"
      "profile:jvm-development"
      "profile:programming"
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
