{
  config.substrate.modules.ai.agent.agents = {
    tags = [ "ai:agent" ];

    homeManager =
      { lib, ... }:
      let
        # Agent definitions without content paths (computed automatically)
        agents = {
          api-designer = {
            description = "Expert API designer specializing in REST, GraphQL, and gRPC design patterns. Masters API versioning, documentation, backward compatibility, and developer experience optimization.";
            model = "reasoning";
            extraMeta.augment.color = "violet";
          };

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

          database-architect = {
            description = "Expert database architect with deep knowledge of schema design, query optimization, and data modeling across SQL, NoSQL, and graph databases. Masters migrations, replication, sharding, and polyglot persistence strategies.";
            model = "reasoning";
            extraMeta.augment.color = "green";
          };

          devops-engineer = {
            description = "Expert DevOps engineer specializing in CI/CD pipelines, release engineering, and deployment strategies. Masters build automation, artifact management, environment promotion, and operational tooling.";
            model = "coding";
            extraMeta.augment.color = "amber";
          };

          diagram-designer = {
            description = "Expert visual communication designer specializing in technical diagrams, architecture visualizations, and information design. Masters visual hierarchy, layout principles, and diagram type selection for clear technical communication.";
            model = "coding";
            extraMeta.augment.color = "orange";
          };

          distributed-systems-architect = {
            description = "Distributed systems architect designing scalable, resilient service ecosystems. Masters service boundaries, multi-region architecture, disaster recovery, cloud-provider redundancy, and operational excellence in cloud-native environments.";
            model = "reasoning";
            extraMeta.augment.color = "yellow";
          };

          documentation-writer = {
            description = "Expert technical writer specializing in clear, maintainable documentation. Masters API documentation, architecture decision records, tutorials, and knowledge management for developer audiences.";
            model = "planning";
            extraMeta.augment.color = "gray";
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

          kubernetes-expert = {
            description = "Expert Kubernetes architect with deep knowledge of cluster operations, workload management, and cloud-native patterns. Masters Helm, operators, service mesh, GitOps, and production-grade cluster design.";
            model = "reasoning";
            extraMeta.augment.color = "cyan";
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

          observability-expert = {
            description = "Expert observability engineer specializing in metrics, logging, tracing, and alerting systems. Masters SLIs/SLOs, OpenTelemetry, Prometheus, Grafana, and incident response tooling.";
            model = "reasoning";
            extraMeta.augment.color = "teal";
          };

          project-planner = {
            description = "Expert project planner who transforms roadmap initiatives into structured project plans. Masters scope definition, resource allocation, risk planning, and stakeholder alignment to set projects up for success before execution begins.";
            model = "planning";
            extraMeta.augment.color = "violet";
          };

          python-expert = {
            description = "Expert Python developer with deep knowledge of idiomatic Python, async patterns, and modern tooling. Masters type hints, popular frameworks (FastAPI, Django), testing, and performance optimization.";
            model = "coding";
            extraMeta.augment.color = "yellow";
          };

          roadmap-builder = {
            description = "Strategic roadmap architect who translates vision into actionable multi-quarter plans. Masters OKR alignment, dependency mapping, and stakeholder prioritization to create compelling roadmaps that balance ambition with feasibility.";
            model = "planning";
            extraMeta.augment.color = "indigo";
          };

          ruby-expert = {
            description = "Expert Ruby developer with deep knowledge of idiomatic Ruby, Rails patterns, and metaprogramming. Masters ActiveRecord, testing with RSpec, gem development, and performance optimization.";
            model = "coding";
            extraMeta.augment.color = "red";
          };

          rust-expert = {
            description = "Expert Rust developer with deep knowledge of ownership, lifetimes, and systems programming. Masters async Rust, unsafe code, FFI, and building high-performance, memory-safe applications.";
            model = "coding";
            extraMeta.augment.color = "orange";
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
            extraMeta.augment.color = "purple";
          };

          testing-expert = {
            description = "Expert testing engineer specializing in test strategy, automation, and quality assurance. Masters unit testing, integration testing, E2E testing, property-based testing, and test architecture design.";
            model = "coding";
            extraMeta.augment.color = "lime";
          };

          typescript-expert = {
            description = "Expert TypeScript developer with deep knowledge of the type system, Node.js, and modern frontend frameworks. Masters React, build tools, testing, and full-stack TypeScript development.";
            model = "coding";
            extraMeta.augment.color = "blue";
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
