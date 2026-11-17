{
  lib,
  config,
  inputs,
  ...
}:
let
  substrateConfig = config;

  mkPanixConfig =
    { substrate, domain }:
    let
      systemHosts = lib.filterAttrs (
        _: hostcfg: !hostcfg.usersOnly && hostcfg.users != [ ]
      ) substrate.hosts;

      fqdn = hostname: lib.optionalString (domain != "") "${hostname}.${domain}";

      mkMachine = hostname: {
        ssh = {
          hostname = fqdn hostname;
          username = "deploy";
          identity_file = "~/.ssh/deploy_ed25519";
        };
      };

      buildMode =
        hostcfg:
        if lib.elem "build:local" hostcfg.tags then
          "local"
        else if lib.elem "build:remote" hostcfg.tags then
          "remote"
        else
          "remote";

      mkHost =
        hostname: hostcfg:
        lib.optionalAttrs (buildMode hostcfg == "remote") {
          nix.build_mode = "remote";
        }
        // {
          machines.${hostname} = mkMachine hostname;
        };
    in
    {
      flags = {
        activation_mode = {
          alltypes = "test";
        };

        local_machine_hostname = "none";

        runtime = {
          ssh_reachability_timeout = "10s";
        };
      };

      fleet = {
        flakes = {
          nix-config = {
            installables = {
              nixosConfigurations = lib.mapAttrs mkHost systemHosts;
            };
          };
        };
      };
    };
in
{
  config.substrate.modules.programs.panix = {
    tags = [ "capability:deploy" ];

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ inputs.panix.packages.${pkgs.stdenv.hostPlatform.system}.default ];
      };

    homeManager =
      { config, pkgs, ... }:
      let
        domain = config.hdwlinux.networking.domain;
      in
      {
        xdg.configFile."panix/config.yml".source = pkgs.writeText "config.yml" (
          lib.generators.toYAML { } (mkPanixConfig {
            inherit (substrateConfig) substrate;
            inherit domain;
          })
        );

        home.sessionVariables.PANIX_CONFIG = "${config.xdg.configHome}/panix/config.yml";
      };
  };
}
