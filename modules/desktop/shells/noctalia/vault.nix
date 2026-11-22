{
  config.substrate.modules.desktop.shells.noctalia.vault = {
    tags = [ "desktop:shells:noctalia" ];

    homeManager =
      { lib, ... }:
      {
        options.hdwlinux.programs.noctalia.vault = lib.mkOption {
          default = "kb";
          description = "Obsidian vault directory name under ~/Projects/github.com/craiggwilson.";
          type = lib.types.str;
        };
      };
  };
}
