{
  config.substrate.modules.programs.openspec = {
    tags = [
      "profile:programming"
      "profile:ai"
    ];

    homeManager =
      { pkgs, wrap, ... }:
      {
        home.packages = [
          (wrap.package {
            package = pkgs.openspec;
            env.OPENSPEC_TELEMETRY = "0";
          })
        ];
      };
  };
}
