{
  config.substrate.modules.programs.claude-code = {
    tags = [
      "ai:agent"
      "programming"
      "users:craig:work"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.claude-code ];
      };
  };
}
