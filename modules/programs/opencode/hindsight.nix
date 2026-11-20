{
  config.substrate.modules.programs.opencode.hindsight = {
    tags = [ "profile:ai" ];

    homeManager =
      { config, lib, ... }:
      let
        home = config.home.homeDirectory;

        # Paths assigned to each named bank. mapPathToBank is generated from
        # this so the configuration reads as bank -> paths.
        bankPaths = {
          craig = [ "${home}/Projects/github.com/craiggwilson/kb" ];
          mongodb = [
            "${home}/Projects/github.com/craiggwilson/kb-work"
            "${home}/Projects/github.com/10gen"
            "${home}/Projects/github.com/mongodb"
            "${home}/Projects/github.com/xgen-cloud"
          ];
          wilsonfamilyhq = [
            "${home}/Projects/github.com/craiggwilson/nix-config"
            "${home}/Projects/github.com/craiggwilson/nix-private"
            "${home}/Projects/github.com/craiggwilson/substrate"
            "${home}/Projects/github.com/craiggwilson/homelab"
          ];
        };

        mapPathToBank = lib.listToAttrs (
          lib.concatLists (
            lib.mapAttrsToList (
              bank: paths:
              map (path: {
                name = path;
                value = bank;
              }) paths
            ) bankPaths
          )
        );
      in
      {
        programs.opencode.settings.plugins = [
          "@vectorize-io/hindsight-coding-agents@0.8.8"
        ];

        # Materialize the Hindsight API token to disk once per login so the
        # plugin can read it without resolving the secret on every invocation.
        secretspec.entries.HINDSIGHT_API_TOKEN = {
          description = "Hindsight API token for the coding-agents plugin.";
          ref = {
            vault = "Craig";
            item = "Hindsight";
            field = "api_key";
          };
          file.path = "${config.xdg.configHome}/hindsight/token";
        };

        # Plugin configuration. Banks are NOT managed here; create each bank in
        # the Hindsight UI/API and import the matching template from
        # ~/.hindsight/templates/ so every bank starts with the intended config.
        home.file.".hindsight/coding-agent.json" = {
          text = builtins.toJSON {
            apiUrl = "https://hindsight.wilsonfamilyhq.com:8443";
            dynamicBankId = true;
            bankIdTemplate = "coding-agent::{gitProject}";
            observationScopes = "shared";
            retainExtractionMode = "concise";
            manageBankConfig = false;
            inherit mapPathToBank;
            banks = {
              # Vault paths are explicitly routed above: kb -> craig and
              # kb-work -> mongodb. For non-repo paths Hindsight falls back to
              # the directory basename, so a session started directly in
              # /home/craig resolves to "coding-agent::craig"; converge that
              # onto the personal bank.
              "coding-agent::craig" = {
                bank = "craig";
              };
              craig = {
                retainExtractionMode = "verbose";
                pages = {
                  "Component map" = false;
                  "Conventions and patterns" = false;
                };
                customPages = {
                  "Life dashboard" = {
                    source_query = "What are Craig's current active personal projects, recurring commitments, upcoming deadlines, and recent decisions?";
                  };
                };
              };
              mongodb = {
                # Tag provenance so work memories still show which vault or
                # repo they came from.
                retainTags = [ "project:{gitProject}" ];
                retainMetadata = {
                  repo = "{gitProject}";
                };
              };
              wilsonfamilyhq = {
                # Tag provenance so memories from the shared infrastructure
                # bank still show which repo they came from.
                retainTags = [ "project:{gitProject}" ];
                retainMetadata = {
                  repo = "{gitProject}";
                };
              };
            };
            harnesses = {
              opencode2 = {
                reflectTimeoutMs = 20000;
                injectTimeoutMs = 7000;
              };
            };
          };
        };
      };
  };
}
