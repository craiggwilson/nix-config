{
  config.substrate.modules.programs.nh = {
    tags = [ "core:tools:nix" ];

    nixos = { config, ... }: {
      programs.nh = {
        enable = true;
        flake = config.hdwlinux.flake;
      };
    };

    homeManager =
      {
        config,
        hasTag,
        lib,
        pkgs,
        ...
      }:
      let
        flake = config.hdwlinux.flake;
        target = "craig@wintersteel.raeford.wilsonfamilyhq.com";
        rebuild = action: ''
          exec nh os ${action} \
            --build-host ${target} \
            --target-host ${target} \
            "${flake}#wintersteel" "$@"
        '';
      in
      {
        config = lib.mkIf (hasTag "profile:programming") {
          home.packages = [
            (pkgs.hdwlinux.writeShellApplicationWithSubcommands {
              name = "nh-wintersteel";
              runtimeInputs = [ pkgs.nh ];
              subcommands = {
                build = rebuild "build";
                switch = rebuild "switch";
                test = rebuild "test";
              };
            })
          ];
        };
      };
  };
}
