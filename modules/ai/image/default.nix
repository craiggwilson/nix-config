{ config, ... }:
let
  fileTypeFn = config.substrate.types.file;
in
{
  config.substrate.modules.ai.image = {
    tags = [ "ai:image" ];

    homeManager =
      { lib, pkgs, ... }:
      let
        fileType = fileTypeFn lib;

        fetchModel =
          model:
          let
            filePaths = lib.map (f: {
              name = "${f.subdir}/${f.name}";
              path = pkgs.fetchurl {
                name = f.name;
                url = f.url;
                sha256 = f.sha256;
              };
            }) model.files;

            linkFarmDir = pkgs.linkFarm "image-${lib.replaceStrings [ ":" ] [ "-" ] model.name}" filePaths;
          in
          lib.map (x: "${linkFarmDir}/${x.name}") filePaths;
      in
      {
        options.hdwlinux.ai.image = {
          models = lib.mkOption {
            description = "Image generation models available locally.";
            type = lib.types.attrsOf (
              lib.types.submodule (
                { name, config, ... }:
                {
                  options = {
                    name = lib.mkOption {
                      description = "The id of the model.";
                      type = lib.types.str;
                      default = name;
                    };
                    type = lib.mkOption {
                      description = "The model format.";
                      type = lib.types.enum [ "safetensors" ];
                    };
                    files = lib.mkOption {
                      description = "Model files to download.";
                      type = lib.types.listOf fileType;
                    };
                    paths = lib.mkOption {
                      description = "The paths of the downloaded files.";
                      readOnly = true;
                      type = lib.types.listOf lib.types.str;
                      default = fetchModel config;
                    };
                  };
                }
              )
            );
            default = { };
          };
        };
      };
  };
}
