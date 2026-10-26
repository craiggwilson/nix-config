{
  substrate.packages.revdiff =
    {
      lib,
      pkgs,
      ...
    }:
    let
      version = "1.13.0";

      # Pinned to master (9ff3562, 2026-10-25): the OpenCode v2 CLI plugin in
      # plugins/opencode/v2/ is newer than the v1.13.0 release, and this config
      # runs OpenCode v2. Repin to a release tag once one ships the v2 plugin.
      src = pkgs.fetchFromGitHub {
        owner = "umputun";
        repo = "revdiff";
        rev = "9ff3562d2480da0e02ec7469c0ef093e389c078e";
        hash = "sha256-y3sFtVRikhYSoRrLN/di4U/r2NvpWP23IuKF3++1jsg=";
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
