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
      };
  };
}
