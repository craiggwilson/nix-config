{
  config.substrate.modules.services.comfy-ui = {
    tags = [
      "ai:image"
      "gui"
    ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        cfg = config.hdwlinux.services.comfy-ui;
        dataDir = "${config.xdg.dataHome}/comfy-ui";
        modelsDir = lib.removePrefix "${config.home.homeDirectory}/" "${dataDir}/models";
        customNodesDir = lib.removePrefix "${config.home.homeDirectory}/" "${dataDir}/custom_nodes";
      in
      {
        options.hdwlinux.services.comfy-ui = {
          host = lib.mkOption {
            description = "The listen address for ComfyUI.";
            type = lib.types.str;
            default = "127.0.0.1";
          };
          port = lib.mkOption {
            description = "The port for ComfyUI.";
            type = lib.types.int;
            default = 8188;
          };
          dataDir = lib.mkOption {
            description = "The directory for models and outputs.";
            type = lib.types.str;
            default = dataDir;
          };
          package = lib.mkOption {
            description = "The comfy-ui package to use.";
            type = lib.types.package;
            default = pkgs.stable-diffusion-webui.comfy.cuda;
          };
          extensions = lib.mkOption {
            description = "ComfyUI custom nodes to install into custom_nodes/.";
            type = lib.types.attrsOf (lib.types.submodule (
              { name, ... }: {
                options = {
                  name = lib.mkOption {
                    description = "The directory name for the extension in custom_nodes/.";
                    type = lib.types.str;
                    default = name;
                  };
                  src = lib.mkOption {
                    description = "The extension source (e.g. fetchFromGitHub).";
                    type = lib.types.package;
                  };
                };
              }
            ));
            default = { };
          };
          extensionPythonPkgs = lib.mkOption {
            internal = true;
            description = "Python packages required by extensions.";
            type = lib.types.listOf lib.types.package;
            default = [ ];
          };
        };

        config = {
          home.file = lib.listToAttrs (
            lib.concatMap (
              model:
              lib.imap0 (i: f: {
                name = "${modelsDir}/${f.subdir}/${f.name}";
                value.source = builtins.elemAt model.paths i;
              }) model.files
            ) (builtins.attrValues config.hdwlinux.ai.image.models)
            ++ lib.concatMap (
              lora:
              lib.imap0 (i: f: {
                name = "${modelsDir}/loras/${f.name}";
                value.source = builtins.elemAt lora.paths i;
              }) lora.files
            ) (builtins.attrValues config.hdwlinux.ai.image.loras)
            ++ lib.mapAttrsToList (_: ext: {
              name = "${customNodesDir}/${ext.name}";
              value.source = ext.src;
            }) cfg.extensions
          );

          systemd.user.services.comfy-ui = let
            extensionPythonPaths = lib.optionals (cfg.extensionPythonPkgs != [ ]) (
              let
                allDeps = lib.closePropagation cfg.extensionPythonPkgs;
              in
              map (pkg: "${pkg}/${pkgs.python3.sitePackages}") allDeps
            );
          in {
            Unit = {
              Description = "ComfyUI";
              Documentation = "https://github.com/comfyanonymous/ComfyUI";
              After = [ "network.target" ];
            };
            Install = {
              WantedBy = [ "default.target" ];
            };
            Service = {
              Type = "simple";
              Environment = [
                "HF_HOME=%C/comfy-ui/huggingface"
              ] ++ lib.optionals (extensionPythonPaths != [ ]) [
                "PYTHONPATH=${lib.concatStringsSep ":" extensionPythonPaths}"
              ];
              ExecStartPre = "${pkgs.bash}/bin/bash -c 'mkdir -p ${cfg.dataDir}/{custom_nodes,models}'";
              ExecStart = "${lib.getExe cfg.package} --base-directory ${cfg.dataDir} --listen ${cfg.host} --port ${builtins.toString cfg.port}";
              Restart = "on-failure";
              RestartSec = 10;
            };
          };
        };
      };
  };
}
