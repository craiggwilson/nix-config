{
  config.substrate.modules.programs.agent-deck = {
    tags = [ "ai:agent" ];

    homeManager =
      { lib, pkgs, ... }:
      let
        opencodeCmd = lib.getExe pkgs.opencode;

        agentDeckConfig = {
          default_tool = "opencode";

          opencode = {
            command = opencodeCmd;
          };

          logs = {
            max_size_mb = 10;
            max_lines = 10000;
            remove_orphans = true;
          };

          updates = {
            check_enabled = false;
            check_interval_hours = 24;
          };

          global_search = {
            enabled = true;
            tier = "auto";
            recent_days = 90;
          };
        };
      in
      {
        home.packages = [ pkgs.hdwlinux.agent-deck ];

        home.file.".agent-deck/config.toml".source =
          (pkgs.formats.toml { }).generate "agent-deck-config.toml"
            agentDeckConfig;
      };
  };
}
