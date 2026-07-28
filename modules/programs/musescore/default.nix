{
  config.substrate.modules.programs.musescore = {
    tags = [
      "gui"
      "users:craig:personal"
    ];

    homeManager =
      { lib, pkgs, ... }:
      {
        home.packages = [
          (pkgs.musescore.overrideAttrs (old: {
            buildInputs = old.buildInputs ++ [ pkgs.qt6.qtwebsockets ];
            cmakeFlags = old.cmakeFlags ++ [ (lib.cmakeBool "MUSE_MODULE_NETWORK_WEBSOCKET" true) ];
          }))
          pkgs.muse-sounds-manager
        ];
      };
  };

  config.substrate.modules.programs.musescore.mcp = {
    tags = [
      "ai:clients"
      "gui"
      "users:craig:personal"
    ];

    homeManager =
      { lib, pkgs, ... }:
      {
        home.file."Documents/MuseScore4/Plugins/musescore-mcp-websocket.qml".source =
          "${pkgs.hdwlinux.mcp-musescore}/share/musescore-plugins/musescore-mcp-websocket.qml";

        hdwlinux.ai.clients.mcpServers.musescore.stdio = {
          command = lib.getExe pkgs.hdwlinux.mcp-musescore;
          args = [ ];
        };
      };
  };
}
