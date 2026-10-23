{
  config.substrate.modules.desktop.shells.custom.clipboard = {
    tags = [ "desktop:shells:custom" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          (pkgs.hdwlinux.writeShellApplicationWithSubcommands {
            name = "clipboardctl";
            runtimeInputs = [
              pkgs.vicinae
              pkgs.wl-clipboard
            ];
            subcommands = {
              copy = "wl-copy";
              paste = "wl-paste";
              show-menu = "vicinae 'vicinae://launch/clipboard/history?toggle=true'";
            };
          })
        ];
      };
  };
}
