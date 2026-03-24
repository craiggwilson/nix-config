{
  config.substrate.modules.programs.engram = {
    tags = [ "ai:agent" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.hdwlinux.engram-rs ];

        home.file.".config/engram/engram.toml".text = ''
          indexed_paths = ["~/Projects/kb"]
        '';

        home.file.".config/opencode/engram.json".text = builtins.toJSON {
          # Optional: Path to engram config file (TOML).
          # If not specified, engram defaults to $XDG_CONFIG_HOME/engram/engram.toml
          configFile = null;

          # Optional: Path to SQLite database file.
          # If not specified, engram defaults to $XDG_DATA_HOME/engram/engram.db
          db = null;
        };
      };
  };
}
