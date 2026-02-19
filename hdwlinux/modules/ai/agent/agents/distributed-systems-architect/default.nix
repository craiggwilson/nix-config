{
  config.substrate.modules.ai.agent.agents.distributed-systems-architect = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.agents.distributed-systems-architect = {
        description = "Distributed systems architect designing scalable, resilient service ecosystems. Masters service boundaries, multi-region architecture, disaster recovery, cloud-provider redundancy, and operational excellence in cloud-native environments.";
        model = "opus4.5";
        content = ./content.md;
        extraMeta.augment.color = "yellow";
      };
    };
  };
}
