{
  config.substrate.modules.ai.agent.agents.bazel-expert = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.agents.bazel-expert = {
        description = "Expert Bazel build engineer with deep knowledge of Bazel's build system, rules, and ecosystem. Masters monorepo management, remote execution, caching, and custom rule development.";
        model = "opus4.5";
        content = ./content.md;
        extraMeta.augment.color = "lime";
      };
    };
  };
}
