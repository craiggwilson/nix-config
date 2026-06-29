{
  config.substrate.modules.services.comfy-ui-mcp = {
    tags = [
      "ai:image"
      "gui"
    ];

    homeManager =
      { config, lib, pkgs, ... }:
      let
        cfg = config.hdwlinux.services.comfy-ui-mcp;
      in
      {
        options.hdwlinux.services.comfy-ui-mcp = {
          host = lib.mkOption {
            description = "The listen address for the ComfyUI MCP server.";
            type = lib.types.str;
            default = "127.0.0.1";
          };
          port = lib.mkOption {
            description = "The port for the ComfyUI MCP server.";
            type = lib.types.int;
            default = 9000;
          };
          package = lib.mkOption {
            description = "The comfyui-mcp-server package to use.";
            type = lib.types.package;
            default = pkgs.hdwlinux.comfyui-mcp-server;
          };
        };

          config = {
            systemd.user.services.comfy-ui-mcp = {
              Unit = {
                Description = "ComfyUI MCP Server";
                Documentation = "https://github.com/joenorton/comfyui-mcp-server";
                After = [
                  "network.target"
                  "comfy-ui.service"
                ];
                BindsTo = [ "comfy-ui.service" ];
              };
              Install = {
                WantedBy = [ "default.target" ];
              };
              Service = {
                Type = "simple";
                Environment = "COMFYUI_URL=http://${config.hdwlinux.services.comfy-ui.host}:${toString config.hdwlinux.services.comfy-ui.port}";
                ExecStart = lib.getExe cfg.package;
                Restart = "always";
                RestartSec = 10;
              };
            };
          };
      };
  };
}
