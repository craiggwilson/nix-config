{
  config.substrate.modules.ai.agent.agents.roadmap-builder = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.agents.roadmap-builder = {
        description = "Strategic roadmap architect who translates vision into actionable multi-quarter plans. Masters OKR alignment, dependency mapping, and stakeholder prioritization to create compelling roadmaps that balance ambition with feasibility.";
        model = "opus4.5";
        content = ./content.md;
        extraMeta.color = "indigo";
      };
    };
  };
}
