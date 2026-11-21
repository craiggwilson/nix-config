{
  config.substrate.modules.programs.herdr.templates = {
    tags = [ "profile:ai" ];

    homeManager =
      { config, lib, ... }:
      let
        # opencode's full TUI has no --agent flag; mini does, and stays
        # interactive (watchable, steerable), which hc requires of agents.
        mkTemplate = name: agent: ''
          ---
          name: ${name}
          description: ${builtins.toJSON agent.description}
          command: opencode mini --agent ${name}
          ---

          You are the ${name} on a team of agents running in herdr terminals.
          Your parent started you with hc; its address is in the reach hint of
          the message that brought this task.

          - Report to your parent with `hc send <parent> "<result>"` when done
            or stuck. Put anything longer than a few lines in a file under
            /tmp/opencode/team/ and send its path.
          - Push back. If the task is wrong, underspecified or a bad idea, say
            so to your parent before doing the work, with what you would do
            instead.
          - Teammates are listed by `hc ls` (their name says their role). Ask
            one directly with `hc send <name> "<question>"`; a reply arrives as
            your next input. Review requests from teammates are part of your
            job: answer them, and push back on their findings when you
            disagree, with reasons.
          - Don't start agents unless your task says to.
        '';
      in
      {
        xdg.configFile = lib.mapAttrs' (
          name: agent: lib.nameValuePair "herdr-core/templates/${name}.md" { text = mkTemplate name agent; }
        ) config.hdwlinux.ai.clients.agents;
      };
  };
}
