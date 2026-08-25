{
  config.substrate.modules.programs."49agents" = {
    tags = [ "users:craig:personal" ];

    generic =
      { lib, ... }:
      {
        options.hdwlinux.programs."49agents".port = lib.mkOption {
          type = lib.types.port;
          default = 1071;
          description = "Port for the 49Agents cloud relay server.";
        };
      };

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        cfg = config.hdwlinux.programs."49agents";
        pkg = pkgs.hdwlinux."49agents";

        # Same file `49ctl setup` would generate; writing it declaratively
        # makes setup unnecessary.
        ctlConfig = ''
          RUN_CLOUD=true
          RUN_AGENT=true
          CLOUD_PORT=${toString cfg.port}
          AGENT_CLOUD_URL=ws://localhost:${toString cfg.port}
        '';

        # xdg.stateHome is absolute but home.file keys are $HOME-relative.
        stateDirRel = lib.removePrefix "${config.home.homeDirectory}/" config.xdg.stateHome;
      in
      {
        home.packages = [ pkg ];

        # Same file `49ctl setup` would generate; writing it declaratively
        # makes setup unnecessary. 49ctl itself runs the cloud server and
        # agent (`49ctl start`), with offline pairing baked into its wrapper.
        home.file."${stateDirRel}/49agents/config" = {
          text = ctlConfig;
          # Overwrite a config left behind by an earlier manual `49ctl setup`.
          force = true;
        };
      };
  };
}
