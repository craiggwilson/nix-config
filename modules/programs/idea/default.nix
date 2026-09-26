{
  config.substrate.modules.programs.idea = {
    tags = [
      "gui"
      "programming"
      "users:craig:work"
    ];

    perUser =
      { pkgs, ... }:
      {
        packages = [
          pkgs.jetbrains.idea
        ];
      };
  };
}
