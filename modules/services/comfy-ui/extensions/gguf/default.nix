{
  config.substrate.modules.services.comfy-ui.extensions.gguf = {
    tags = [
      "ai:image"
      "gui"
    ];

    homeManager = { pkgs, ... }: {
      config.hdwlinux.services.comfy-ui = {
        extensions."ComfyUI-GGUF".src = pkgs.fetchFromGitHub {
          owner = "city96";
          repo = "ComfyUI-GGUF";
          rev = "6ea2651e7df66d7585f6ffee804b20e92fb38b8a";
          hash = "sha256-/ZwecgxTTMo9J1whdEJci8lEkOy/yP+UmjbpOAA3BvU=";
        };

        extensionPythonPkgs = [ pkgs.python3Packages.gguf ];
      };
    };
  };
}
