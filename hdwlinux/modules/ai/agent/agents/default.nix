{
  config.substrate.modules.ai.agent.agents = {
    tags = [ "ai:agent" ];

    homeManager =
      { lib, ... }:
      let
        # Agent definitions without content paths (computed automatically)
        agents = {
          aws-expert = {
            description = "Expert AWS architect with deep knowledge of AWS services, well-architected framework, and cloud-native patterns. Masters compute, networking, data, security, and operational excellence on AWS.";
            model = "reasoning";
            extraMeta.augment.color = "orange";
          };

          bazel-expert = {
            description = "Expert Bazel build engineer with deep knowledge of Bazel's build system, rules, and ecosystem. Masters monorepo management, remote execution, caching, and custom rule development.";
            model = "coding";
            extraMeta.augment.color = "lime";
          };

          codebase-analyst = {
            description = "Expert codebase analyst specializing in code archaeology, architecture discovery, and technical research. Masters code navigation, dependency analysis, and pattern recognition to provide deep insights into any codebase.";
            model = "explore";
            extraMeta.augment.color = "teal";
          };

          distributed-systems-architect = {
            description = "Distributed systems architect designing scalable, resilient service ecosystems. Masters service boundaries, multi-region architecture, disaster recovery, cloud-provider redundancy, and operational excellence in cloud-native environments.";
            model = "reasoning";
            extraMeta.augment.color = "yellow";
          };

          excalidraw-expert = {
            description = "Expert Excalidraw diagram designer specializing in creating clear, hand-drawn style technical diagrams. Masters architecture diagrams, flowcharts, sequence diagrams, and visual documentation with Excalidraw's unique aesthetic.";
            model = "coding";
            extraMeta.augment.color = "orange";
          };

          flink-expert = {
            description = "Expert Apache Flink architect with deep knowledge of stream processing, stateful computations, event-time processing, and production deployments. Masters DataStream API, Table API, SQL, state management, and operational excellence.";
            model = "reasoning";
            extraMeta.augment.color = "purple";
          };

          go-expert = {
            description = "Expert Go developer with deep knowledge of idiomatic Go, concurrency patterns, and cloud-native development. Masters the standard library, popular frameworks, and performance optimization.";
            model = "coding";
            extraMeta.augment.color = "cyan";
          };

          java-expert = {
            description = "Expert Java developer with deep knowledge of the JVM ecosystem, enterprise patterns, and modern Java development. Masters Spring, build tools, testing, and performance optimization.";
            model = "coding";
            extraMeta.augment.color = "green";
          };

          kafka-expert = {
            description = "Expert Apache Kafka and WarpStream architect with deep knowledge of event streaming, topic design, performance tuning, and cloud-native deployments. Masters producers, consumers, Kafka Streams, Connect, and WarpStream's S3-native architecture.";
            model = "reasoning";
            extraMeta.augment.color = "blue";
          };

          mongodb-expert = {
            description = "Expert MongoDB and MongoDB Atlas architect with deep knowledge of database design, query optimization, replication, sharding, and cloud operations. Masters data modeling, performance tuning, and Atlas platform features.";
            model = "reasoning";
            extraMeta.augment.color = "green";
          };

          nix-expert = {
            description = "Expert Nix developer with deep knowledge of the Nix language, NixOS, Home Manager, flakes, and Linux system administration. Masters declarative configuration, reproducible builds, and system integration.";
            model = "coding";
            extraMeta.augment.color = "blue";
          };

          project-planner = {
            description = "Expert project planner who transforms roadmap initiatives into structured project plans. Masters scope definition, resource allocation, risk planning, and stakeholder alignment to set projects up for success before execution begins.";
            model = "planning";
            extraMeta.augment.color = "violet";
          };

          roadmap-builder = {
            description = "Strategic roadmap architect who translates vision into actionable multi-quarter plans. Masters OKR alignment, dependency mapping, and stakeholder prioritization to create compelling roadmaps that balance ambition with feasibility.";
            model = "planning";
            extraMeta.augment.color = "indigo";
          };

          security-architect = {
            description = "Expert security architect specializing in secure system design, threat modeling, and compliance. Masters zero-trust architecture, identity management, and security best practices across cloud-native environments.";
            model = "reasoning";
            extraMeta.augment.color = "red";
          };

          task-planner = {
            description = "Expert task planner who decomposes project work into actionable, well-defined tasks. Masters user story creation, acceptance criteria definition, and sprint planning to enable smooth execution and predictable delivery.";
            model = "planning";
            extraMeta.augment.color = "purple";
          };

          terraform-expert = {
            description = "Expert Terraform engineer with deep knowledge of infrastructure as code, provider ecosystem, and cloud architecture. Masters module design, state management, and multi-environment deployments.";
            model = "coding";
            extraMeta.augment.color = "amber";
          };
        };

        # Add prompt path to each agent based on its name
        addPromptPath = name: agent: agent // { prompt = agent.prompt or (./prompts + "/${name}.md"); };
      in
      {
        hdwlinux.ai.agent.agents = lib.mapAttrs addPromptPath agents;
      };
  };
}
