{
  config.substrate.modules.ai.agent.agents.excalidraw-expert = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.agents.excalidraw-expert = {
        description = "Expert Excalidraw diagram designer specializing in creating clear, hand-drawn style technical diagrams. Masters architecture diagrams, flowcharts, sequence diagrams, and visual documentation with Excalidraw's unique aesthetic.";
        model = "coding";
        content = ./content.md;
        extraMeta.augment.color = "orange";
      };
    };
  };
}
