{
  config.substrate.settings.theming.apps.agents = {
    enabled = { config, ... }: true;
    apply.homeManager =
      { theme, ... }:
      {
        hdwlinux.ai.clients.agents.coder.color = theme.colors.hexWithHashtag.base0D;
        hdwlinux.ai.clients.agents.architect.color = theme.colors.hexWithHashtag.base0E;
        hdwlinux.ai.clients.agents.code-reviewer.color = theme.colors.hexWithHashtag.base09;
        hdwlinux.ai.clients.agents.debugger.color = theme.colors.hexWithHashtag.base08;
        hdwlinux.ai.clients.agents.platform-engineer.color = theme.colors.hexWithHashtag.base0C;
        hdwlinux.ai.clients.agents.sre.color = theme.colors.hexWithHashtag.base0B;
        hdwlinux.ai.clients.agents.security-engineer.color = theme.colors.hexWithHashtag.base08;
        hdwlinux.ai.clients.agents.planner.color = theme.colors.hexWithHashtag.base07;
        hdwlinux.ai.clients.agents.technical-writer.color = theme.colors.hexWithHashtag.base04;
        hdwlinux.ai.clients.agents.researcher.color = theme.colors.hexWithHashtag.base0C;
        hdwlinux.ai.clients.agents.diagram-designer.color = theme.colors.hexWithHashtag.base09;
      };
  };
}
