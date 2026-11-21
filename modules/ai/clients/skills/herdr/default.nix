{
  config.substrate.modules.ai.clients.skills.herdr = {
    tags = [ "profile:ai" ];

    homeManager =
      { lib, pkgs, ... }:
      let
        # Each CLI prints its own manual (`--skill`); generating it at build
        # time keeps the skill in step with the installed version.
        mkSkill =
          name: description: pkg:
          pkgs.runCommand "${name}-skill" { } ''
            mkdir -p $out
            {
              printf -- '---\nname: %s\ndescription: %s\n---\n\n' ${
                lib.escapeShellArgs [
                  name
                  (builtins.toJSON description)
                ]
              }
              ${lib.getExe pkg} --skill
            } > $out/SKILL.md
          '';
      in
      {
        hdwlinux.ai.clients.skills = {
          herdr-app = mkSkill "herdr-app" "Use when changing what the user sees in herdr-app: spaces, tabs, panes, layouts, mods, focus, opening a pane or mod beside the agent (herdr-app do/ls/status/commands)." pkgs.hdwlinux.herdr-app;
          herdr-core = mkSkill "herdr-core" "Use when starting, reading, messaging, waiting on or cleaning up agents and programs in herdr terminals, including sub-agents and other agents' terminals (hc)." pkgs.hdwlinux.herdr-core;
        };
      };
  };
}
