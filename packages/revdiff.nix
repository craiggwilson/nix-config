{
  substrate.packages.revdiff =
    {
      lib,
      pkgs,
      ...
    }:
    let
      version = "1.14.0";

      src = pkgs.fetchFromGitHub {
        owner = "umputun";
        repo = "revdiff";
        rev = "v1.14.0";
        hash = "sha256-x0pst0Rlu4+43gb7EPzl6bjXO5+QqWP9EBbD+QJzEO0=";
      };
    in
    pkgs.buildGoModule {
      pname = "revdiff";
      inherit version;

      inherit src;

      # The repo ships a vendor/ directory, so no vendor hash is needed.
      vendorHash = null;

      subPackages = [ "app/revdiff" ];

      ldflags = [
        "-s"
        "-w"
        "-X main.revision=v${version}"
      ];

      # Ship the OpenCode CLI plugin files next to the binary so the
      # programs.opencode.revdiff module can install them from this one
      # pinned source instead of fetching the repo again.
      postInstall = ''
        pluginDir=$out/share/revdiff/opencode/plugins/revdiff
        mkdir -p $pluginDir/scripts
        install -m 0644 plugins/opencode/v2/{tui.ts,claims.ts,launcher.ts,package.json} $pluginDir/
        install -m 0644 .claude-plugin/skills/revdiff/scripts/agentdeck-window.sh $pluginDir/scripts/
        install -m 0755 .claude-plugin/skills/revdiff/scripts/launch-revdiff.sh $pluginDir/scripts/
      '';

      doCheck = false;

      meta = {
        description = "TUI for reviewing diffs, files, and documents with inline annotations";
        homepage = "https://github.com/umputun/revdiff";
        license = lib.licenses.mit;
        mainProgram = "revdiff";
        platforms = lib.platforms.unix;
      };
    };
}
