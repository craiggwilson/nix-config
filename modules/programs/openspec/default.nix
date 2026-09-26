{
  config.substrate.modules.programs.openspec = {
    tags = [
      "programming"
      "ai:clients"
    ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.openspec ];
      };
  };
}
