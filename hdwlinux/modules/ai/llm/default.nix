{
  config.substrate.modules.ai.llm = {
    tags = [ "ai:llm" ];

    homeManager =
      {
        lib,
        pkgs,
        ...
      }:
      let
        fetchGGUF =
          model:
          let
            filePaths = lib.map (f: {
              name = f.name;
              path = pkgs.fetchurl f;
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
                    settings = lib.mkOption {
                      type = lib.types.attrsOf lib.types.anything;
                      default = { };
                    };
                    files = lib.mkOption {
                      description = "The url of the model.";
                      type = lib.types.listOf (
                        lib.types.submodule {
                          options = {
                            name = lib.mkOption {
                              description = "The name of the file.";
                              type = lib.types.str;
                            };
                            url = lib.mkOption {
                              description = "The url to download the model.";
                              type = lib.types.str;
                            };
                            sha256 = lib.mkOption {
                              description = "The hash of the file.";
                              type = lib.types.str;
                            };
                          };
                        }
                      );
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
