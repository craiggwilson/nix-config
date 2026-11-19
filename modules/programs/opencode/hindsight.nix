{
  config.substrate.modules.programs.opencode.hindsight = {
    tags = [ "profile:ai" ];

    homeManager =
      { config, lib, ... }:
      let
        home = config.home.homeDirectory;
        kb = "${home}/Projects/github.com/craiggwilson/kb";

        # Paths assigned to each named bank. mapPathToBank is generated from
        # this so the configuration reads as bank -> paths.
        bankPaths = {
          wilsonfamilyhq = [
            "${home}/Projects/github.com/craiggwilson/nix-config"
            "${home}/Projects/github.com/craiggwilson/nix-private"
            "${home}/Projects/github.com/craiggwilson/substrate"
            "${home}/Projects/github.com/craiggwilson/homelab"
          ];
          craig = [ kb ];
          # Org roots, not individual repos: mapPathToBank matches on longest
          # path prefix, so every repo beneath these orgs — including future
          # clones — routes to the work bank.
          mongodb = [
            "${home}/Projects/github.com/10gen"
            "${home}/Projects/github.com/mongodb"
            "${home}/Projects/github.com/xgen-cloud"
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
              # The KB is explicitly routed to "craig" above. For non-repo
              # paths Hindsight falls back to the directory basename, so a
              # session started directly in /home/craig resolves to
              # "coding-agent::craig"; converge that onto the personal bank.
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
                    source_query = "What are Craig's current active projects, recurring commitments, upcoming deadlines, and recent decisions across personal and work life?";
                  };
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
              mongodb = {
                # Same provenance tagging as the shared infra bank: many work
                # repos share one bank, so memories must stay attributable.
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
