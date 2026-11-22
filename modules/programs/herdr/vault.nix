{
  config.substrate.modules.programs.herdr.vault = {
    tags = [
      "profile:ai"
      "profile:programming"
    ];

    homeManager =
      { lib, ... }:
      {
        options.hdwlinux.programs.herdr.vault = lib.mkOption {
          default = "kb";
          description = "Obsidian vault directory name under ~/Projects/github.com/craiggwilson.";
          type = lib.types.str;
        };
      };
  };
}
