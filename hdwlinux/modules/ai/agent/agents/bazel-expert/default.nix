{
  config.substrate.modules.ai.agent.agents.bazel-expert = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.agents.bazel-expert = {
        metadata = {
          name = "bazel-expert";
          description = "Expert Bazel build engineer with deep knowledge of Bazel's build system, rules, and ecosystem. Masters monorepo management, remote execution, caching, and custom rule development.";
          tools = "Read, Write, Edit, Glob, Grep, Bash";
          model = "opus4.5";
          color = "lime";
        };
        content = ./prompt.md;
      };
    };
  };
}
