{ config, ... }:
let
  fileTypeFn = config.substrate.types.file;
in
{
  config.substrate.modules.ai.llm = {
    tags = [ "ai:llm" ];

    homeManager =
      { lib, pkgs, ... }:
      let
        fileType = fileTypeFn lib;

        fetchGGUF =
          model:
          let
            filePaths = lib.map (f: {
              inherit (f) name;
              path = pkgs.fetchurl {
                inherit (f) name url sha256;
              };
            }) model.files;

            linkFarmDir = pkgs.linkFarm "gguf-${lib.replaceStrings [ ":" ] [ "-" ] model.name}" filePaths;
          in
          lib.map (x: "${linkFarmDir}/${x.name}") filePaths;
      in
      {
        options.hdwlinux.ai.llm = {
          models = lib.mkOption {
            description = "The gguf models that should be available locally.";
            type = lib.types.attrsOf (
              lib.types.submodule (
                { name, config, ... }:
                {
                  options = {
                    name = lib.mkOption {
                      description = "The id of the model on hugging face.";
                      type = lib.types.str;
                      default = name;
                    };
                    type = lib.mkOption {
                      description = "The url to download the model.";
                      type = lib.types.enum [ "gguf" ];
                    };
                    categories = lib.mkOption {
                      description = "Alias categories this model should be used for (e.g., coding, reasoning, small).";
                      type = lib.types.listOf lib.types.str;
                      default = [ ];
                    };
                    priority = lib.mkOption {
                      description = "Relative preference when more than one model matches the same alias category.";
                      type = lib.types.int;
                      default = 0;
                    };
                    settings = lib.mkOption {
                      type = lib.types.attrsOf lib.types.anything;
                      default = { };
                    };
                    files = lib.mkOption {
                      description = "Model files to download.";
                      type = lib.types.listOf fileType;
                    };
                    paths = lib.mkOption {
                      description = "The paths of the downloaded files.";
                      readOnly = true;
                      type = lib.types.listOf lib.types.str;
                      default = fetchGGUF config;
                    };
                  };
                }
              )
            );
            default = [ ];
          };
        };
      };
  };
}
