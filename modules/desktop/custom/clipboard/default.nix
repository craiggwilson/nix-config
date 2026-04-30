{
  config.substrate.modules.desktop.custom.clipboard = {
    tags = [ "desktop:custom" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.wl-clipboard
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
