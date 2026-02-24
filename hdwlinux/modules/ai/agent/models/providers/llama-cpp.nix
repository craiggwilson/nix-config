{
  config.substrate.modules.ai.agent.models.providers.llama-cpp = {
    tags = [
      "ai:llm"
      "ai:agent"
    ];

    homeManager =
      { config, lib, ... }:
      {
        hdwlinux.ai.agent.models = lib.mapAttrs (
          _: model:
          let
            oc = model.settings.opencode or { };
          in
          {
            providers = [ "llama.cpp" ];
            limits = {
              context = oc.limit.context or 32000;
              output = oc.limit.output or 8192;
            };
          }
        ) config.hdwlinux.ai.llm.models;
      };
  };
}
