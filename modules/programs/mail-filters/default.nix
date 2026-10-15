let
  # Wrap the generic mail-filters program with a profile's rules file,
  # rendered from the Nix attr sets below.
  mkProfile =
    pkgs: name: rules:
    let
      rulesFile = pkgs.writeText "mail-filters-${name}-rules.json" (builtins.toJSON rules);
    in
    # The derivation name carries the profile for a readable store path, but
    # the binary is always `mail-filters` — only one profile lands per machine.
    pkgs.runCommand "mail-filters-${name}"
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];
        meta.mainProgram = "mail-filters";
      }
      ''
        mkdir -p $out/bin
        makeWrapper ${pkgs.hdwlinux.mail-filters}/bin/mail-filters $out/bin/mail-filters \
          --add-flags "--rules ${rulesFile}"
      '';

  # --- phase 1 templates: match shapes that apply a label, nothing more -----

  # Join Gmail search alternatives with the {...} OR syntax; a single
  # alternative is emitted bare.
  braced =
    alts:
    if builtins.length alts == 1 then builtins.head alts else "{${builtins.concatStringsSep " " alts}}";

  # GitHub repo notifications: mail addressed to <repo>@noreply.github.com
  # (Gmail's to: covers to/cc/bcc, so this catches all notification types).
  githubRepo =
    { label, repos }:
    {
      name = "github-${label}";
      match = {
        to = braced (map (repo: "${repo}@noreply.github.com") repos);
      };
      actions = { inherit label; };
    };

  # Project classification by subject prefix: GitHub PR titles and JIRA
  # notifications alike carry the ticket prefix, and either way the mail
  # belongs to the project. (The jira label itself is sender-scoped — see
  # jira-main / jira-escalation below.)
  projectPrefix =
    { label, alts }:
    {
      name = "project-${label}";
      match = {
        subject = braced alts;
      };
      actions = { inherit label; };
    };

  # --- work rules (Google Mail) ---------------------------------------------

  # Phase 2 fate is keyed on SOURCE (Jira / GitHub), not on project labels:
  # project labels (adfa, mms, go-driver, ...) are classification only, so a
  # boss mail mentioning CLOUDP- gets the label but stays in the inbox. The
  # jira label is source-scoped by construction (its rules match the Jira
  # senders), so label:jira is a safe archive key.
  # Sender-scoped noise labels: phase 1 labels them, phase 2 archives and
  # reads them. (comms is deliberately absent — it archives unread via
  # archive-comms.)
  noiseLabels = [
    "calendar"
    "code-review"
    "github"
    "newsletters"
    "rfc"
    "sentry"
    "zoom"
  ];

  allLabels = [
    "cc"
    "code-review"
    "docs"
    "github"
    "jira"
    "mana"
    "on-call"
  ]
  ++ noiseLabels
  ++ builtins.attrNames projects;

  # Project → GitHub repo slugs + subject prefixes. The single source of
  # truth: adding a project here generates its GitHub label rule, its
  # subject-prefix rule, includes its repos in the code-review rule, and
  # ensures its label exists. Both fields are required (use [ ] for none).
  projects = {
    adfa = {
      prefixes = [ "MHOUSE-" ];
      repos = [
        "mongohouse"
        "mongoast"
      ];
    };
    dotnet-driver = {
      prefixes = [
        "CSHARP-"
        ".NET"
      ];
      repos = [ "mongo-csharp-driver" ];
    };
    go-driver = {
      prefixes = [ "GODRIVER-" ];
      repos = [ "mongo-go-driver" ];
    };
    cloud = {
      prefixes = [ "CLOUDP-" ];
      repos = [ "mms" ];
    };
    mongosql = {
      prefixes = [
        "BI-"
        "\"BI CONNECTOR\""
      ];
      repos = [
        "sqlproxy"
        "mongoast"
      ];
    };
    sre = {
      prefixes = [ ];
      repos = [ "gosre" ];
    };
  };

  # Phase-1 project rules generated from `projects`: one GitHub-repo label
  # rule and one subject-prefix rule per project (whichever apply).
  projectRules = builtins.filter (r: r != null) (
    builtins.concatMap (
      label:
      let
        p = projects.${label};
      in
      [
        (
          if p.repos != [ ] then
            githubRepo {
              inherit label;
              inherit (p) repos;
            }
          else
            null
        )
        (
          if p.prefixes != [ ] then
            projectPrefix {
              inherit label;
              alts = p.prefixes;
            }
          else
            null
        )
      ]
    ) (builtins.attrNames projects)
  );

  workRules = {
    labels = allLabels;
    rules =
      # --- Phase 1: label everything we can. Applying a label does nothing
      # else — fate (archive/read/discard) is decided exclusively in phase 2.

      # Project rules (GitHub repo labels + subject prefixes), generated
      # from the `projects` attr set.
      projectRules ++ [
        # Catch-all for GitHub mail from repos without a dedicated label.
        # Excludes review-requested mail so code-review and github never
        # co-occur (code-review is keyed on the review_requested marker).
        {
          name = "github-catch-all";
          match = {
            from = "{notifications@github.com noreply.github.com}";
            negatedQuery = "cc:review_requested@noreply.github.com";
          };
          actions = {
            label = "github";
          };
        }
        {
          name = "jira-escalation";
          match = {
            from = "online-archive-escalation@mongodb.com";
          };
          actions = {
            label = "jira";
          };
        }
        {
          name = "jira-main";
          match = {
            from = "jira@mongodb.org";
          };
          actions = {
            label = "jira";
          };
        }

        # Named review requests: cc:review_requested appears only when you
        # were asked to review (general notifications carry author@/
        # state_change@ markers instead).
        {
          name = "code-review";
          match = {
            query = "cc:review_requested@noreply.github.com";
          };
          actions = {
            label = "code-review";
          };
        }
        {
          name = "cc-me";
          match = {
            query = "cc:me";
          };
          actions = {
            label = "cc";
          };
        }

        # Google Docs comment/share notifications.
        {
          name = "google-docs";
          match = {
            from = "{docs.google.com comments-noreply@docs.google.com drive-shares-dm-noreply@google.com}";
          };
          actions = {
            label = "docs";
          };
        }

        # On-call: all PagerDuty mail. Deliberately NOT archived by phase 2 —
        # pages stay in the inbox.
        {
          name = "pagerduty-oncall";
          match = {
            from = "no-reply@pagerduty.com";
          };
          actions = {
            label = "on-call";
          };
        }

        # MANA approval requests are actionable — labeled, stays in inbox.
        {
          name = "mana-requests";
          match = {
            from = "corps@mongodb.com";
          };
          actions = {
            label = "mana";
          };
        }

        # Noise streams: labeled for retrieval, archived + read by phase 2.
        {
          name = "sentry";
          match = {
            query = "{from:noreply@md.getsentry.com list:(<mms-server.mongodb-org.getsentry.com>)}";
          };
          actions = {
            label = "sentry";
          };
        }
        {
          name = "zoom";
          match = {
            from = "no-reply@zoom.us";
          };
          actions = {
            label = "zoom";
          };
        }
        {
          name = "cloud-platform";
          match = {
            from = "{mongodb-atlas@mongodb.com cloud-manager-support@mongodb.com Cloud-Core-XV@mongodb.com mms-admin@mongodb.com}";
          };
          actions = {
            label = "cloud";
          };
        }
        {
          name = "rfc";
          match = {
            from = "{tpm-bot@mongodb.com downstreamchanges@10gen.com}";
          };
          actions = {
            label = "rfc";
          };
        }
        {
          name = "calendar";
          match = {
            subject = "{Invitation: \"Canceled event:\" \"Updated invitation:\"}";
          };
          actions = {
            label = "calendar";
          };
        }
        {
          name = "comms";
          match = {
            from = "{internalcomms@mongodb.com peoplecomms@mongodb.com pt-ops@mongodb.com industry.solutions@mongodb.com eng@10gen.com enterprisetools-leads@10gen.com}";
          };
          actions = {
            label = "comms";
          };
        }
        {
          name = "newsletters";
          match = {
            from = "{notifications@vercel.com ship@info.vercel.com product@fireworks.ai support-noreply@snyk.io no-reply@account.pagerduty.com}";
          };
          actions = {
            label = "newsletters";
          };
        }

        # --- Phase 2: fate. Keyed on source, not on project labels. Filters
        # run in creation order, so these must stay after phase 1 (archive-jira
        # needs the jira label applied by jira-main/jira-escalation).
        {
          name = "archive-jira";
          match = {
            query = "label:jira";
          };
          actions = {
            archive = true;
            markRead = true;
          };
        }
        {
          name = "archive-github";
          match = {
            query = "from:{notifications@github.com noreply.github.com}";
          };
          actions = {
            archive = true;
            markRead = true;
          };
        }
        {
          name = "archive-noise";
          match = {
            query = braced (map (l: "label:${l}") noiseLabels);
          };
          actions = {
            archive = true;
            markRead = true;
          };
        }
        {
          # Comms blasts (org changes, new hires) archive but stay unread so
          # they stand out in the label view.
          name = "archive-comms";
          match = {
            query = "label:comms";
          };
          actions = {
            archive = true;
          };
        }
        {
          # MongoDB Cloud platform mail is machine noise — archive + read by
          # sender (label:cloud would also catch prefix-classified human mail).
          name = "archive-cloud-platform";
          match = {
            query = "from:{mongodb-atlas@mongodb.com cloud-manager-support@mongodb.com Cloud-Core-XV@mongodb.com mms-admin@mongodb.com}";
          };
          actions = {
            archive = true;
            markRead = true;
          };
        }

        # Azure billing/action-required mail is noise.
        {
          name = "azure-discard";
          match = {
            from = "azure-noreply@microsoft.com";
          };
          actions = {
            discard = true;
          };
        }

        # Exception to the docs stay-in-inbox rule: doc share notifications are
        # noise — archive + read them.
        {
          name = "doc-shares";
          match = {
            subject = "\"Document shared with you\"";
          };
          actions = {
            archive = true;
            markRead = true;
          };
        }

        # Discard.
        {
          name = "github-push-trash";
          match = {
            query = "cc:push@noreply.github.com";
          };
          actions = {
            discard = true;
          };
        }
        {
          name = "usage-reports-trash";
          match = {
            subject = "{\"MongoDB Download and Usage Report\" \"MANA: New order\"}";
          };
          actions = {
            discard = true;
          };
        }
        {
          name = "wins-bonusly-trash";
          match = {
            from = "{wins@10gen.com mongodb-atlas-alerts@mongodb.com noreply@bonus.ly system@bonus.ly}";
          };
          actions = {
            discard = true;
          };
        }
        {
          name = "wins-to-trash";
          match = {
            to = "wins@10gen.com";
          };
          actions = {
            discard = true;
          };
        }
      ];
  };

  # --- personal rules (Fastmail) ---------------------------------------------

  # `mail-filters sieve` renders a Sieve script to paste into Fastmail's UI.
  personalRules = {
    rules = [
      {
        name = "newsletters";
        match = {
          subject = "newsletter";
        };
        actions = {
          label = "Newsletters";
          markRead = true;
        };
      }
    ];
  };
in
{
  config.substrate.modules.programs.mail-filters-work = {
    tags = [ "users:craig:work" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ (mkProfile pkgs "work" workRules) ];
      };
  };

  config.substrate.modules.programs.mail-filters-personal = {
    tags = [ "users:craig:personal" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ (mkProfile pkgs "personal" personalRules) ];
      };
  };
}
