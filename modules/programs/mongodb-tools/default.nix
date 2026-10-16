{
  config.substrate.modules.programs.mongodb-tools = {
    provides = [ "programming" ];
    requires = [ "profiles:work" ];
    tags = [
      "programming"
      "users:craig:work"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.mongosh
          pkgs.mongodb-tools
        ];
      };
  };
}
