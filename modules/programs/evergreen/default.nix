{
  config.substrate.modules.programs.evergreen = {
    tags = [ "profile:programming" ];

    homeManager =
      {
        config,
        ...
      }:
      let
        cfg = config.hdwlinux.programs.evergreen;
      in
      {
        config.home.packages = [ cfg.package ];
      };
  };
}
