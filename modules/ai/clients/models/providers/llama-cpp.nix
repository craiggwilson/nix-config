{
  config.substrate.modules.ai.clients.models.providers.llama-cpp = {
    tags = [
      "ai:llm"
      "ai:clients"
    ];

    homeManager =
      { config, lib, ... }:
      let
        llmModels = config.hdwlinux.ai.llm.models;
      in
      {
        hdwlinux.ai.clients.models.providers."llama.cpp" = {
          displayName = "LLaMA C++ (local)";
          models = lib.mapAttrs (
            name: model:
            let
              oc = model.settings.opencode or { };
            in
            {
              displayName = oc.name or name;
              limits = {
                context = oc.limit.context or 32000;
                output = oc.limit.output or 8192;
              };
            }
          ) llmModels;
        };

      };
  };
}
