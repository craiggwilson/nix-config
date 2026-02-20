{
  config.substrate.modules.ai.agent.agents.roadmap-builder = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.agents.roadmap-builder = {
        description = "Strategic roadmap architect who translates vision into actionable multi-quarter plans. Masters OKR alignment, dependency mapping, and stakeholder prioritization to create compelling roadmaps that balance ambition with feasibility.";
        model = "planning";
        content = ./content.md;
        extraMeta.augment.color = "indigo";
      };
    };
  };
}
