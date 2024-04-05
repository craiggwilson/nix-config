{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.localai;
in
{
  options.hdwlinux.features.localai = with types; {
    enable = mkEnableOpt ["ai"] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs;  [
      local-ai
      aichat

      (pkgs.writeShellScriptBin "start-local-ai" ''
        local-ai \
          --galleries '[{"name":"model-gallery", "url":"github:go-skynet/model-gallery/index.yaml"}, {"url": "github:go-skynet/model-gallery/huggingface.yaml","name":"huggingface"}]' \
          --models-path "${config.home.homeDirectory}/.local/share/local-ai/models"
      '')
    ];

    xdg.configFile."aichat/config.yaml".text = ''
      model: localai
      clients:
      - type: localai
        api_base: http://127.0.0.1:8080
        api_key: null
        models:
        - name: lunademo
          max_input_tokens: null
    '';
    xdg.configFile."aichat/roles.yaml".text = ''
      - name: shell
        prompt: >
          I want you to act as a linux shell expert.
          I want you to answer only with code.
          Do not write explanations.
        temperature: 0.7
    '';
  };
}
